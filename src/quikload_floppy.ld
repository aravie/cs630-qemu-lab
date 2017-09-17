/*                                       */
/* 'ldscript' --- A simple Linker Script */
/* for use with the GNU linker 'ld' when */
/* producing a elf-format executable. */
/*                                       */
/* usage:                                */
/*   $ gcc -c main.cpp			 */
/*   $ ld main.o -T ldscript -o main.elf */

/* programmer: ALLAN CRUSE */
/* written on: 02 MAY 2004 */
/* revised on: 24 MAY 2004 */

OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386");

SECTIONS
{
	. = 0x00007C00;
	.text :	{ *(.text) }
	.data : { *(.data) }
	.bss  : { *(.bss)  }
}
