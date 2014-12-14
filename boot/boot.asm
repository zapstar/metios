;******************************************************************************
; MiteOS Stage 1 Bootloader main source file
; @author: Thirumal Venkat
;******************************************************************************

; Real mode
bits	16

; Let's assume that our code is aligned to zero, we'll change it later on
org	0

;******************************************************************************
; BIOS partition block START (or else Windows will show us "Not formatted")
;******************************************************************************
start:
	jmp boot_loader		; Three bytes of jump instruction
bpb_oem:
	db	"MITEOS  "	; Always should be 8 bytes of OS name
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
; Media SPEC: single sided, 9 sector per FAT, 80 tracks, removable floppy
bpb_media:
	db	0xf8
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
	dd	0xa0a1a2a3	; Fake it with some unique random number
bs_volumelabel:
	db	"MITEOS FLOP"	; Always should be 11 bytes
bs_filesystem:
	db	"FAT12   "	; Always should be 8 bytes
;******************************************************************************
; End of BIOS partition block
;******************************************************************************

;******************************************************************************
; Debug print routine
; @pre: SI should contain the address of the string
;******************************************************************************
debug_print:
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
;
; Convert LBA to CHS
;
; @pre: AX will be filled with LBA to convert
; @post: abs_sect = (logical sector / sectors per track) + 1
; @post: abs_head = (logical sector / sectors per track) % Number of Heads
; @post: abs_trak = logical sector / (sectors per track * number of heads)
;
;******************************************************************************
lba_to_chs:
	xor dx, dx
	div word [bpb_sectorspertrack]
	inc dl
	mov byte [abs_sect], dl
	xor dx, dx
	div word [bpb_headspercylinder]
	mov byte [abs_head], dl
	mov byte [abs_trak], al
	ret

;******************************************************************************
; Routine to read a series of sectors into memory
; @pre: AX will have the cluster number
;******************************************************************************
read_sectors:
.main:
	mov di, 5				; 5 retries
.sector_loop:
	push ax
	push bx
	push cx
	call lba_to_chs				; Now abs_* will be filled
	mov ah, 2
	mov al, 1
	mov ch, byte [abs_trak]
	mov cl, byte [abs_sect]
	mov dh, byte [abs_head]
	mov dl, byte [boot_drive]
	int 0x13				; Invoke disk read
	jnc .success
; We failed to read, we'll decrement DI once and try again
	xor ax,ax				; Reset floppy AH=command 0x00
	int 0x13				; DL is still boot_drive
	dec di
	pop cx
	pop bx
	pop ax
	jnz .sector_loop
; We've failed 5 times! Display No ROM BASIC and halt
	int 0x18
; Success in reading 1 sector, see if we need to read the next one
.success:
	mov si, progress_msg
	call debug_print
	pop cx
	pop bx
	pop ax
	add bx, word [bpb_bytespersector]	; Next address to load
	inc ax					; Next sector
	loop .main
	ret

;******************************************************************************
; Bootloader entry point
;******************************************************************************
boot_loader:

; Disable interrupts
	cli

; Clear the AX, DS and ES registers
; Set all the segment registers to 0x07c0
; BIOS loads the code at address 0x07c00 (20bit real mode)
	mov ax, 0x07c0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

; Now create the stack
	xor ax, ax	; Clear AX
	mov ss, ax	; Stack segment at 0x0000
	mov sp, 0xffff	; Our stack pointer at 0xFFFF

; Save boot drive information for later (Given to us by BIOS)
	mov [boot_drive], dl

; Enable interrupts again
	sti

; Print our message
	mov si, welcome_msg
	call debug_print

;******************************************************************************
; Load root directory table into memory
;
; Number of sectors to read = FAT 12 directory entry * total directory size /
;                                         number of bytes per sector
;
; Location of root directory = Reserved sectors +
;                                         (No. of FATs * sectors per FAT)
;
;******************************************************************************
; Computer size of root directory first
	xor cx, cx
	xor dx, dx
	mov ax, 32			; FAT 12 directory entry size
	mul word [bpb_rootentries]	; Total size of directory (224)
	div word [bpb_bytespersector]	; Find number of sectors
	xchg ax, cx			; Store size in CX
; Next compute the location of the root directory
	mov al, byte [bpb_numberoffats]		; Number of FATs
	mul word [bpb_sectorsperfat]		; sectors used by FATs
	add ax, word [bpb_reservedsectors]	; Adjust for reserved sectors
; Keep the actual start of data sector in a global variable
	mov word [data_sector], ax
	add word [data_sector], cx
	mov bx, 0x0200		; Copy the root directory at 0x07c0:0x0200
	call read_sectors	; Read the root directory into memory

;******************************************************************************
; Find the stage 2 bootloader file
; In our case STAGE2 bootloader is stored in variable boot2_name
;******************************************************************************
	mov cx, word [bpb_rootentries]	; Load counter with no. of root entries
	mov di, 512			; First root entry in memory
.search_loop:
	push cx				; Save counter for later
	mov cx, 11			; 11 bytes of file name
	mov si, boot2_name		; SI with address of file name
	push di				; Save DI
	rep cmpsb			; Compare string
	je .search_done			; If equal DI has entry
	pop di
	pop cx
	add di, 32			; If not, increment 32 bytes and search
	loop .search_loop
; If CX is 0, we haven't found the file. Go to failure
	jmp boot_failure
.search_done:
	pop di
	pop cx

; SHOULD NOT COME HERE
; Disable interrupts and halt the CPU
	cli
	hlt

;******************************************************************************
; Handle failures
;******************************************************************************
boot_failure:
	mov si, failure_msg
	call debug_print
	mov ah, 0		; Await a keyboard input
	int 0x16
	int 0x19		; Warm reboot

;******************************************************************************
; Global variables
;******************************************************************************

; BIOS gives us the boot drive number, make sure we keep it
boot_drive	db	0x00

; Absolute sector number on the actual disk
abs_sect	db	0x00

; Absolute head number on the actual disk
abs_head	db	0x00

; Absolute track number on the actual disk
abs_trak	db	0x00

; Start of data sector
data_sector	dw	0x0000

; Cluster number
cluster_num	dw	0x0000

; Progress bar message
progress_msg	db	"#", 0

; New line message
newline_msg	db	13, 10, 0

; Stage 2 bootloader name
boot2_name	db	"KERNLD  SYS"

;Welcome message of the operating system
welcome_msg	db	"Weclome to MiteOS", 13, 10, 0

; Failure message, wait for key press and reboot
failure_msg	db	"ERROR: Press a key to reboot.", 13, 10, 0

;******************************************************************************
; Pad with zeros
;******************************************************************************

; Fill the rest up to 512 bytes with zeros
times		(510 - ($ - $$)) db 0

; Magic Number
boot_magic:
	dw	0xaa55

; Floppy size is 1,474,560 bytes
; Now 1474560 - 512 = 1474048 bytes
times		1474048 db 0