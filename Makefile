#
# AVR tool chain config
#
AVR_TOOL := avr-gcc
AVR_COPY := avr-objcopy
AVR_DUDE := avrdude
AVR_DUDE_CONF := arduino/avrdude.conf
AVR_INSET := atmega328p
AVR_CPU_FREQ := 16000000L

#
# Arduino config
#
ARD_DEVICE := /dev/cu.usbmodem1421
ARD_BAUD := 115200

#
# arduino program
#
ARD_PARTS := hooks.c wiring.c wiring_digital.c

ARD_DIR := ./arduino
ARD_SRC_DIR := $(ARD_DIR)/src
ARD_SRCS := $(ARD_PARTS:%=$(ARD_SRC_DIR)/%)

ARD_OBJ_DIR ?= $(ARD_DIR)/obj
ARD_OBJS := $(ARD_SRCS:%=$(ARD_OBJ_DIR)/%.o)
ARD_DEPS := $(ARD_OBJS:.o=.d)

#
# main program
#
MAIN := main.cpp
MAIN_ELF := $(MAIN:.cpp=.elf)
MAIN_HEX := $(MAIN_ELF:.elf=.hex)

SRC_DIRS := ./src
SRCS := $(shell find $(SRC_DIRS) -name **\*.cpp )

INC_DIRS := $(SRC_DIRS) ./common/include  ./arduino/src

COMPILE_FLAGS := -Wall $(addprefix -I,$(INC_DIRS)) -MMD -mmcu=$(AVR_INSET) -DF_CPU=$(AVR_CPU_FREQ) -Os

OBJ_DIR ?= ./obj
MAIN_OBJ := $(OBJ_DIR)/$(MAIN).o
OBJS := $(SRCS:%=$(OBJ_DIR)/%.o)
DEPS := $(MAIN_OBJ:.o=.d) $(OBJS:.o=.d)

LINK_FLAGS := -Wl,--gc-sections -mmcu=$(AVR_INSET) -Os
LINK_LIBS := c m

BUILD_DIR := ./build

MKDIR_P ?= mkdir -p

#
# targets
#

$(BUILD_DIR)/$(MAIN_HEX): $(BUILD_DIR)/$(MAIN_ELF)
	$(MKDIR_P) $(dir $@)
	$(AVR_COPY) -O ihex -R .eeprom $< $@

$(BUILD_DIR)/$(MAIN_ELF): $(MAIN_OBJ) $(OBJS) $(ARD_OBJS)
	$(MKDIR_P) $(dir $@)
	$(AVR_TOOL) $(LINK_FLAGS) -o $@ $(MAIN_OBJ) $(OBJS) $(ARD_OBJS) $(addprefix -l,$(LINK_LIBS))

$(OBJ_DIR)/%.o: %
	$(MKDIR_P) $(dir $@)
	$(AVR_TOOL) $(COMPILE_FLAGS) -x c++ -o $@ -c $<

$(ARD_OBJ_DIR)/%.o: %
	$(MKDIR_P) $(dir $@)
	$(AVR_TOOL) $(COMPILE_FLAGS) -x c -o $@ -c $<

install:
	$(AVR_DUDE) -C$(AVR_DUDE_CONF) -c arduino -p $(AVR_INSET) -P $(ARD_DEVICE) -b $(ARD_BAUD) -D -U flash:w:$(BUILD_DIR)/$(MAIN_HEX):i

clean:
	rm -rf $(OBJ_DIR)
	rm -rf $(ARD_OBJ_DIR)
	rm -rf $(BUILD_DIR)

-include $(DEPS)
