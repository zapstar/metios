#!/bin/bash

# Stop on error
set -e

# First compile everything
cd boot/
make
cd ../

# Now copy second stage bootloader onto floppy
losetup /dev/loop0 bin/boot.img
mount /dev/loop0 /mnt -t msdos -o "fat=12"
cp bin/KERNLD.SYS /mnt/
umount /mnt
losetup -d /dev/loop0

# Will use the local bin/boot.img with KERNLOAD.SYS for now
bochs
