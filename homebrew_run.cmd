@echo off
rem Home made bootloader and kernel run script
rem (Should be root) This is because we mount the floppy drive to copy second
rem stage bootloader into a mounted file system.
rem
rem This script should be run as an administrator, we mount a floppy

rem Set the drive letter for floppy (change it to any unused value)
set DRIVE=A

set BOCHS=bochs
rem set BOCHS=bochsdbg

rem Check for NASM installation
where nasm || ^
echo NASM not in PATH && goto :error

rem Check for Bochs installation
where bochs || ^
echo Bochs not in PATH && goto :error

rem Check for ImDisk installation
where imdisk || ^
echo ImDisk not in PATH && goto :error

rem Create the binary directory
if not exist bin mkdir bin || ^
echo Error making bin directory && goto :error

rem Change to boot loader directory
cd boot || ^
echo Did not find bootloader directory && goto :error

rem Compile the first stage bootloader
nasm boot.asm -f bin -o ..\bin\homebrew_floppy.img || ^
echo Error building first stage bootloader && goto :error

rem Compile the second stage bootloader
nasm stage2.asm -f bin -o ..\bin\KERNLD.SYS || ^
echo Error building second stage bootloader && goto :error

rem Return back home
cd .. || ^
echo Could not return back home && goto :error

rem Mount the floppy onto A drive
imdisk -a -t file -o rw,rem,fd -m %DRIVE%: -f bin\homebrew_floppy.img || ^
echo Error mounting floppy, please make sure A drive is free && goto :error

rem Now copy second stage bootloader onto floppy
copy bin\KERNLD.SYS %DRIVE%:\ || ^
echo Error copying second stage bootloader. Remove floppy manually ^
&& goto :error

rem Unmount the floppy, make it ready to boot
imdisk -D -m %DRIVE%: || ^
echo Error unmounting floppy, please force remove manually && goto :error

rem Run home made bootloader and kernel
%BOCHS% -q -f homebrew_bochsrc-win32.txt

rem Success, go to EOF
goto :EOF

rem Handle error conditions
:error
echo Exiting with error #%errorlevel%.
exit /b %errorlevel%
