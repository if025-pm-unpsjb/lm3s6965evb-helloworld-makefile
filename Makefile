############################################################################### 
#
# Name for the binary, hex and other output build files.
# 
APP_NAME=main
DEBUG=1

############################################################################### 
#
# Compiler executables path and names.
# 
GCC_BIN =
AR      = $(GCC_BIN)arm-none-eabi-ar
AS      = $(GCC_BIN)arm-none-eabi-as
CC      = $(GCC_BIN)arm-none-eabi-gcc
CPP     = $(GCC_BIN)arm-none-eabi-g++
LD      = $(GCC_BIN)arm-none-eabi-gcc
OBJCOPY = $(GCC_BIN)arm-none-eabi-objcopy
SIZE    = $(GCC_BIN)arm-none-eabi-size

############################################################################### 
#
# Paths.
#
MAKE_DIR = $(PWD)
BUILD_DIR = ./build

###############################################################################
#
# Source code.
#
SRC += $(wildcard ./src/*.c)
OBJECTS = $(SRC:.c=.o)

###############################################################################
#
# Include paths to the required headers.
#
INCLUDE_PATHS += -I.
INCLUDE_PATHS += -I./src
INCLUDE_PATHS += -I./board/lm3s6965evb/drivers

###############################################################################
#
# Paths to the required libraries (*.a files)
#
LIBRARY_PATHS += -L./board/lm3s6965evb/drivers/arm-none-eabi-gcc
LIBRARIES += -ldriver
LIBRARIES += -lgr

###############################################################################
#
# Common flags and symbols used by the compiler.
#
CPU += -mcpu=cortex-m3
CPU += -mthumb

COMMON_FLAGS += $(CPU)
COMMON_FLAGS += -c
COMMON_FLAGS += -g
COMMON_FLAGS += -Wall
COMMON_FLAGS += -fno-common
COMMON_FLAGS += -fmessage-length=0
COMMON_FLAGS += -fno-exceptions
COMMON_FLAGS += -fno-builtin
COMMON_FLAGS += -ffunction-sections
COMMON_FLAGS += -fdata-sections
COMMON_FLAGS += -funsigned-char
COMMON_FLAGS += -fno-delete-null-pointer-checks
COMMON_FLAGS += -fomit-frame-pointer
COMMON_FLAGS += -MMD -MP
COMMON_FLAGS += -std=gnu99

ifeq ($(DEBUG), 1)
  COMMIN_FLAGS += -g
  COMMON_FLAGS += -Og
  COMMON_FLAGS += -ggdb3
else
  COMMON_FLAGS += -Os  
endif

###############################################################################
#
# Linker script used to build the binary.
#
LINKER_SCRIPT = ./board/lm3s6965evb/linker.ld

###############################################################################
#
# Flags and symbols required by the linker.
#
LD_FLAGS += $(CPU)
LD_FLAGS += -nostartfiles
LD_FLAGS += -Wl,-gc-sections
LD_FLAGS += $(foreach l, $(LIBS), -l$(l))

###############################################################################
#
# Make flags.
#
MAKE_FLAGS += --no-print-directory

###############################################################################
#
# Rules used to build the example programs.
#
all: $(BUILD_DIR)/$(APP_NAME).bin size

clean:
	+@echo "Cleaning files..."
	@rm -f $(BUILD_DIR)/$(APP_NAME).bin $(BUILD_DIR)/$(APP_NAME).elf $(OBJECTS) $(DEPS)

.c.o:
	+@echo "Compile: $<"
	@$(CC) $(COMMON_FLAGS) $(CC_FLAGS) $(CC_SYMBOLS) $(INCLUDE_PATHS) -o $@ $<	

$(BUILD_DIR)/$(APP_NAME).elf: $(OBJECTS)
	+@echo "Linking: $@"
	@$(LD) $(LD_FLAGS) -T$(LINKER_SCRIPT) $(LIBRARY_PATHS) -o $@ $^ $(LIBRARIES) $(WRAP)

$(BUILD_DIR)/$(APP_NAME).bin: $(BUILD_DIR)/$(APP_NAME).elf
	+@echo "Binary: $@"
	@$(OBJCOPY) -O binary $< $@
	
size: $(BUILD_DIR)/$(APP_NAME).elf
	$(SIZE) $<

DEPS = $(OBJECTS:.o=.d)
-include $(DEPS)
