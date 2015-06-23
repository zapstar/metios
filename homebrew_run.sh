#!/bin/bash

# Home made bootloader and kernel run script

# (Should be root) This is because we mount the floppy drive to copy second
# stage bootloader into a mounted file system.

# Stop on error
set -e

# First compile the bootloader
mkdir -p bin/
cd boot/
make > /dev/null
cd ../

# Now copy second stage bootloader and the kernel stub onto floppy
losetup /dev/loop0 bin/homebrew_floppy.img
mount /dev/loop0 /mnt -t msdos -o "fat=12"
cp bin/KERNLD.SYS /mnt/
cp bin/KERNEL.EXE /mnt/
umount /mnt
losetup -d /dev/loop0

# Check for the presence of BOCHS
# Use this to install bochs if you've compiled it. (two lines, make into one)
# update-alternatives --install /usr/local/sbin/bochs \
# bochs /opt/bochs/bin/bochs 2000
which bochs > /dev/null

# Run home made bootloader and kernel
# With X workaround see this website for more info. Or if it has been fixed
# https://bugs.launchpad.net/ubuntu/+source/bochs/+bug/980167
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libXpm.so.4 \
bochs -q -f ./homebrew_bochsrc-linux.txt
