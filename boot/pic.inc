;*******************************************************************************
; Initialize the two 8259A PICs on the PC
;
; Map the PIC to use INT 32-39 for IRQ 0-7 and INT 40-47 for IRQ 8-15
;*******************************************************************************
; Terminology:
;
; PIC	Programmable Interrupt Controller
; IRQ	Interrupt Request
; ICW	Initialization Control Word

; ICW #1
; Primary control word sent to PIC
; Bit 0: We'll be sending IC4 later on
; Bit 4: PIC needs to be initialized
%define ICW_1		00010001b
; ICW #2
; Specifies which IRQs map to which interrupts
; IRQ 0-7 mapped to INT 32-39 (hence address 32 or 0x20)
%define ICW_2_PIC_1	0x20
; IRQ 8-15 mapped to INT 40-47 (hence address 40 or 0x28)
%define ICW_2_PIC_2	0x28
; ICW #3
; Tells which IR Line the other PIC uses to communicate with you
; IR2 for PIC_1 is bit-2 (IR3 for PIC_1 is bit-3 and so on ...)
%define ICW_3_PIC_1	00000100b
; IR2 for PIC_2 is 010b (IR3 for PIC_2 is 011b and so on ...)
%define ICW_3_PIC_2	00000010b
; ICW #4
; How the PIC operates
; Bit 0: 80x86 mode enabled
%define ICW_4		00000001b

; Command Registers in PICs
%define PIC_1_CTRL	0x20
%define PIC_1_DATA	0x21

%define PIC_2_CTRL	0xA0
%define PIC_2_DATA	0xA1

init_pic:
	push ax
; Send ICW #1 to both PICs control register
	mov al, ICW_1
	out PIC_1_CTRL, al
	out PIC_2_CTRL, al
; Send ICW #2 to both PICs data register
	mov al, ICW_2_PIC_1
	out PIC_1_DATA, al
	mov al, ICW_2_PIC_2
	out PIC_2_DATA, al
; Send ICW #3 to both PICs data register
	mov al, ICW_3_PIC_1
	out PIC_1_DATA, al
	mov al, ICW_3_PIC_2
	out PIC_2_DATA, al
; Send ICW #4 to both PICs data register
	mov al, ICW_4
	out PIC_1_DATA, al
	out PIC_2_DATA, al
; Done initializing, NULL out PICs data register
	xor al, al
	out PIC_1_DATA, al
	out PIC_2_DATA, al
; Return
	pop ax
	ret
