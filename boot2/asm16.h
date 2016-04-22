#ifndef _BOOT_ASM16_H_
#define _BOOT_ASM16_H_

/**
 * Reference: https://en.wikipedia.org/wiki/BIOS_interrupt_call
 */

/* Video Services */
#define BINT_VIDSERV                0x10
#define BINT_VIDSERV_CMD_PUTCHAR    0x0E

/* Low level disk services */
#define BINT_DISKSERV               0x13
#define BINT_DISKSERV_CMD_RESET     0x00
#define BINT_DISKSERV_CMD_READ      0x02

/* No ROM BASIC and halt */
#define BINT_NOROMBASIC             0x18

#endif /* _BOOT_ASM16_H_ */