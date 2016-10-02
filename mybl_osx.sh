#!/bin/bash

# Home made bootloader and kernel run script

# Stop on error
set -e

# First compile the bootloader
mkdir -p bin/
cd boot/
make > /dev/null
cd ../

# Now copy second stage bootloader and the kernel stub onto floppy
#losetup /dev/loop0 bin/homebrew_floppy.img
# mount /dev/loop0 /mnt -t msdos -o "fat=12"
MOUNT_OUTPUT="$(hdiutil mount bin/homebrew_floppy.img)"
# Extract the mount point from the output
MOUNT_POINT=`echo $MOUNT_OUTPUT | cut -d' ' -f2- | cat`
# Copy the files
cp bin/KERNLD.SYS "$MOUNT_POINT"
cp bin/KERNEL.EXE "$MOUNT_POINT"
# Unmount it
hdiutil unmount "$MOUNT_POINT"

# Check for the presence of BOCHS
which bochs > /dev/null

# Run home made bootloader and kernel
bochs -q -f ./mybl_bochsrc-osx.txt
