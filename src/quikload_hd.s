//-----------------------------------------------------------------
//	quikload.s
//
//	This is a 'quick-and-dirty' boot-loader that you can use
//	(or modify) for CS630's in-class exercises in Fall 2006.
//
//	 to assemble: $ as quikload.s -o quikload.o
//	 and to link: $ ld quikload.o -T ldscript -o quikload.b
//	 and install: $ dd if=quikload.b of=/dev/sda4
//
//	NOTE: This code begins execution with CS:IP = 0000:7C00.
//
//	programmer: ALLAN CRUSE
//	written on: 12 SEP 2006
//-----------------------------------------------------------------

	.global main
	.code16
	.text
#------------------------------------------------------------------
main:
	# clear the screen
	#mov $0xA000, %ax
	mov $0xB800, %ax
	mov %ax, %es
	xor %di, %di
	xor %ax, %ax
	#mov $32000, %cx
	mov $2000, %cx
	cld
	rep stosw


	# setup segment-registers to address our program data
	mov	%cs, %ax
	mov	%ax, %ds
	mov	%ax, %es

	# transfer sectors from disk to memory
	mov     $LOAD_ADDR, %ax
	mov     %ax, %es
        mov     $0, %bx                 # address = 0x10000

	mov     $0x0080, %dx            # drive hd0, head 0
        mov     $0x0002, %cx            # sector 2, track 0
        .equ    AX, 0x0200+SYS_SIZE
        mov     $AX, %ax                # service 2, nr of sectors
        int     $0x13

	# verify that our program's signature-word is present
        mov     $0, %bx                 # address = 0x10000
	cmpw	$0xABCD, %es:0
	jne	err

	# transfer control to our program's entry-point
	lcall	$LOAD_ADDR, $0x0002

fin:	# await keypress, then reboot
	mov	$0x00, %ah
	int	$0x16
	int	$0x19

err:	# TODO: We ought to display an error-message here
	#jmp	fin
	lcall	$LOAD_ADDR, $0x0000

	.org	510
	.byte	0x55, 0xAA
	.end
