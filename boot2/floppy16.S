#include <asm.h>

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
 *
 */

/******************************************************************************
* NAME: read_sectors16
*
* PURPOSE: Read sectors from a floppy drive in real mode
*
* @pre: AH is reserved for function number for interrupts
* @pre: AL contains the number of sectors to be read
* @pre: BX contains offset part of the address to read into
* @pre: CH contains the track/cylinder number
* @pre: CL contains the sector number in that track
* @pre: DH contains the head number
* @pre: DL contains the drive number of the floppy drive
* @pre: ES contains the segment part of the address to read into
*
* @post: AL number of sectors are read at address specified by ES: BX
* @post: All registers are intact
*******************************************************************************/
.code16
.global read_sectors16
read_sector16:
	pusha				/* Save registers */
/* Reset the floppy drive */
.reset:
	movb $FLOPPY_CMD_DRV_RESET, %ah	/* Reset floppy disk function */
	int $BIOS_INTERRUPT		/* Invoke BIOS interrupt */
	jc .reset
/* Read the sectors into disk */
	xor %si, %si 			/* %SI (# retries) < FLOPPY_RETRIES */
.read:
	movb $FLOPPY_CMD_DRV_READ, %ah	/* Floppy drive read sectors function */
	int $BIOS_INTERRUPT		/* Invoke BIOS interrupt */
	jnc .done			/* If carry not set, then no error */
	inc %si				/* Increment retries count */
	cmpw $FLOPPY_RETRIES, %si
	jl .read			/* If SI < FLOPPY_RETRIES, read again */
/* Error condition */

/* Success condition */
.done:
	popa				/* Restore registers */
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
 * Abbr: SPT (Sectors per track), LBA (logical block address)
 * HPC (heads per cylinder)
 *
 * @pre: AX should contain the logical sector (LBA)
 * @post: CH will contain the cylinder number
 * @post: DH will contain the head number
 * @post: CL will contain the sector number inside that track
 *
 ******************************************************************************/
 lba_to_chs:
 	xorw %dx, %dx
 	divw $FLOPPY_SECTS_PER_TRACK	/* DX = LBA % SPT
 					 * AX = LBA / SPT
 					 */
 	movb %dl, %cl
 	inc %cl				/* CL now has sector number */
 	xorw %dx, %dx
 	divw $FLOPPY_HEADS_PER_CYLNDR	/* DX = LBA / SPT % HPC
 					 * AX = LBA /SPT / HPC
 	 				 */
 	movb %al, %ch 			/* CH now has cylinder number */
 	movb %dl, %dh			/* DH now has the head number */
 	ret

/******************************************************************************
 * NAME: chs_to_lba
 *
 * PURPOSE: Convert CHS notation to LBA

 */
