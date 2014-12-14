;******************************************************************************
; MiteOS Stage 2 Bootloader main source file
; @author: Thirumal Venkat

; @pre: We are loaded at linear address 0x20000
;******************************************************************************

; Real mode
bits	16

; Let's assume that our code is aligned to zero, we'll change it later on
org	0

	jmp main

;******************************************************************************
; Debug print routine
; @pre: SI should contain the address of the string
;******************************************************************************
bios_print_msg:
.read_next:
	lodsb		; Picks a fresh byte from SI into AL
	cmp al, 0	; See if we have reached the end of the string
	jz .debug_done	; If so, prepare to exit the routine
	mov ah, 0x0e	; Print on TTY
	int 0x10	; Make the INT call
	jmp .read_next	; Get ready to print more
.debug_done:
	ret

;******************************************************************************
; Second Stage boot loader entry point
;******************************************************************************

main:
; Ensure that code segment and the data segment both are the same
	push cs
	pop ds
; Print the initializing message for us
	mov si, boot2_init_msg
	call bios_print_msg
; HALT for now. We'll look at what to do here later on
	cli			; Disable interrupts
	hlt			; Halt the system

;******************************************************************************
; Global variables (DATA SECTION)
;******************************************************************************

boot2_init_msg	db	"Intializing second stage bootloader...", 13, 10, 0