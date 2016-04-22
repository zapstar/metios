CC = gcc
LD = ld
OBJDUMP = objdump
OBJCOPY = objcopy

GENOBJ = -c

CFLAGS += -fno-builtin
CFLAGS += -fno-omit-frame-pointer
CFLAGS += -fno-pic
CFLAGS += -fno-stack-protector
CFLAGS += -fno-strict-aliasing
CFLAGS += -fvar-tracking
CFLAGS += -fvar-tracking-assignments
CFLAGS += -g
CFLAGS += -gdwarf-2
CFLAGS += -m32
CFLAGS += -nostdinc
CFLAGS += -static
CFLAGS += -MD
CFLAGS += -O0
CFLAGS += -Wall
CFLAGS += -Werror

LDFLAGS = -m elf_i386 -N -e start -Ttext 0x0

all: boot

boot:
	$(CC) $(CFLAGS) $(INCFLAGS) $(GENOBJ) floppy16.S
	$(LD) $(LDFLAGS) -o boot.o floppy16.o
	$(OBJDUMP) -S boot.o > boot.asm
	$(OBJCOPY) -S -O binary -j .text boot.o boot

clean:
	rm -f boot boot.asm *.o