#include "asm16.h"
#include "floppy16.h"

.section .text
.org 0
.code16

/******************************************************************************
 * BIOS Partition Block (Looks like opcode, but is not at all opcode)
 *****************************************************************************/
.globl start
start:
/* Three bytes of jump instruction, make a jump to the bootloader code */
    jmp boot_start

/* OEM Information */
.ascii FLOPPY_OEM_NAME

/* Number of bytes per sector */
.int FLOPPY_BYTES_PER_SECTOR

/* Number of sectors per cluster */
.byte FLOPPY_SECTS_PER_CLUST

/* Number of reserved sectors */
.int FLOPPY_RESERVED_SECTS

/* Number of FATs - File Allocation Tables */
.byte FLOPPY_NUM_FATS

/* Number of root entries */
.int FLOPPY_NUM_ROOT_ENTRIES

/* Total number of sectors */
.int FLOPPY_NUM_SECTORS

/* Media SPEC: single sided, 9 sector per FAT, 80 tracks, removable floppy */
.byte 0xF8

/* Number of sectors per FAT */
.int FLOPPY_SECTS_PER_FAT

/* Number of sectors per track */
.int FLOPPY_SECTS_PER_TRACK

/* Number of heads per cylinder */
.int FLOPPY_HEADS_PER_CYLNDR

/* Number of hidden sectors */
.long FLOPPY_HIDDEN_SECTORS

/* Number of total big sectors */
.long FLOPPY_NUM_BIG_SECTORS

/* Driver Number */
.byte FLOPPY_DRVNO

/* Unused */
.byte 0x00

/* Boot signature */
.byte FLOPPY_BOOT_SIGNATURE

/* Serial number for the floppy */
.long FLOPPY_SERIAL_NUMBER

/* Volume Label */
.ascii FLOPPY_VOLUME_LABEL

/* Filesystem name */
.ascii FLOPPY_FILESYSTEM

/******************************************************************************
 * BIOS Partition Block ends here...
 *****************************************************************************/

/******************************************************************************
 * Prints a NULL terminated string
 * @pre: DS should point to the correct data segment
 * @pre: SI should point to the correct offset address
 *****************************************************************************/
print16:
    pusha
.Lprint_next:
    lodsb                               /* Move byte from [DS:SI] into AL */
    cmpb $0, %al                        /* If NULL, we're done */
    jz .Lprint_done
    mov $BINT_VIDSERV_CMD_PUTCHAR, %ah  /* Print on TTY BIOS Video serv. cmd */
    int $BINT_VIDSERV                   /* Video service BIOS interrupt */
    jmp .Lprint_next                    /* Go and try to print more */
.Lprint_done:
    popa
    ret

/*
 * For more information on the organization of a floppy disk please visit
 * http://www.brokenthorn.com/Resources/images/cylinder.gif
 *
 * Each red circle in the figure above is a track (63 tracks on a floppy disk)
 * The red circles together form a cylinder
 * Each track is divided into sectors (18 sectors on a track)
 * Each sector is of 512 bytes
 * There are two heads on a floppy disk
 * In total, we have 2880 sectors on a floppy disk
 */

/******************************************************************************
* NAME: read_sectors16
*
* PURPOSE: Read sectors from a floppy drive in real mode
*
* @pre:  AH is reserved for function number for interrupts
* @pre:  AL contains the number of sectors to be read
* @pre:  BX contains offset part of the address to read into
* @pre:  CH contains the track/cylinder number
* @pre:  CL contains the sector number in that track
* @pre:  DH contains the head number
* @pre:  DL contains the drive number of the floppy drive
* @pre:  ES contains the segment part of the address to read into
*
* @post: AL number of sectors are read at address specified by ES:BX
* @post: All registers are intact
******************************************************************************/
/* .globl read_sectors16 */
read_sector16:
        pusha
/* Reset the floppy drive */
.reset:
        movb $BINT_DISKSERV_CMD_RESET, %ah  /* Load command */
        int $BINT_DISKSERV                  /* Invoke interrupt */
        jc .reset

        xor %si, %si                        /* Initialize loop variable %SI  */
/* Read the sectors into disk: %SI (# retries) < FLOPPY_RETRIES */
.read:
        movb $BINT_DISKSERV_CMD_READ, %ah   /* Load command */
        int $BINT_DISKSERV                  /* Invoke interrupt */
        jnc .done                           /* If carry not set, no error */
        inc %si                             /* Increment retries count */
        cmpw $FLOPPY_RETRIES, %si
        jl .read                            /* try again? */
/* Error condition */
        int $BINT_NOROMBASIC          /* Show 'No ROM BASIC' and halt */
/* Success condition */
.done:
        popa
        ret

/******************************************************************************
 * NAME: lba_to_chs
 *
 * PURPOSE Convert LBA (logical sector) to CHS
 *
 * Cylinder number = logical sector / sectors per track / number of heads
 * Head Number = logical sector / sectors per track % number of heads
 * Sector Number = logical sector % sectors per track + 1
 *
 * Abbr: SPT (Sectors per track)
 *       LBA (logical block address)
 *       HPC (heads per cylinder)
 *
 * @pre:  AX should contain the logical sector (LBA)
 * @post: CH will contain the cylinder number
 * @post: DH will contain the head number
 * @post: CL will contain the sector number inside that track
 *
 *****************************************************************************/
/* .globl lba_to_chs16 */
 lba_to_chs16:
         xorw %dx, %dx
         divw (FLOPPY_SECTS_PER_TRACK)  /* DX = LBA % SPT, AX = LBA / SPT */

         movb %dl, %cl
         inc %cl                         /* CL now has sector number */
         xorw %dx, %dx
         divw (FLOPPY_HEADS_PER_CYLNDR) /* DX = LBA / SPT % HPC,
                                            AX = LBA /SPT / HPC */

         movb %al, %ch                   /* CH now has cylinder number */
         movb %dl, %dh                   /* DH now has the head number */
         ret

/******************************************************************************
 * NAME: chs_to_lba
 *
 * PURPOSE: Convert CHS notation to LBA
 *****************************************************************************/

/******************************************************************************
 * BOOT LOADER ENTRY POINT
 *****************************************************************************/
boot_start:
/* Disable interrupts */
    cli

/* Setup segments DS, ES, FS & GS = 0x7c00:0x0000, SS = 0x0000:0xFFFF */
    movw $0x7c0, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    xorw %ax, %ax
    movw %ax, %ss
    movw $0xFFFF, %sp

/* Save the boot drive number onto its memory location */
    movb %dl, (BOOT_DRIVE)

/* Enable interrupts again */
    sti

/* Print a welcome message */
    mov %si, WELCOME_MSG
    call print16

/******************************************************************************
 * GLOBAL VARIABLES (DATA SECTION inside CODE)
 *****************************************************************************/
BOOT_DRIVE:
    .byte 0x00

WELCOME_MSG:
    .ascii "Welcome to MiteOS"
    .byte 13, 10, 0

FAILURE_MSG:
    .ascii "ERROR"
