;******************************************************************************
; MiteOS Stage 2 Bootloader main source file
; @author: Thirumal Venkat

; @pre: We are loaded at linear address 0x20000
;******************************************************************************

; Let's assume that our code is aligned to zero, we'll change it later on
org	0

; Start executing from main routine
	jmp main

%include "stdio.inc"

;******************************************************************************
; Second Stage boot loader entry point
;******************************************************************************
; Real mode
bits	16

main:
; Ensure that code segment and the data segment both are the same
	push cs
	pop ds
; Print the initializing message for us
	mov si, boot2_init_msg
	call puts16
; HALT for now. We'll look at what to do here later on
	cli			; Disable interrupts
	hlt			; Halt the system

;******************************************************************************
; Global variables (DATA SECTION)
;******************************************************************************
boot2_init_msg	db	"Intializing second stage bootloader...", 13, 10, 0