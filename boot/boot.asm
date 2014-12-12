;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MiteOS Bootloader main routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Real mode
bits 16

; BIOS partition block START (or else Windows will show us "Not formatted")
start:
	jmp boot_loader			; Three bytes of jump instruction
bpb_oem:
	db	"MITEOS  "		; Always should be 8 bytes of OS name
bpb_bytespersector:
	dw	512
bpb_sectorspercluster:
	db	1
bpb_reservedsectors:
	dw	1
bpb_numberoffats:
	db	2
bpb_rootentries:
	dw	224
bpb_totalsectors:
	dw	2880
bpb_media:
	db	0xf0
bpb_sectorsperfat:
	dw	9
bpb_sectorspertrack:
	dw	18
bpb_headspercylinder:
	dw	2
bpb_hiddensectors:
	dd	0
bpb_totalsectorsbig:
	dd	0
bs_drivenumber:
	db	0
bs_unused:
	db	0
bs_extbootsignature:
	db	0x29
bs_serialnumber:
	dd	0xa0a1a2a3		; Fake it with some unique random number
bs_volumelabel:
	db	"MITEOS FLOP"	; Always should be 11 bytes
bs_filesystem:
	db	"FAT12   "		; Always should be 8 bytes
; End of BIOS partition block

; Bootloader code
boot_loader:

; Disable interrupts
	cli

; Clear the AX, DS and ES registers
; Set all the segment registers to 0x07c0
; BIOS loads the code at address 0x07c00 (20bit real mode)
	mov ax, 0x7c0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

; Now create the stack of size 65536
	xor ax, ax	; Clear AX
	mov ss, ax	; Stack segment at 0x0000
	mov sp, 0xffff	; Our stack pointer at 0xFFFF

; Enable interrupts again
	sti

; Print our message
	mov si, welcome_msg
	call debug_print



; Halt the CPU
	hlt

; Welcome message of the operating system
welcome_msg:
	db	"Weclome to MiteOS", 13, 10, 0

;; Debug print routine
; @pre: SI should contain the address of the string
debug_print:
	lodsb			; Picks a byte from SI into AL
	cmp al, 0		; See if we have reached the end of the string
	jz debug_done	; If so, prepare to exit the routine
	mov ah, 0eh		; Print on TTY
	int 0x10		; Make the INT call
	jmp debug_print	; Get ready to print more
debug_done:
	ret

; Fill the rest up to 512 bytes with zeros
times		(510 - ($ - $$)) db 0

; Magic Number
boot_magic:
	dw	0xaa55