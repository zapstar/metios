all: boot

boot:
	nasm boot.asm -f bin -o ../bin/homebrew_floppy.img
	nasm stage2.asm -f bin -o ../bin/KERNLD.SYS
	nasm kernel_stub.asm -f bin -o ../bin/KERNEL.EXE
