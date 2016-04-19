#ifndef _BOOT_ASM_H_
#define _BOOT_ASM_H_

/* BIOS Interrupt number */
#define BIOS_INTERRUPT              0x13

/* Floppy drive number (used by BIOS interrupt to communicate) */
#define FLOPPY_DRVNO                0

/* Floppy disk command function to reset it (populated into AH) */
#define FLOPPY_CMD_DRV_RESET        0

/* Floppy disk command function to read it (populated in AH) */
#define FLOPPY_CMD_DRV_READ         2

/* Number of retries for a floppy read sector */
#define FLOPPY_RETRIES              5

/* Total number of bytes per sector */
#define FLOPPY_BYTES_PER_SECTOR     512

/* Number of sectors per cluster */
#define FLOPPY_SECTS_PER_CLUST      1

/* Number of reserved sectors */
#define FLOPPY_RESERVED_SECTS       1

/* Number of FATs on the floppy disk */
#define FLOPPY_NUM_FATS             2

/* Number of root entries on the disk */
#define FLOPPY_NUM_ROOT_ENTRIES     224

/* Total number of sectors (each of 512 byte in size) */
#define FLOPPY_NUM_SECTORS          2880

/* Number of sectors per FAT */
#define FLOPPY_SECTS_PER_FAT        9

/* Number of sectors per track */
#define FLOPPY_SECTS_PER_TRACK      18

/* Number of heads per cylinder */
#define FLOPPY_HEADS_PER_CYLNDR     2

#endif /* _BOOT_ASM_H_ */