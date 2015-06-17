;*******************************************************************************
; STDIO.INC file
; This include file for standard input output routines
; for the second stage bootloader
;*******************************************************************************

%ifndef __BIOS__STDIO_INC_
%define __BIOS__STDIO_INC_

;*******************************************************************************
; NAME:    puts16()
; PURPOSE: Prints a null terminated string on the screen
; @pre: DS=>SI should contain the address of a null terminated string
;*******************************************************************************
bits 16

puts16:
	push ax		; Save AX register
	push si		; Save SI register
	mov ah, 0eh	; Set 0x0E to AH to invoke print when BIOS interrupt
puts16loop:
	lodsb		; Fetch a byte from [SI] into AL
	or al,al	; OR AL with itself to set the CRs
	jz puts16done	; If AL is zero go to puts16done marker
	int 10h		; Invoke BIOS interrupt
	jmp puts16loop	; Go back to the loop
puts16done:
	pop si		; Restore SI register
	pop ax		; Restore AX register
	ret
;*******************************************************************************

%endif ;__BIOS__STDIO_INC_
