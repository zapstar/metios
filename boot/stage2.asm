;******************************************************************************
; MiteOS Stage 2 Bootloader main source file
; @author: Thirumal Venkat

; @pre: We are loaded at linear address 0x500
;******************************************************************************
bits 16

; Let's assume that our code is aligned to zero, we'll change segments later on
org	0x500

; Start executing from main routine
	jmp main

; Import STDIO routines for bootloader
%include "video16.inc"
; Import GDT and its associated installer routine
%include "gdt.inc"
; Import function to enable the A20 line
%include "A20.inc"

;******************************************************************************
; Global variables (DATA SECTION)
;******************************************************************************
.boot2_msg	db	"Intializing second stage bootloader...", 13, 10, 0

;******************************************************************************
; Second Stage boot loader entry point
;******************************************************************************
; Real mode
bits	16

main:
; Disable interrupts for a while
	cli

; Make sure segment registers are NULL (except code segment)
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
; Our stack starts from 0xFFFF and is till 0x07E00
	mov ss, ax
	mov sp, 0xffff

; Enable interrupts again
	sti

; Print the initializing message for us
	push word .boot2_msg
	call puts16

; Install our GDT
	call gdt_install

; Enable A20 line (32-bit addressing, till now 20-bit addressing)
	call enable_A20

; Enter protected mode (by setting bit-0 of CR0 to 1)
	cli		; Disable interrupts
	mov eax, cr0
	or eax, 0x01	; Set the bit-0 to 1
	mov cr0, eax

; NOTE: Do NOT enable interrupts now, will triple fault if done so

; Make a far jump with offset 0x08 (code descriptor) in the GDT
	jmp 0x08:stage3

;*******************************************************************************
; Stage 3 Bootloader
;*******************************************************************************
; We're in protected mode, we're dealing with 32 bit instructions & registers
; But as the segment descriptors are setup with no translation so we'll still
; be using identity mapping
;
; By making the far jump to here our %CS and %EIP would have been reloaded
;
; Import 32-bit VGA routines
%include "video32.inc"

stage3:
bits 32

; Now setup our data, extended and stack segments with data descriptor
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov ss, ax

; Setup stack for 32-bit mode
	mov esp, 0x9ffff

; Clear the screen
	call clrscr

; Print a welcome message
	push dword .miteos_msg
	call puts32

; HALT for now. We'll look at what to do here later on
	cli			; Disable interrupts
	hlt			; Halt the system

; Message to be printed on 13th line in the center of the screen
.miteos_msg:
	db	10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10
	db	"                                     "
	db	"METIOS"
	db	0

; Stage 3 Bootloader VGA Driver Test Data
;msg	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"Newline and Overflow Slide Up Test", 0x0A,
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	"+=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789*!"
;	db	0
