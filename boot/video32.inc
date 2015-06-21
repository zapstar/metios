;*******************************************************************************
; VGA Graphics routines for second stage bootloader (32-bit mode)
;*******************************************************************************
%ifndef __BIOS__VIDEO32_INC_
%define __BIOS__VIDEO32_INC_
bits 32

%define	VIDMEM	0xB8000		; Video memory location
%define	COLS	80		; No. of columns on the screen
%define ROWS	25		; No. of rows on the screen
; Character Attribute Text Bit Map (0/1)
; Bit 0: Red FG Color (N/Y)
; Bit 1: Green FG Color (N/Y)
; Bit 2: Blue FG Color (N/Y)
; Bit 3: Foreground Intensity (Low/High)
; Bit 4: Red BG Color (N/Y)
; Bit 5: Red BG Color (N/Y)
; Bit 6: Red BG Color (N/Y)
; Bit 7: Blinking Text (N/Y)
%define CHATTR	0x07		; Light grey text on black background

; Current (x,y) position to place our character
; Limits: 0 <= x < 25 and 0 <= y < 80
_cur_x	db	0
_cur_y	db	0

;*******************************************************************************
; NAME: _slide_up()
;
; Function to slide up all rows on the screen (32-bit mode)
; @post: The first row is forgotten and last row is cleared
;
; Each row is COLS * 2 times wide (160 characters)
; We're copying 4 bytes at a time. So to copy a row we need to copy 40 times
; We have to run this loop 24 times. So a total of 960 times of copying DWORDs
;
; For Internal use only
;
;*******************************************************************************
_slide_up:
	pusha
; Let EDI have VIDMEM
	mov edi, VIDMEM
; Make EAX contain the total number of times the loop has to run
	mov eax, COLS / 2	; 40 copies for a row
	mov ecx, ROWS - 1	; 24 columns to be shifted up
	mul cl
._sl_loop1:
	cmp ax, 0 ; while (AX < 960) 
	je ._sl_done1
; Copy the word from next row into this row
	mov ebx, dword [edi + (COLS * 2)]
	mov dword [edi], ebx
	add edi, 4		; Move to the next double word
	dec ax
	jmp ._sl_loop1
; Fill the last row with spaces
._sl_done1:
	xor ax, ax
	mov dh, CHATTR
	mov dl, ' '
._sl_loop2:
	cmp ax, COLS
	je ._sl_done2
	mov word [edi], dx
	add edi, 2
	inc ax
	jmp ._sl_loop2
._sl_done2:
	dec byte [_cur_y]
	popa
	ret

;*******************************************************************************
; NAME: _putc32()
;
; Function to put a character on screen (32-bit mode)
; @pre: Push a character into stack and call this routine
; @post: Character is printed on the screen
;
; Each character is made up of two bytes. One for the actual character
; The other is filled with character attributes. Colors for foreground and
; background, intensity of the foreground colors etc.
;
; IMPORTANT NOTE:
; Function only intended for internal use only. See putc32 for the exported
; function. This function does not move the cursor once the character has
; been inserted. This lets me optimize puts32 which moves the cursor once
; after the string has been printed
;*******************************************************************************
_putc32:
	pop dword ebp			; Get the CALL stack 
	pop word bx			; Populate the pushed value in BX
	pusha
; Get current offset in EAX
; First calculate the correct number of bytes to offset for the rows
	xor eax, eax		; Set EAX to zero
	mov ecx, COLS * 2	; Number of bytes in a row
	mov al, byte [_cur_y]	; Load _cur_y (no. or rows from top) into AL
	mul ecx			; Multiply AL with ECX and store in EAX
	push eax		; Save EAX (multiplication)
; Now calculate the correct number of bytes to offset for the columns
	mov al, byte [_cur_x]	; Load _cur_x (no. of cols from left) into AL
	mov cl, 2		; Load multiplicand 2 into CL
	mul cl			; Multiply AL with CL and store (x * 2) in EAX
	pop ecx			; Fetch (y * COLS * 2) into ECX
	add eax, ecx		; EAX = (y * COLS  + x) * 2
; Add offset to video memory address
	xor ecx, ecx
	mov edi, VIDMEM
	add edi, eax		; Add EAX to video memory location
; Watch out for newline character, if so move to the next row
	cmp bl, 0x0A
	je .pc32_next_row
; Print a character, if its not newline
	mov dl, bl		; Now DL contains the actual character
	mov dh, CHATTR		; Now DH contains the character attribute
	mov word [edi], dx	; Move it onto desired video memory
; Update the position for the next character
	inc byte [_cur_x]
	cmp byte [_cur_x], COLS
; See if the next character overflows the screen? If not we're done
	jl .pc32_done
.pc32_next_row:
; Move to the next row if we're overflowing the columns to more than 80?
	mov byte [_cur_x], 0
	inc byte [_cur_y]
; Check if we've overflown the rows to more than 25, if so slide up one row
	cmp byte [_cur_y], ROWS
	jl .pc32_done
	call _slide_up
; We're done with printing a character
.pc32_done:
	popa
	push dword ebp		; Restore call stack
	ret

;*******************************************************************************
; NAME: _move_cursor()
;
; Move the cursor to the current position mentioned by _cur_x and _cur_y
; @pre: _cur_x and _cur_y contain the correct position to put a character
;	on the screen
; @post: cursor placed at the correct position on the screen
;*******************************************************************************
_move_cursor:
	pusha
; Calculate the location from _cur_y and _cur_x and push it into EBX later on
	xor eax, eax
	mov ecx, COLS
	mov al, byte [_cur_y]
	mul ecx
	add al, byte [_cur_x]
	mov ebx, eax
; Set low byte index to VGA register
	mov al, 0x0f		; Cursor Location low byte
	mov dx, 0x03D4		; Index register
	out dx, al		; Write AL into CRT Controller's Index Register
	mov al, bl		; Fill low byte of EBX into AL
	mov dx, 0x03D5		; Data Register
	out dx, al		; Write AL into CRT Controller's Data Register
; Set high byte index to VGA register
	mov al, 0x0e		; Cursor Location high byte
	mov dx, 0x03D4		; Index Register
	out dx, al		; Write AL into CRT Controller's Index Register
	mov al, bh		; Fill high byte of EBX into AL
	mov dx, 0x03D5		; Data Register
	out dx, al		; Write AL into CRT Controller's Data Register
	popa
	ret

;*******************************************************************************
; NAME: putc32()
;
; Function to print a character on screen (32-bit mode)
; @pre: Push a  character (2 byte) with high byte 0 and then call the routine
; @post: Character is printed on the screen
;
; Wrapper to _putc32 internal routine. Can be exposed to external routines
;*******************************************************************************
putc32:
; Put a character on the screen
	call _putc32
; Move the cursor to the correct position
	call _move_cursor
	ret

;*******************************************************************************
; NAME: puts32()
;
; Function to put a string on screen (32-bit mode)
; @pre: Push the address (32-bit) and call the routine
; @post: String is printed on the screen
;
; Internally we make use of putc32 routine
;*******************************************************************************
puts32:
	pop dword ebp		; Get the call stack
	pop dword esi		; Populate the pushed result in ESI
	pusha
	xor bh, bh
.ps32_loop:
	mov bl, byte [esi]	; Copy the string's byte into BL
	cmp bl, 0		; See if NULL, if so exit
	je .ps32_done
; Character is not NULL make the putc32() call with BL holding the character
	push word bx
	call _putc32
; Go to the next character
	inc esi
	jmp .ps32_loop
.ps32_done:
; Move the cursor to the correct position on the screen
	call _move_cursor
	popa
	push dword ebp		; Restore the call stack
	ret

;*******************************************************************************
; NAME: clrscr()
;
; Clears the screen in 32-bit mode
;
; Psuedocode:
; Clear the direction flags
; EDI will be filled with video memory address
; CX will be filled with ROWS * COLS
; AH will be filled with CHATTR
; AL with be filled with space
; Then we invoke store word to string for CX repetitions
; Can be exported
;*******************************************************************************
clrscr:
	pusha
	cld		; Clear direction flag
	mov edi, VIDMEM
	mov cx, ROWS * COLS
	mov ah, CHATTR
	mov al, ' '
	rep stosw
; Reset the current pointers
	mov byte [_cur_y], 0
	mov byte [_cur_x], 0
; Move cursor to the appropriate point
	call _move_cursor
	popa
	ret
%endif ; __BIOS__VIDEO32_INC_
