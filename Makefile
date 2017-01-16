#
# The target to build
#
TARGET		?= ts100

#
# Compile-time options
#
OPTIONS		?=

#
# Debugger optons, must be empty or GDB
#
DEBUG ?=

#
# Things that need to be maintained as the source changes
#

VALID_TARGETS	 = ts100

#
# Working directories
#
ROOT		 = $(dir $(lastword $(MAKEFILE_LIST)))
SRC_DIR		 = $(ROOT)/onboard
OBJECT_DIR	 = $(ROOT)/obj
BIN_DIR		 = $(ROOT)/bin

#
# Source files common to all targets
#
$(TARGET)_SRC	= startup_stm32f10x_md.s system_stm32f10x.c misc.c syscalls.c main.c \
		   stm32f10x_adc.c stm32f10x_dma.c stm32f10x_exti.c stm32f10x_flash.c stm32f10x_gpio.c stm32f10x_iwdg.c \
		   stm32f10x_rcc.c stm32f10x_tim.c stm32f10x_i2c.c \
		   Analog.c Bios.c I2C.c Interrupt.c MMA8652FC.c Modes.c Oled.c PID.c Settings.c

#
# Search path for baseflight sources
#
VPATH		:= $(SRC_DIR)

#
# Things that might need changing to use different tools
#
CC			= arm-none-eabi-gcc
OBJCOPY			= arm-none-eabi-objcopy

#
# Tool options.
#
INCLUDE_DIRS		= $(SRC_DIR)

ARCH_FLAGS		= -mthumb -mcpu=cortex-m3
BASE_CFLAGS		= $(ARCH_FLAGS) \
			$(addprefix -D,$(OPTIONS)) \
			$(addprefix -I,$(INCLUDE_DIRS)) \
			-Wall \
			-ffunction-sections \
			-fdata-sections \
			-DSTM32F10X_MD \
			-DUSE_STDPERIPH_DRIVER \
			-D$(TARGET)

ASFLAGS			= $(ARCH_FLAGS) \
			-x assembler-with-cpp \
			$(addprefix -I,$(INCLUDE_DIRS))

# XXX Map/crossref output?
LD_SCRIPT		= $(SRC_DIR)/stm32_flash.ld
LDFLAGS			= -lm \
			$(ARCH_FLAGS) \
			-static \
			-Wl,-gc-sections  \
			--specs=nano.specs \
			-u _printf_float \
			-u _scanf_float \
			-T$(LD_SCRIPT)

#
# Things we will build
#
ifeq ($(filter $(TARGET),$(VALID_TARGETS)),)
$(error Target '$(TARGET)' is not valid, must be one of $(VALID_TARGETS))
endif

ifeq ($(DEBUG),GDB)
CFLAGS = $(BASE_CFLAGS) \
	-ggdb \
	-O0
else
CFLAGS = $(BASE_CFLAGS) \
	-Os
endif

TARGET_HEX	 = $(BIN_DIR)/$(TARGET).hex
TARGET_ELF	 = $(BIN_DIR)/$(TARGET).elf
TARGET_OBJS	 = $(addsuffix .o,$(addprefix $(OBJECT_DIR)/$(TARGET)/,$(basename $($(TARGET)_SRC))))

# List of buildable ELF files and their object dependencies.
# It would be nice to compute these lists, but that seems to be just beyond make.


$(TARGET_HEX): $(TARGET_ELF)
	@mkdir -p $(dir $@)
	@$(OBJCOPY) -O ihex $< $@

$(TARGET_ELF):  $(TARGET_OBJS)
	@mkdir -p $(dir $@)
	@$(CC)  -o $@ $^ $(LDFLAGS)

all:
# Compile
$(OBJECT_DIR)/$(TARGET)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo %% $(notdir $<)
	@$(CC) -c -o $@ $(CFLAGS) $<

# Assemble
$(OBJECT_DIR)/$(TARGET)/%.o: %.s
	@mkdir -p $(dir $@)
	@echo %% $(notdir $<)
	@$(CC) -c -o $@ $(ASFLAGS) $<

$(OBJECT_DIR)/$(TARGET)/%.o): %.S
	@mkdir -p $(dir $@)
	@echo %% $(notdir $<)
	@$(CC) -c -o $@ $(ASFLAGS) $<

clean:
	rm -f $(TARGET_HEX) $(TARGET_ELF) $(TARGET_OBJS)
