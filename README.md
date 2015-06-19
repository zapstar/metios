metios
======

MetiOS is a pet operating system that I'm cooking in my backyard. I'm following the tutorial on the [BrokenThorn Entertainment](http://www.brokenthorn.com/Resources/OSDevIndex.html) website

Progress
--------
- [X] First stage bootloader (loads the second stage bootloader)
	- [X] BIOS Partition Block
	- [X] Debug Print Routine
	- [X] Routine to convert Logical Block Address (LBA) to Cylinder Head Sector (CHS)
	- [X] Routine to convert CHS to LBA
	- [X] Routine to load FAT root directory into memory
	- [X] Routine to read FAT sectors into memory
	- [X] Build Scripts for Linux
	- [X] Build Scripts for Windows
- [ ] Second stage bootloader (loads the kernel)
	- [X] STDIO include file
	- [X] Global Descriptor Table (GDT) Installation
	- [X] Enter Protected Mode (32-bit)
	- [ ] Enable A20 line
- [ ] and so on...
