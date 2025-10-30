############################################################################### 
#
# Check if Makefile.mine exists
#
ifeq (,$(wildcard Makefile.mine))
$(error El archivo Makefile.mine no existe. Crearlo a partir de Makefile.config)
endif

############################################################################### 
#
# Modify example to build in Makefile.mine
#
include Makefile.mine

############################################################################### 
#
# Name for the binary, hex and other output build files.
# 
ifeq ($(UNIQUE_BUILD_NAME), y)
	APP_NAME=build
else
	APP_NAME=$(APP)
endif
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
SRC += $(wildcard ./src/$(APP)/*.c)
SRC += $(wildcard ./src/*.c)
SRC += $(wildcard ./libs/FreeRTOS/*.c)
SRC += ./libs/FreeRTOS/portable/ARM_CM3/port.c
SRC += ./libs/Tracealyzer/trcKernelPort.c
SRC += ./libs/Tracealyzer/trcSnapshotRecorder.c
OBJECTS = $(SRC:.c=.o)

###############################################################################
#
# Include paths to the required headers.
#
INCLUDE_PATHS += -I.
INCLUDE_PATHS += -I./src
INCLUDE_PATHS += -I./src/$(APP)
INCLUDE_PATHS += -I./board/lm3s6965evb/drivers
INCLUDE_PATHS += -I./libs/FreeRTOS/include
INCLUDE_PATHS += -I./libs/FreeRTOS/portable/ARM_CM3
INCLUDE_PATHS += -I./libs/Tracealyzer/config
INCLUDE_PATHS += -I./libs/Tracealyzer/include

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

build: all

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

docker-build:
	docker build -t rtsg .

qemu: all
	./runvnc.sh
	qemu-system-arm -kernel $(BUILD_DIR)/$(APP_NAME).elf -machine lm3s6965evb -vnc :0 -serial mon:stdio

qemu-uart: all
	qemu-system-arm -kernel $(BUILD_DIR)/$(APP_NAME).elf -machine lm3s6965evb -nographic

qemu-gdb: all
	qemu-system-arm -kernel $(BUILD_DIR)/$(APP_NAME).elf -S -s -machine lm3s6965evb -vnc :0 -serial mon:stdio

DEPS = $(OBJECTS:.o=.d)
-include $(DEPS)
