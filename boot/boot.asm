; Simple Bootloader Example

; BIOS loads us at 0x7c00
org 0x7c00

; Real mode
bits 16

; Disable interrupts
cli

; Infinite Loop
loop:
	jmp loop

; Fill the rest upto 512 bytes with zeros
times (510 - ($ - $$)) db 0

; Magic Number
magic dw 0xaa55
