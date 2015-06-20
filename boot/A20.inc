;*******************************************************************************
; Function to enable the A20 line
;
; This function should be run in real mode only
;
; Reference:
; in al, 0x60	; Read from keyboard input buffer
; out 0x60, al	; Write to keyboard output buffer
; in al, 0x64	; Read keyboard status register of controller into AL
; out 0x64, al	; Send command in AL to keyboard controller
;*******************************************************************************
bits 16

enable_A20:
; Disable interrupts
	cli

; Save registers
	pusha

; Wait until keyboard is free
	call wait_till_input_buffer_clear

; Disable the keyboard with 0xAD command
	mov al, 0xAD
	out 0x64, al

; Wait until keyboard is free
	call wait_till_input_buffer_clear

; Ask keyboard to fetch output port data into input buffer using 0xD0
	mov al, 0xD0
	out 0x64, al

; Wait until keyboard is free
	call wait_till_output_buffer_clear

; Get output port data from the input buffer
	in al, 0x60

; OR fetched keyboard data with 0x02, Save EAX for future use
	or al, 0x02
	push ax

; Wait until keyboard is free
	call wait_till_input_buffer_clear

; Send write output command (0xD1)
	mov al, 0xD1
	out 0x64, al

; Wait until keyboard is free
	call wait_till_input_buffer_clear

; Send the ORed data back to keyboard
	pop ax
	out 0x60, al

; Wait until keyboard is free again
	call wait_till_input_buffer_clear

; Enable the keyboard with the 0xAE command
	mov al, 0xAE
	out 0x64, al

; Wait till keyboard becomes free again
	call wait_till_input_buffer_clear

; Pop registers
	popa

; Enable interrupts
	sti

; Return
	ret

;*******************************************************************************
; Function to check if the keyboard input buffer is free
;*******************************************************************************
wait_till_input_buffer_clear:
	in al, 0x64		; Read keyboard status register into AL
	test al, 0x02		; Bitwise AND with 2nd bit and set ZF if != 0
	jnz wait_till_input_buffer_clear
	ret

;*******************************************************************************
; Function to check if the keyboard output buffer is free
;*******************************************************************************
wait_till_output_buffer_clear:
	in al, 0x64		; Read keyboard status register into AL
	test al, 0x01		; Bitwise AND with 1st bit and set ZF if == 0
	jz wait_till_output_buffer_clear
	ret
