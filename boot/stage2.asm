;******************************************************************************
; MiteOS Stage 2 Bootloader main source file
; @author: Thirumal Venkat

; @pre: We are loaded at linear address 0x20000
;******************************************************************************

; Let's assume that our code is aligned to zero, we'll change segments later on
org	0x20000

; Start executing from main routine
	jmp main

; Import STDIO routines for bootloader
%include "stdio.inc"
; Import GDT and its associated installer routine
%include "gdt.inc"

;******************************************************************************
; Global variables (DATA SECTION)
;******************************************************************************
boot2_init_msg	db	"Intializing second stage bootloader...", 13, 10, 0

;******************************************************************************
; Second Stage boot loader entry point
;******************************************************************************
; Real mode
bits	16

main:
; Disable interrupts for a while
	cli

; Make sure code segment and data segment point to 0x20000
	push cs
	pop ds

; Our stack starts from 0x20000 and is till 0x07E00
	xor ax, ax
	mov sp, 0xffff
	mov ax, 0x9000
	mov ss, ax

; Enable interrupts again
	sti

; Print the initializing message for us
	mov si, boot2_init_msg
	call puts16

; Install our GDT
	call gdt_install

; Enter protected mode (by setting bit-0 of CR0 to 1)
	cli		; Disable interrupts
	mov eax, cr0
	or eax, 0x01	; Set the bit-0 to 1
	mov cr0, eax

; NOTE: Do NOT enable interrupts now, will triple fault if done so

; Make a far jump with offset 0x08 in the GDT
	jmp 0x08:stage3

;*******************************************************************************
; Stage 3 Bootloader
;*******************************************************************************
; We're in protected mode, we're dealing with 32 bit instructions & registers
; But as the segment descriptors are setup with no translation so we'll still
; be using identity mapping
;
; By making the far jump to here our %cs and %eip would have been reloaded
;
stage3:
bits 32

; Now setup our data segment
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov ss, ax

; Zero out unused segments
	mov ax, 0x00
	mov fs, ax
	mov gs, ax

; Setup stack for 32-bit mode
	mov esp, 0x90000

; HALT for now. We'll look at what to do here later on
;	cli
;	hlt			; Halt the system
