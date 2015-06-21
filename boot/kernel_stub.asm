;*******************************************************************************
; NAME: kernel_stub.asm
;
; Kernel Stub
;*******************************************************************************
; The code should be organized at 0x100000 (1 MB)
org 0x100000
; 32-bit code (protected mode)
bits 32

jmp main

; Import VGA routines
%include "video32.inc"

main:
; Set segments to appropriate (data) descriptor value
	mov ax, 0x10		; Data descriptor offset in GDT
	mov ds, ax
	mov es, ax
	mov ss, ax
; Set stack pointer to start at 0x90000 (to 0x7e00)
	mov esp, 0x90000

; Clear Screen and print success
	call clrscr
	push dword .kernel_msg
	call puts32

; Halt the PC
	cli
	hlt

.kernel_msg:
	db 0xA, 0xA, "Welcome to Kernel Land!", 0xA, 0

; Fill with Junk (so that kernel is big and loading can be tested - 4K)
times	(4096 - ($ - $$))	db	0