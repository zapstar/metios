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
bios_print_msg:
	pusha
.read_next:
	lodsb		; Picks a fresh byte from SI into AL
	cmp al, 0	; See if we have reached the end of the string
	jz .debug_done	; If so, prepare to exit the routine
	mov ah, 0x0e	; Print on TTY
	int 0x10	; Make the INT call
	jmp .read_next	; Get ready to print more
.debug_done:
	popa
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
	pusha
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
	call bios_print_msg
	popa
	add bx, word [bpb_bytespersector]	; Next address to load
	inc ax					; Next sector
	loop .main
	ret

;******************************************************************************
; Routine to convert from CHS to LBA
; @post: AX will have the LBA
; LBA = (cluster - 2) * sectors per cluster
;******************************************************************************
cluster_to_lba:
	sub ax, 2				; For formula above
	xor cx, cx
	mov cl, byte [bpb_sectorspercluster]	; For multiplication
	mul cx
	add ax, word [data_sector]		; Base data sector correction
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
	mov sp, 0xffff	; Our stack pointer at 0xFFFF (0x00007E00 - 0x0009FFFF)

; Save boot drive information for later (Given to us by BIOS)
	mov [boot_drive], dl

; Enable interrupts again
	sti

; Print our message
	mov si, welcome_msg
	call bios_print_msg

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
; This is useful in converting CHS to LBA
	mov word [data_sector], ax
	add word [data_sector], cx
	mov bx, [boot_mem_end]	; Copy the root directory at 0x07c0:0x0200
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

; Now DI will have address of the root directory entry for second stage
; bootloader. Save that in variable current_cluster
	mov dx, word [di + 26]
	mov word [current_cluster], dx

; Print new line indicating that root directory has been loaded successfully
	mov si, newline_msg
	call bios_print_msg

;******************************************************************************
; Code to load FAT into memory (0x07c0:0x0200)
; We don't need the root directory any more as we already have
; the second stage bootloader
;******************************************************************************
; First compute the size of FAT and store it in CX
	xor ax, ax
	mov al, [bpb_numberoffats]
	mul word [bpb_sectorsperfat]
	mov cx, ax
; Now compute location of FAT and store it in AX
	mov ax, word [bpb_reservedsectors]
; Read the FAT into memory
	mov bx, word [boot_mem_end]
	call read_sectors

; Print new line indicating that FAT has been loaded successfully
	mov si, newline_msg
	call bios_print_msg

;******************************************************************************
; Load the stage 2 bootloader at address (0x2000:0x0000 = 0x20000)
;******************************************************************************
; The address where the second stage bootloader at ES:BX
	mov ax, word [boot2_high_add]
	mov es, ax
	mov bx, word [boot2_low_add]
	push bx
load_image:
	mov ax, word [current_cluster]		; Cluster to be read
	pop bx
	call cluster_to_lba
	xor cx, cx
	mov cl, byte [bpb_sectorspercluster]	; Number of clusters
	call read_sectors
	push bx
; Compute the next cluster
	mov ax, word [current_cluster]		; Copy of current_cluster
	mov cx, ax				; Copy of current_cluster
	mov dx, ax				; Copy of current_cluster
	shr dx, 1
	add cx, dx				;CX = 1.5 * current_cluster
	mov bx, [boot_mem_end]			; ES:BX has FAT in memory
; Store address of the index of FAT for current cluster in BX
	add bx, cx
	mov dx, word [bx]			; Read next cluster into DX
; See if we were dealing with even or odd current cluster
	test ax, 1
	jnz .odd_cluster
.even_cluster:
; Select the lower twelve bits
	and dx, 0000111111111111b
	jmp .move_past_odd
.odd_cluster:
; Select the higher twelve bits
	shr dx, 4
.move_past_odd:
; store the new cluster as the current cluster
	mov word [current_cluster], dx
; End of file will have cluster number as 0x0ff0
	cmp dx, 0x0ff0
	jb load_image

; Print new line indicating the end of second stage bootloader image load
	mov si, newline_msg
	call bios_print_msg

;******************************************************************************
; Make a far jump and start running the second stage boot loader
;******************************************************************************
	mov ax, word [boot2_high_add]
	push ax
	mov ax, word [boot2_low_add]
	push ax
	retf
;******************************************************************************
; SHOULD NOT COME HERE
;******************************************************************************

;******************************************************************************
; Handle failures
;******************************************************************************
boot_failure:
	mov si, failure_msg
	call bios_print_msg
	mov ah, 0		; Await a keyboard input
	int 0x16
	int 0x19		; Warm reboot

;******************************************************************************
; Global variables (DATA SECTION)
;******************************************************************************

; BIOS gives us the boot drive number, make sure we keep it
boot_drive	db	0x00

; Absolute sector number on the actual disk
abs_sect	db	0x00

; Absolute head number on the actual disk
abs_head	db	0x00

; Absolute track number on the actual disk
abs_trak	db	0x00

;******************************************************************************
; This memory is used to store the root directory temporarily and holds
; a copy of the both the FATs in the memory which is used to fetch the
; image of the second stage bootloader
;******************************************************************************
; Boot sector end (ES: 0x07c00, then we'll be + 512)
boot_mem_end	dw	0x0200

; Start of data sector
data_sector	dw	0x0000

; Current cluster. Will initially point to the first cluster of the
; second stage bootloader
current_cluster	dw	0x0000

;******************************************************************************
; NOTE: Currently we're planning to put the second stage bootloader at 0x20000
; This puts a limitation on the size of the second stage bootloader
; Video memory starts at 0xA0000 and for this reason our second stage
; bootloader cannot exceed 524288 bytes in size (exactly 512KB)
;******************************************************************************
; Second stage bootloader image's desired higher address
boot2_high_add	dw	0x2000

; Second stage bootloader image's desired lower address
boot2_low_add	dw	0x0000

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
; Pad with zeros and the magic number
; We barely made it with 12 bytes remaining to hit the 510 byte mark!
;******************************************************************************

; Fill the rest up to 512 bytes with zeros
times	(510 - ($ - $$))	db	0

; Magic Number
boot_magic:
	dw	0xaa55

; Floppy size is 1,474,560 bytes
times	(1474560 - ($ - $$))	db	0

