Operating system, which kernel is implemented using 512b of code (of course .vfd is greater than 512b because it is 1.44MB and have some space to install applications there)

Implemented:
* user interface
  * clear screen and shows current picked file
  * up and down arrow keys to select file
  * enter to start file
* searching all files on FAT12 disk
* loading COM executables
  * maximum size - 65536 bytes (it is checked)
  * loaded at 0x1000:0x0000
  * SS, CS, DS, ES points to 0x1000
  * SP points to 0xffff
  * int 21h to terminate program

Unimplemented:
* error messages
* memory protection
* file io system api
* launching more than one app api
