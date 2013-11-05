/*

Address ranges for the MMU	Description								Page size

0x00000000 - 0x000fffff		Program ROM 1							0x00100000 (  1 MiB)
0x00100000 - 0x0010ffff		Work RAM								0x00010000 ( 64 kiB)
0x00200000 - 0x002fffff		Program ROM 2							0x00100000 (  1 MiB)
0x00300000 - 0x003fffff		I/O, system, video registers			Invalid
0x00400000 - 0x00401fff		Palettes RAM							0x00008000 ( 32 kiB)
0x00800000 - 0x00bfffff		Memory card								Invalid
0x00c00000 - 0x00c1ffff		BIOS ROM								0x00020000 (128 kiB)
0x00d00000 - 0x00d0ffff		Backup RAM								0x00010000 ( 64 kiB)

0x01000000 - 0x013fffff		Tiles ROM 1								0x00400000 (  4 MiB)

0x00500000 - 0x005fffff		Emulator program						0x00100000 (  1 MiB)

NeoGeo emulator:

MMU table (IS+TIA+TIB+TIC+TID+PS = 0+4+4+4+5+15 = 32)

TIA				TIBs			TICs			TIDs

[TIB_0]			[TIC_0]			[PRG_ROM1+WP]	[WORK_RAM]		[PAL_RAM]		[BIOS+WP]		[BAK_RAM]
0x10000001		0x01000001		[TID_0]			[WORK_RAM+32k]	[INVALID]		[BIOS+WP+32k]	[BAK_RAM+32k]
0x20000001		0x02000001		[PRG_ROM2+WP]	[INVALID]		[INVALID]		[BIOS+WP+64k]	[INVALID]
0x30000001		0x03000001		[INVALID]		[INVALID]		[INVALID]		[BIOS+WP+96k]	[INVALID]
0x40000001		0x04000001		[TID_1]			[INVALID]		[INVALID]		[INVALID]		[INVALID]
0x50000001		0x05000001		[EMU_RAM]		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0x60000001		0x06000001		0x00600001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0x70000001		0x07000001		0x00700001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0x80000041		0x08000001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0x90000041		0x09000001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xa0000041		0x0a000001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xb0000041		0x0b000001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xc0000041		0x0c000001		[TID_2]			[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xd0000041		0x0d000001		[TID_3]			[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xe0000041		0x0e000001		0x00e00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
[TIB_1]			0x0f000001		0x00f00041		[INVALID]		[INVALID]		[INVALID]		[INVALID]
												[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf0000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf1000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf2000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf3000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf4000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf5000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf6000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf7000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf8000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xf9000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xfa000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xfb000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xfc000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xfd000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				0xfe000041						[INVALID]		[INVALID]		[INVALID]		[INVALID]
				[TIC_0]

Atari Falcon original:

MMU table (IS+TIA+TIB+TIC+TID+PS = 0+4+4+4+5+15 = 32)

TIA			TIBs		TIC

[TIB_0000]	[TIC_0000]	0x00000001
0x10000001	0x01000001	0x00100001
0x20000001	0x02000001	0x00200001
0x30000001	0x03000001	0x00300001
0x40000001	0x04000001	0x00400001
0x50000001	0x05000001	0x00500001
0x60000001	0x06000001	0x00600001
0x70000001	0x07000001	0x00700001
0x80000041	0x08000001	0x00800001
0x90000041	0x09000001	0x00900001
0xa0000041	0x0a000001	0x00a00001
0xb0000041	0x0b000001	0x00b00001
0xc0000041	0x0c000001	0x00c00001
0xd0000041	0x0d000001	0x00d00001
0xe0000041	0x0e000001	0x00e00001
[TIB_0001]	0x0f000001	0x00f00041

			0xf0000041
			0xf1000041
			0xf2000041
			0xf3000041
			0xf4000041
			0xf5000041
			0xf6000041
			0xf7000041
			0xf8000041
			0xf9000041
			0xfa000041
			0xfb000041
			0xfc000041
			0xfd000041
			0xfe000041
			[TIC_0000]

*/

.global start

.include "../bios.asm"
.include "../xbios.asm"
.include "../gemdos.asm"

|-------------------------------------------------------------------------------

.text

|-------------------------------------------------------------------------------
|
|	Main program.
|
|-------------------------------------------------------------------------------

start:
	jbsr	build_mmu_tables
	jbsr	load_roms

	jbsr	f030_init

	| Copy emulator program to 0x500000.

	lea		emulator,a0
	lea		0x500000,a1
1:
	move.l	(a0)+,(a1)+
	cmp.l	#emulator_end,a0
	jlt		1b

	| Start emulation.

	move.l	mmu_tables_start,d0
	move.l	neogeo_memory_pages_start,a0
	jsr		0x500000

	jbsr	f030_deinit

	Pterm0

|-------------------------------------------------------------------------------
|
|	Load ROM data.
|
|-------------------------------------------------------------------------------

load_roms:
	| Load the program ROM.

	Fopen	program_rom_file_name,#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#0x100000+0x8000,a0
	Fread	d7,#0x100000,(a0)

	move.l	neogeo_memory_pages_start,a0
	Fread	d7,#0x100000,(a0)

	Fclose	d7

	move.l	neogeo_memory_pages_start,a0
	move.l	a0,a1
	add.l	#0x100000,a1
1:
	move	(a0),d0
	ror		#8,d0
	move	d0,(a0)+

	cmp.l	a1,a0
	jlt		1b

	move.l	neogeo_memory_pages_start,a0
	add.l	#0x100000+0x8000,a0
	move.l	a0,a1
	add.l	#0x100000,a1
1:
	move	(a0),d0
	ror		#8,d0
	move	d0,(a0)+

	cmp.l	a1,a0
	jlt		1b

	| Load the BIOS ROM.

	Fopen	bios_rom_file_name,#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#0x100000+0x8000+0x100000+0x8000,a0
	Fread	d7,#0x20000,(a0)

	Fclose	d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#0x100000+0x8000+0x100000+0x8000,a0
	move.l	a0,a1
	add.l	#0x20000,a1
1:
	move	(a0),d0
	ror		#8,d0
	move	d0,(a0)+

	cmp.l	a1,a0
	jlt		1b

	rts

program_rom_file_name:
	.asciz	"201-p1.p1"

.even

bios_rom_file_name:
|	.asciz	"sp-e.sp1"
	.asciz	"sp-j2.sp1"

.even

|-------------------------------------------------------------------------------
|
|	Build NeoGeo MMU tables.
|
|-------------------------------------------------------------------------------

build_mmu_tables:
	move.l	#neogeo_memory_pages,d0
	add.l	#0x8000-1,d0
	and.l	#0xffff8000,d0
	move.l	d0,neogeo_memory_pages_start

	move.l	#mmu_tables,d0
	add.l	#0x10-1,d0
	and.l	#0xfffffff0,d0
	move.l	d0,mmu_tables_start

	move.l	mmu_tables_start,a0
	move.l	a0,d0
	move.l	neogeo_memory_pages_start,d1

	| TIA.

	move.l	d0,(a0)
	add.l	#16*4+0x2,(a0)+														| Reference to TIB 0.

	move.l	#0x10000000+0x01,(a0)+
	move.l	#0x20000000+0x01,(a0)+
	move.l	#0x30000000+0x01,(a0)+
	move.l	#0x40000000+0x01,(a0)+
	move.l	#0x50000000+0x01,(a0)+
	move.l	#0x60000000+0x01,(a0)+
	move.l	#0x70000000+0x01,(a0)+
	move.l	#0x80000000+0x41,(a0)+
	move.l	#0x90000000+0x41,(a0)+
	move.l	#0xa0000000+0x41,(a0)+
	move.l	#0xb0000000+0x41,(a0)+
	move.l	#0xc0000000+0x41,(a0)+
	move.l	#0xd0000000+0x41,(a0)+
	move.l	#0xe0000000+0x41,(a0)+

	move.l	d0,(a0)
	add.l	#16*4*2+0x2,(a0)+													| Reference to TIB 1.

	| TIB 0.

	move.l	d0,(a0)
	add.l	#16*4*3+0x2,(a0)+													| Reference to TIC 0.

	move.l	#0x01000000+0x01,(a0)+
	move.l	#0x02000000+0x01,(a0)+
	move.l	#0x03000000+0x01,(a0)+
	move.l	#0x04000000+0x01,(a0)+
	move.l	#0x05000000+0x01,(a0)+
	move.l	#0x06000000+0x01,(a0)+
	move.l	#0x07000000+0x01,(a0)+
	move.l	#0x08000000+0x01,(a0)+
	move.l	#0x09000000+0x01,(a0)+
	move.l	#0x0a000000+0x01,(a0)+
	move.l	#0x0b000000+0x01,(a0)+
	move.l	#0x0c000000+0x01,(a0)+
	move.l	#0x0d000000+0x01,(a0)+
	move.l	#0x0e000000+0x01,(a0)+
	move.l	#0x0f000000+0x01,(a0)+

	| TIB 1.

	move.l	#0xf0000000+0x41,(a0)+
	move.l	#0xf1000000+0x41,(a0)+
	move.l	#0xf2000000+0x41,(a0)+
	move.l	#0xf3000000+0x41,(a0)+
	move.l	#0xf4000000+0x41,(a0)+
	move.l	#0xf5000000+0x41,(a0)+
	move.l	#0xf6000000+0x41,(a0)+
	move.l	#0xf7000000+0x41,(a0)+
	move.l	#0xf8000000+0x41,(a0)+
	move.l	#0xf9000000+0x41,(a0)+
	move.l	#0xfa000000+0x41,(a0)+
	move.l	#0xfb000000+0x41,(a0)+
	move.l	#0xfc000000+0x41,(a0)+
	move.l	#0xfd000000+0x41,(a0)+
	move.l	#0xfe000000+0x41,(a0)+

	move.l	d0,(a0)
	add.l	#16*4*3+0x2,(a0)+													| Reference to TIC 0 (again).

	| TIC 0.

	move.l	d1,(a0)
	add.l	#0x5,(a0)+															| Program ROM 1.

	move.l	d0,(a0)
	add.l	#16*4*4+0x2,(a0)+													| Reference to TID 0.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x5,(a0)+											| Program ROM 2.

	clr.l	(a0)+

	move.l	d0,(a0)
	add.l	#16*4*4+32*4+0x2,(a0)+												| Reference to TID 1.

	move.l	#0x00500000+0x01,(a0)+												| Emulator program(?).
	move.l	#0x00600000+0x01,(a0)+
	move.l	#0x00700000+0x01,(a0)+

	clr.l	(a0)+																| Memory card (invalid).
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+

	move.l	d0,(a0)
	add.l	#16*4*4+32*4*2+0x2,(a0)+											| Reference to TID 2.

	move.l	d0,(a0)
	add.l	#16*4*4+32*4*3+0x2,(a0)+											| Reference to TID 3.

	move.l	#0x00e00000+0x01,(a0)+												| TOS.
	move.l	#0x00f00000+0x41,(a0)+												| Atari hardware registers.

	| TID 0.

	move.l	d1,(a0)
	add.l	#0x100000+0x1,(a0)+													| Work RAM.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x1,(a0)+											| Work RAM.

.rept 32-2
	clr.l	(a0)+
.endr

	| TID 1.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x1,(a0)+									| Palette RAM.

.rept 32-1
	clr.l	(a0)+
.endr

	| TID 2.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x8000+0x5,(a0)+							| BIOS ROM.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x8000+0x8000+0x5,(a0)+					| BIOS ROM.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x8000+0x8000*2+0x5,(a0)+					| BIOS ROM.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x8000+0x8000*3+0x5,(a0)+					| BIOS ROM.

.rept 32-4
	clr.l	(a0)+
.endr

	| TID 3.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x20000+0x1,(a0)+							| Backup RAM.

	move.l	d1,(a0)
	add.l	#0x100000+0x8000+0x100000+0x20000+0x8000+0x1,(a0)+	| Backup RAM.

.rept 32-2
	clr.l	(a0)+
.endr

	rts

|-------------------------------------------------------------------------------

.data

message_text:
	.asciz "Yes!"

|-------------------------------------------------------------------------------

.bss

mmu_tables_start:
	ds.l	1

mmu_tables:
	ds.l	16+16*2+16+32*4
	ds.b	16																	| Padding bytes (16 B).

neogeo_memory_pages_start:
	ds.l	1

neogeo_memory_pages:
	ds.b	0x00100000															| Program ROM 1 (1 MiB).
	ds.b	0x00008000															| Work RAM (32 kiB).
	ds.b	0x00100000															| Program ROM 2 (1 MiB).
	ds.b	0x00008000															| Palette RAM (32 kiB).
	ds.b	0x00020000															| BIOS ROM (128 kiB).
	ds.b	0x00010000															| Backup RAM (64 kiB).

	ds.b	0x00008000															| Padding bytes (32 kiB).

	ds.l	2000
my_stack:

.end
