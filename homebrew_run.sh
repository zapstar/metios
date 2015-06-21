#!/bin/bash

# Home made bootloader and kernel run script

# (Should be root) This is because we mount the floppy drive to copy second
# stage bootloader into a mounted file system.

# Stop on error
set -e

# First compile the bootloader
mkdir -p bin/
cd boot/
make
cd ../

# Now copy second stage bootloader and the kernel stub onto floppy
losetup /dev/loop0 bin/homebrew_floppy.img
mount /dev/loop0 /mnt -t msdos -o "fat=12"
cp bin/KERNLD.SYS /mnt/
cp bin/KERNEL.EXE /mnt/
umount /mnt
losetup -d /dev/loop0

# Run home made bootloader and kernel
bochs -f homebrew_bochsrc-linux.txt
