CC = gcc
LD = ld
OBJDUMP = objdump


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

INCFLAGS += -I.

boot:
	$(CC) $(CFLAGS) $(INCFLAGS) $(GENOBJ) floppy16.S