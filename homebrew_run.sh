#!/bin/bash

# Home made bootloader and kernel run script

# Stop on error
set -e

# First compile the bootloader
mkdir -p bin/
cd boot/
make
cd ../

# Now copy second stage bootloader onto floppy
losetup /dev/loop0 bin/homebrew_floppy.img
mount /dev/loop0 /mnt -t msdos -o "fat=12"
cp bin/KERNLD.SYS /mnt/
umount /mnt
losetup -d /dev/loop0

# Run home made bootloader and kernel
bochs -f homebrew_bochsrc.txt
