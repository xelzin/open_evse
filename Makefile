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
CINCS = -I$(ARDUINO_CORE) $(patsubst %,-I$(ARDUINO_DIR)/libraries/%,$(ARDLIBS)) $(patsubst %,-I$(HOME)/sketchbook/libraries/%,$(USERLIBS))

# Compiler flag to set the C Standard level.
# c89   - "ANSI" C
# gnu89 - c89 plus GCC extensions
# c99   - ISO C99 standard (not yet fully implemented)
# gnu99 - c99 plus GCC extensions
#CSTANDARD = -std=gnu99
CDEBUG = -g$(DEBUG)
#CWARN = -Wall -Wstrict-prototypes
#CTUNING =  -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
CTUNING = -felide-constructors -ffunction-sections -fdata-sections -fno-exceptions -std=c++0x -w -MMD
#CEXTRA = -Wa,-adhlns=$(<:.c=.lst)

CFLAGS = $(CDEBUG) $(CDEFS) $(CINCS) -O$(OPT) $(CWARN) $(CSTANDARD) $(CEXTRA) $(CTUNING)
#CXXFLAGS = $(CDEBUG) $(CDEFS) $(CINCS) -O$(OPT) $(CTUNING)
CXXFLAGS = -c -g -Os -felide-constructors -std=c++0x -w -MMD -fno-exceptions -ffunction-sections -fdata-sections -mmcu=$(MCU) -DF_CPU=$(F_CPU) $(CDEFS) $(CINCS)
#ASFLAGS = -Wa,-adhlns=$(<:.S=.lst),-gstabs 
LDFLAGS = -lm

# Programming support using avrdude. Settings and variables.
AVRDUDE_WRITE_FLASH = -U flash:w:$(TARGET).hex
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

# Combine all necessary flags and optional flags.
# Add target processor to flags.
ALL_CFLAGS = -mmcu=$(MCU) -I. $(CFLAGS)
ALL_CXXFLAGS = -mmcu=$(MCU) -I. $(CXXFLAGS)
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
upload: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)

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
	$(CXX) -c $(ALL_CXXFLAGS) $< -o $@

# Compile: create object files from C source files.
.c.o:
	$(CC) -c $(ALL_CFLAGS) $< -o $@ 

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
open_evse.o: open_evse.cpp open_evse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/wdt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/eeprom.h \
  arduino-0022/hardware/arduino/cores/arduino/pins_arduino.h \
  arduino-0022/hardware/arduino/cores/arduino/WProgram.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/WCharacter.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  libraries/RTClib/RTClib.h libraries/FlexiTimer2/FlexiTimer2.h \
  libraries/Time/Time.h libraries/Wire/Wire.h \
  libraries/LiquidTWI2/LiquidTWI2.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h rapi_proc.h
rapi_proc.o: rapi_proc.cpp open_evse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/wdt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/eeprom.h \
  arduino-0022/hardware/arduino/cores/arduino/pins_arduino.h \
  arduino-0022/hardware/arduino/cores/arduino/WProgram.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/WCharacter.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  libraries/RTClib/RTClib.h libraries/FlexiTimer2/FlexiTimer2.h \
  libraries/Time/Time.h libraries/Wire/Wire.h \
  libraries/LiquidTWI2/LiquidTWI2.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h rapi_proc.h
HardwareSerial.o:  \
 arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.cpp \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h
WMath.o: arduino-0022/hardware/arduino/cores/arduino/WMath.cpp \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h
WString.o: arduino-0022/hardware/arduino/cores/arduino/WString.cpp \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/WProgram.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/WCharacter.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h
Print.o: arduino-0022/hardware/arduino/cores/arduino/Print.cpp \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h
Wire.o: libraries/Wire/Wire.cpp \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  libraries/Wire/utility/twi.c \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/compat/twi.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/twi.h \
  libraries/Wire/utility/twi.h libraries/Wire/Wire.h
LiquidTWI2.o: libraries/LiquidTWI2/LiquidTWI2.cpp \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  libraries/LiquidTWI2/../Wire/Wire.h \
  arduino-0022/hardware/arduino/cores/arduino/WProgram.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/WCharacter.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  libraries/LiquidTWI2/LiquidTWI2.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h
RTClib.o: libraries/RTClib/RTClib.cpp libraries/RTClib/../Wire/Wire.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  libraries/RTClib/RTClib.h \
  arduino-0022/hardware/arduino/cores/arduino/WProgram.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/WCharacter.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h
FlexiTimer2.o: libraries/FlexiTimer2/FlexiTimer2.cpp \
  libraries/FlexiTimer2/FlexiTimer2.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h
Time.o: libraries/Time/Time.cpp \
  arduino-0022/hardware/arduino/cores/arduino/WProgram.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/string.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/math.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/WCharacter.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/ctype.h \
  arduino-0022/hardware/arduino/cores/arduino/WString.h \
  arduino-0022/hardware/arduino/cores/arduino/HardwareSerial.h \
  arduino-0022/hardware/arduino/cores/arduino/Stream.h \
  arduino-0022/hardware/arduino/cores/arduino/Print.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  libraries/Time/Time.h
pins_arduino.o:  \
 arduino-0022/hardware/arduino/cores/arduino/pins_arduino.c \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/pins_arduino.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h
wiring.o: arduino-0022/hardware/arduino/cores/arduino/wiring.c \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h
wiring_analog.o:  \
 arduino-0022/hardware/arduino/cores/arduino/wiring_analog.c \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/pins_arduino.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h
wiring_digital.o:  \
 arduino-0022/hardware/arduino/cores/arduino/wiring_digital.c \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/pins_arduino.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h
wiring_pulse.o:  \
 arduino-0022/hardware/arduino/cores/arduino/wiring_pulse.c \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/pins_arduino.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h
wiring_shift.o:  \
 arduino-0022/hardware/arduino/cores/arduino/wiring_shift.c \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h
WInterrupts.o: arduino-0022/hardware/arduino/cores/arduino/WInterrupts.c \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/inttypes.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdint.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/io.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/sfr_defs.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/iom328p.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/portpins.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/common.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/version.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/fuse.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/lock.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/interrupt.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/pgmspace.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stddef.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdio.h \
  c:\git\open_evse\arduino-0022\hardware\tools\avr\bin\../lib/gcc/avr/4.3.2/include/stdarg.h \
  arduino-0022/hardware/arduino/cores/arduino/WConstants.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/stdlib.h \
  arduino-0022/hardware/arduino/cores/arduino/binary.h \
  arduino-0022/hardware/arduino/cores/arduino/wiring_private.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/avr/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay.h \
  c:/git/open_evse/arduino-0022/hardware/tools/avr/lib/gcc/../../avr/include/util/delay_basic.h
