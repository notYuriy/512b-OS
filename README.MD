Operating system, which kernel is implemented using 512b of code (of course .vfd is greater than 512b because it is 1.44MB and have some space to install applications there)

Implemented:
* searching all files on FAT12 disk
* loading COM executables
** maximum size - 65536 bytes
** loaded at 0x1000:0x0000
** SS, CS, DS, ES points to 0x1000
** SP points to 0xffff
** int 21h to terminate program
