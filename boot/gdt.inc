;*******************************************************************************
; GDT.INC file
; This include file for the Global descriptor table
; for the use of second stage bootloader
;*******************************************************************************
%ifndef __BIOS__GDT_INC_
%define __BIOS__GDT_INC_
; Real Mode
bits 16

;*******************************************************************************
; Installs the GDT on the machine (Ring 0 only)
;*******************************************************************************

gdt_install:
	cli		; Clear interrupts
	pusha		; Save registers
	lgdt [gdt_toc]	; Load the GDT into GDTR
	popa		; Restore registers
	sti		; Enable interrupts
	ret

;*******************************************************************************
; Global Descriptor Table
;*******************************************************************************
gdt_start:
; Null Descriptor
	db 0x00		; Byte 0
	db 0x00		; Byte 1
	db 0x00		; Byte 2
	db 0x00		; Byte 3
	db 0x00		; Byte 4
	db 0x00		; Byte 5
	db 0x00		; Byte 6
	db 0x00		; Byte 7
; Code descriptor
	db 0xff		; Byte 0: Segment Limit 0 - 7 bits
	db 0xff		; Byte 1: Segment Limit 8 - 15 bits
	db 0x00		; Byte 2: Base Address 0 - 7 bits
	db 0x00		; Byte 3: Base Address 8 - 15 bits
	db 0x00		; Byte 4: Base Address 16 - 23 bits
	db 10011010b	; Byte 5: Access
			; Bit 0: Virtual Memory = 0
			; Bit 1: Readable/writable = 1
			; Bit 2: Expansion direction = 0
			; Bit 3: Code Descriptor = 1 (not data descriptor)
			; Bit 4: Code/data descriptor = 1
			; Bit 5-6: Privilege level (Ring 0 to Ring 3) = 0
			; Bit 7: Is segment in memory? = 1
	db 11001111b	; Byte 6: Granularity
			; Bit 0-3: Segment Limit 16-19 bits
			; Bit 4: Reserved for OS use (set to 1)
			; Bit 5: Reserved for Intel (set to 0)
			; Bit 6: Segment Type (32-bit = 1, 16-bit = 0)
			; Bit 7: Granularity (4K bound segment = 1, None = 0)
	db 0x00		; Byte 7: Base Address 24 - 32 bits
; Data descriptor
	db 0xff		; Byte 0: Segment Limit 0 - 7 bits
	db 0xff		; Byte 1: Segment Limit 8 - 15 bits
	db 0x00		; Byte 2: Base Address 0 - 7 bits
	db 0x00		; Byte 3: Base Address 8 - 15 bits
	db 0x00		; Byte 4: Base Address 16 - 23 bits
	db 10010010b	; Byte 5: Access
			; Bit 0: Virtual Memory = 0
			; Bit 1: Readable/writable = 1
			; Bit 2: Expansion direction = 0
			; Bit 3: Data Descriptor = 0 (not code descriptor)
			; Bit 4: Code/data descriptor = 1
			; Bit 5-6: Privilege level (Ring 0 to Ring 3) = 0
			; Bit 7: Is segment in memory? = 1
	db 11001111b	; Byte 6: Granularity
			; Bit 0-3: Segment Limit 16-19 bits
			; Bit 4: Reserved for OS use (set to 1)
			; Bit 5: Reserved for Intel (set to 0)
			; Bit 6: Segment Type (32-bit = 1, 16-bit = 0)
			; Bit 7: Granularity (4K bound segment = 1, None = 0)
	db 0x00		; Byte 7: Base Address 24 - 32 bits
gdt_toc:
	dw gdt_toc - gdt_start - 1	; Size of GDT - 1
	dd gdt_start			; Base Address for the GDT
%endif ;__BIOS__GDT_INC_
