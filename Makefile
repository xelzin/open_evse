# Makefile for building Arduino sketches with Arduino 0022
# Makefile-0022 v0.4 by Akkana Peck <akkana@shallowsky.com>
#
# Adapted from a long-ago Arduino 0011 Makefile by mellis, eighthave, oli.keller
#
# This Makefile allows you to build sketches from the command line
# without the Arduino environment (or Java).
#
# Detailed instructions for using this Makefile:
#
#  1. Copy this file into the folder with your sketch.
#     There should be a file with the extension .pde (e.g. blink.pde).
#     cd into this directory.
#
#  2. Below, modify the line containing "TARGET" to refer to the name of
#     of your program's file without an extension (e.g. TARGET = foo).
#
#  3. Modify the line containg "ARDUINO_DIR" to point to the directory that
#     contains the Arduino installation (for example, under Mac OS X, this
#     might be /Applications/arduino-0022). If it's in your home directory,
#     you can include $(HOME) as part of the path.
#
#  4. Set ARDUINO_MODEL to your Arduino model.
#     I have only tested uno, atmega328, and diecimila,
#     but there are lots of other options:
#     see $(ARDUINO_DIR)/hardware/arduino/boards.txt for a list.
#     If you're using one of the other models you might have to modify
#     PORT; let me know if you do, so I can update this Makefile.
#
#  5. Run "make" to compile/verify your program.
#
#  6. Run "make download" (and reset your Arduino if it requires it)
#     to download your program to the Arduino board.
#

MCU = atmega328p
F_CPU = 16000000L

# Name of the program and main cpp file:
TARGET = open_evse

#CDEFS = -DAMMETER -DRTC 
CDEFS = -DAMMETER -DRAPI -DRTC 
CDEFS += -DKWH_RECORDING
# for LiquidTWI2 - -DMCP23017 for RGB, -DMCP23008 for I2C backpack
CDEFS += -DMCP23017

CPPSRC = $(TARGET).cpp rapi_proc.cpp
OBJS = $(TARGET).o rapi_proc.o

# Standard Arduino libraries it will import, e.g. LiquidCrystal:
ARDLIBS = 

#libs in libraries/
USERLIBS = Wire LiquidTWI2 RTClib FlexiTimer2 Time

# Where do you keep the official Arduino software package?
ARDUINO_DIR = arduino-0022

# Where are tools like avr-gcc located on your system?
AVR_TOOLS_PATH = $(ARDUINO_DIR)/hardware/tools/avr/bin
AVR_UTIL_PATH = $(ARDUINO_DIR)/hardware/tools/avr/utils/bin


############################################################################
# Below here nothing should need to be changed. Cross your fingers!

AVRDUDE_PROGRAMMER = USBasp

CWD = $(shell pwd)
CWDBASE = $(shell basename `pwd`)
TARFILE = $(TARGET)-$(VERSION).tar.gz

ARDUINO_CORE = $(ARDUINO_DIR)/hardware/arduino/cores/arduino
SRC = $(ARDUINO_CORE)/pins_arduino.c $(ARDUINO_CORE)/wiring.c \
    $(ARDUINO_CORE)/wiring_analog.c $(ARDUINO_CORE)/wiring_digital.c \
    $(ARDUINO_CORE)/wiring_pulse.c \
    $(ARDUINO_CORE)/wiring_shift.c $(ARDUINO_CORE)/WInterrupts.c

CXXSRC = $(ARDUINO_CORE)/HardwareSerial.cpp $(ARDUINO_CORE)/WMath.cpp \
    $(ARDUINO_CORE)/WString.cpp $(ARDUINO_CORE)/Print.cpp \
    $(foreach l,$(ARDLIBS),$(ARDUINO_DIR)/libraries/$l/$l.cpp) \
    $(foreach l,$(USERLIBS),libraries/$l/$l.cpp)

FORMAT = ihex

# Name of this Makefile (used for "make depend").
MAKEFILE = Makefile

# Debugging format.
# Native formats for AVR-GCC's -g are stabs [default], or dwarf-2.
# AVR (extended) COFF requires stabs, plus an avr-objcopy run.
DEBUG = stabs

OPT = s

# Include directories
CINCS = -I. -I$(ARDUINO_CORE) $(patsubst %,-I$(ARDUINO_DIR)/libraries/%,$(ARDLIBS)) $(patsubst %,-I$(HOME)/sketchbook/libraries/%,$(USERLIBS))

CXXFLAGS = -c -g -Os -felide-constructors -std=c++0x -w -MMD -fno-exceptions -ffunction-sections -fdata-sections -mmcu=$(MCU) -DF_CPU=$(F_CPU)  -DARDUINO=22 $(CDEFS) $(CINCS)
#ASFLAGS = -Wa,-adhlns=$(<:.S=.lst),-gstabs 
LDFLAGS = -lm

# Programming support using avrdude. Settings and variables.
AVRDUDE_WRITE_FLASH = -U flash:w:$(TARGET).hex
AVRDUDE_FUSES = -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m -U efuse:w:0x07:m
AVRDUDE_FLAGS = -p $(MCU) -c $(AVRDUDE_PROGRAMMER) -C $(ARDUINO_DIR)/hardware/tools/avr/etc/avrdude.conf

# Program settings
CC = $(AVR_TOOLS_PATH)/avr-gcc
CXX = $(AVR_TOOLS_PATH)/avr-g++
OBJCOPY = $(AVR_TOOLS_PATH)/avr-objcopy
OBJDUMP = $(AVR_TOOLS_PATH)/avr-objdump
AR  = $(AVR_TOOLS_PATH)/avr-ar
SIZE = $(AVR_TOOLS_PATH)/avr-size
NM = $(AVR_TOOLS_PATH)/avr-nm
AVRDUDE = $(AVR_TOOLS_PATH)/avrdude
RM = $(AVR_UTIL_PATH)/rm -f
MV = $(AVR_UTIL_PATH)/mv -f

# Define all object files.
OBJ = $(SRC:.c=.o) $(CXXSRC:.cpp=.o) $(ASRC:.S=.o) 
DBG = $(SRC:.c=.d) $(CXXSRC:.cpp=.d) $(CPPSRC:.cpp=.d)

# Define all listing files.
LST = $(ASRC:.S=.lst) $(CXXSRC:.cpp=.lst) $(SRC:.c=.lst)

ALL_ASFLAGS = -mmcu=$(MCU) -I. -x assembler-with-cpp $(ASFLAGS)

# Default target.
all: build elfsize

test:
	@echo CXXSRC = $(CXXSRC)

build: elf hex 

elf: $(TARGET).elf
hex: $(TARGET).hex
eep: $(TARGET).eep
lss: $(TARGET).lss 
sym: $(TARGET).sym

# Program the device.  
flash: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)
# set the fuses
fuses: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_FUSES)


	# Display size of file.
HEXSIZE = $(SIZE) --target=$(FORMAT) $(TARGET).hex
ELFSIZE = $(SIZE)  $(TARGET).elf
elfsize:
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_BEFORE); $(ELFSIZE); echo; fi
sizebefore:
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_BEFORE); $(HEXSIZE); echo; fi

sizeafter:
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_AFTER); $(HEXSIZE); echo; fi

# Convert ELF to COFF for use in debugging / simulating in AVR Studio or VMLAB.
COFFCONVERT=$(OBJCOPY) --debugging \
    --change-section-address .data-0x800000 \
    --change-section-address .bss-0x800000 \
    --change-section-address .noinit-0x800000 \
    --change-section-address .eeprom-0x810000 

coff: $(TARGET).elf
	$(COFFCONVERT) -O coff-avr $(TARGET).elf $(TARGET).cof


extcoff: $(TARGET).elf
	$(COFFCONVERT) -O coff-ext-avr $(TARGET).elf $(TARGET).cof

.SUFFIXES: .elf .hex .eep .lss .sym

.elf.hex:
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $< $@

.elf.eep:
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O $(FORMAT) $< $@

# Create extended listing file from ELF output file.
.elf.lss:
	$(OBJDUMP) -h -S $< > $@

# Create a symbol table from ELF output file.
.elf.sym:
	$(NM) -n $< > $@

	# Link: create ELF output file from library.
$(TARGET).elf: $(OBJ) $(OBJS) libcore.a 
	$(CC) -Os -Wl,--gc-sections,--relax -mmcu=$(MCU) -o $@ $(OBJS) libcore.a -lm

libcore.a: $(OBJ)
	@for i in $(OBJ); do echo $(AR) rcs libcore.a $$i; $(AR) rcs libcore.a $$i; done

# Compile: create object files from C++ source files.
.cpp.o:
	$(CXX) -c $(CXXFLAGS) $< -o $@

# Compile: create object files from C source files.
.c.o:
	$(CC) -c $(CXXFLAGS) $< -o $@ 

# Compile: create assembler files from C source files.
.c.s:
	$(CC) -S $(ALL_CFLAGS) $< -o $@


# Assemble: create object files from assembler source files.
.S.o:
	$(CC) -c $(ALL_ASFLAGS) $< -o $@

# Target: clean project.
clean:
	$(RM) $(OBJS) $(OBJ) $(DBG) $(TARGET).elf $(TARGET).eep libcore.a

tar: $(TARFILE)

$(TARFILE): 
	( cd .. && \
	  tar czvf $(TARFILE) --exclude=applet --owner=root $(CWDBASE) && \
	  mv $(TARFILE) $(CWD) && \
	  echo Created $(TARFILE) \
	)

depend:
	if grep '^# DO NOT DELETE' $(MAKEFILE) >/dev/null; \
	then \
		sed -e '/^# DO NOT DELETE/,$$d' $(MAKEFILE) > \
			$(MAKEFILE).$$$$ && \
		$(MV) $(MAKEFILE).$$$$ $(MAKEFILE); \
	fi
	echo '# DO NOT DELETE THIS LINE -- make depend depends on it.' \
		>> $(MAKEFILE); \
	$(CC) -M -mmcu=$(MCU) $(CDEFS) $(CINCS) $(CPPSRC) $(CXXSRC) $(SRC) $(ASRC) >> $(MAKEFILE)

.PHONY:	all build elf hex eep lss sym program coff extcoff clean depend applet_files sizebefore sizeafter


# DO NOT DELETE THIS LINE -- make depend depends on it.
