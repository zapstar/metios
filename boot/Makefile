all: boot

boot:
	nasm boot.asm -f bin -o ../bin/boot.img
	nasm stage2.asm -f bin -o ../bin/KERNLD.SYS
