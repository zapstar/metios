#ifndef _BOOT_FLOPPY16_H_
#define _BOOT_FLOPPY16_H_

/* Bootable floppy's OEM name - OS name (8 bytes) */
#define FLOPPY_OEM_NAME             "MITEOS  "

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

/* Number of hidden sectors */
#define FLOPPY_HIDDEN_SECTORS       0

/* Total number of big sectors */
#define FLOPPY_NUM_BIG_SECTORS      0

/* Floppy drive number (used by BIOS interrupt to communicate) */
#define FLOPPY_DRVNO                0

/* Boot signature of the floppy drive */
#define FLOPPY_BOOT_SIGNATURE       0x29

/* Serial number of the floppy driver */
#define FLOPPY_SERIAL_NUMBER        0xA0A1A2A3

/* Volume Label of the floppy driver (11 bytes) */
#define FLOPPY_VOLUME_LABEL         "MITEOS FLOP"

/* File system of this particular floppy (8 bytes) */
#define FLOPPY_FILESYSTEM           "FAT12   "

/* Number of retries for a floppy read sector */
#define FLOPPY_RETRIES              5

#endif /* _BOOT_FLOPPY16_H_ */