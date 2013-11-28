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
0x80000041		0x08000001		0x00800001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0x90000041		0x09000001		0x00900001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xa0000041		0x0a000001		0x00a00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
0xb0000041		0x0b000001		0x00b00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]
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

NeoGeo emulator (alternative):

MMU table (IS+TIA+TIB+TIC+TID+PS = 0+4+4+4+5+15 = 32)

TIA				TIBs			TICs			TIDs

[TIB_0]			[TIC_0]			[PRG_ROM1+WP]	[WORK_RAM]		[PAL_RAM]		[BIOS+WP]		[BAK_RAM]		0x00c20001		0x00d30001
0x10000001		[TIC_1]			[TID_0]			[WORK_RAM+32k]	[INVALID]		[BIOS+WP+32k]	[BAK_RAM+32k]	0x00c28001		0x00d38001
0x20000001		0x02000001		[PRG_ROM2+WP]	[INVALID]		[INVALID]		[BIOS+WP+64k]	[INVALID]		0x00c30001		0x00d40001
0x30000001		0x03000001		[INVALID]		[INVALID]		[INVALID]		[BIOS+WP+96k]	[INVALID]		0x00c38001		0x00d48001
0x40000001		0x04000001		[TID_1]			[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c40001		0x00d50001
0x50000001		0x05000001		[EMU_RAM]		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c48001		0x00d58001
0x60000001		0x06000001		0x00600001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c50001		0x00d60001
0x70000001		0x07000001		0x00700001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c58001		0x00d68001
0x80000041		0x08000001		0x00800001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c60001		0x00d70001
0x90000041		0x09000001		0x00900001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c68001		0x00d78001
0xa0000041		0x0a000001		0x00a00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c70001		0x00d80001
0xb0000041		0x0b000001		0x00b00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c78001		0x00d88001
0xc0000041		0x0c000001		[TID_2]			[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c80001		0x00d90001
0xd0000041		0x0d000001		[TID_3]			[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c88001		0x00d98001
0xe0000041		0x0e000001		0x00e00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c90001		0x00da0001
[TIB_1]			0x0f000001		0x00f00041		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00c98001		0x00da8001
												[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00ca0001		0x00db0001
				0xf0000041		0x00700001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00ca8001		0x00db8001
				0xf1000041		0x00800001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cb0001		0x00dc0001
				0xf2000041		0x00900001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cb8001		0x00dc8001
				0xf3000041		0x00a00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cc0001		0x00dd0001
				0xf4000041		0x00b00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cc8001		0x00dd8001
				0xf5000041		[TID_4]			[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cd0001		0x00de0001
				0xf6000041		[TID_5]			[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cd8001		0x00de8001
				0xf7000041		0x01700001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00ce0001		0x00df0001
				0xf8000041		0x01800001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00ce8001		0x00df8001
				0xf9000041		0x01900001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cf0001		[INVALID]
				0xfa000041		0x01a00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00cf8001		[INVALID]
				0xfb000041		0x01b00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00d10001		[INVALID]
				0xfc000041		0x01c00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00d18001		[INVALID]
				0xfd000041		0x01d00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00d20001		[INVALID]
				0xfe000041		0x01e00001		[INVALID]		[INVALID]		[INVALID]		[INVALID]		0x00d28001		[INVALID]
				[TIC_0]			0x01f00001

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

.include "../defines.asm"

/*
.equ	PROGRAM_ROM_1_OFFSET,	0x00000000
.equ	PROGRAM_ROM_1_SIZE,		0x00100000
.equ	WORK_RAM_OFFSET,		PROGRAM_ROM_1_OFFSET+PROGRAM_ROM_1_SIZE
.equ	WORK_RAM_SIZE,			0x00008000
.equ	PROGRAM_ROM_2_OFFSET,	WORK_RAM_OFFSET+WORK_RAM_SIZE
.equ	PROGRAM_ROM_2_SIZE,		0x00100000
.equ	PALETTE_RAM_OFFSET,		PROGRAM_ROM_2_OFFSET+PROGRAM_ROM_2_SIZE
.equ	PALETTE_RAM_SIZE,		0x00008000
.equ	BIOS_ROM_OFFSET,		PALETTE_RAM_OFFSET+PALETTE_RAM_SIZE
.equ	BIOS_ROM_SIZE,			0x00020000
.equ	BACKUP_RAM_OFFSET,		BIOS_ROM_OFFSET+BIOS_ROM_SIZE
.equ	BACKUP_RAM_SIZE,		0x00010000
*/

.equ	PROGRAM_ROM_1_OFFSET,	0x00000000
.equ	PROGRAM_ROM_1_SIZE,		0x00100000
.equ	PROGRAM_ROM_2_OFFSET,	PROGRAM_ROM_1_OFFSET+PROGRAM_ROM_1_SIZE
.equ	PROGRAM_ROM_2_SIZE,		0x00100000
.equ	PALETTE_RAM_OFFSET,		PROGRAM_ROM_2_OFFSET+PROGRAM_ROM_2_SIZE
.equ	PALETTE_RAM_SIZE,		0x00008000
.equ	BIOS_ROM_OFFSET,		PALETTE_RAM_OFFSET+PALETTE_RAM_SIZE
.equ	BIOS_ROM_SIZE,			0x00020000
.equ	BACKUP_RAM_OFFSET,		BIOS_ROM_OFFSET+BIOS_ROM_SIZE
.equ	BACKUP_RAM_SIZE,		0x00010000
.equ	WORK_RAM_OFFSET,		BACKUP_RAM_OFFSET+BACKUP_RAM_SIZE
.equ	WORK_RAM_SIZE,			0x00008000

|-------------------------------------------------------------------------------

.text

|-------------------------------------------------------------------------------
|
|	Main program.
|
|-------------------------------------------------------------------------------

start:
	jbsr	load_tiles_usage_bitmap
	jbsr	compile_tiles
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

	jbsr	save_tiles_usage_bitmap

	Pterm0

|-------------------------------------------------------------------------------
|
|	Load ROM data.
|
|-------------------------------------------------------------------------------

load_roms:
	| Load the program ROM.

	Cconws	loading_program_rom_text

	Fopen	program_rom_file_name,#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_2_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_2_SIZE,(a0)

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_1_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_1_SIZE,(a0)

	Fclose	d7

	Cconws	reordering_program_rom_text

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_1_OFFSET,a0
	move.l	a0,a1
	add.l	#PROGRAM_ROM_1_SIZE,a1
1:
	move.b	(a0),d0
	move.b	1(a0),d1
	move.b	d1,(a0)+
	move.b	d0,(a0)+

	cmp.l	a1,a0
	jlt		1b

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_2_OFFSET,a0
	move.l	a0,a1
	add.l	#PROGRAM_ROM_2_SIZE,a1
1:
	move.b	(a0),d0
	move.b	1(a0),d1
	move.b	d1,(a0)+
	move.b	d0,(a0)+

	cmp.l	a1,a0
	jlt		1b

	| Load the BIOS ROM.

	Cconws	loading_bios_rom_text

	Fopen	bios_rom_file_name,#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#BIOS_ROM_OFFSET,a0
	Fread	d7,#BIOS_ROM_SIZE,(a0)

	Fclose	d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#BIOS_ROM_OFFSET,a0
	move.l	a0,a1
	add.l	#BIOS_ROM_SIZE,a1
1:
	move	(a0),d0
	ror		#8,d0
	move	d0,(a0)+

	cmp.l	a1,a0
	jlt		1b

	| Patch BIOS.

	move.l	neogeo_memory_pages_start,a0

	move.l	#BIOS_ROM_OFFSET+0x11c14,d0
	move.l	#0x4e714e71,(a0,d0.l)												| NOP out the calendar check.

	move.l	#BIOS_ROM_OFFSET+0x11c1c,d0
	move.l	#0x4e714e71,(a0,d0.l)												| NOP out the calendar check.

	move.l	#BIOS_ROM_OFFSET+0x11c62,d0
	move.l	#0x4e714e71,(a0,d0.l)												| NOP out the checksum result check.
	rts

program_rom_file_name:
	.asciz	"201-p1.p1"

bios_rom_file_name:
	.asciz	"sp-s2.sp1"

loading_program_rom_text:
	.asciz	"Loading program ROM...\r\n"

reordering_program_rom_text:
	.asciz	"Reordering program ROM...\r\n"

loading_bios_rom_text:
	.asciz	"Loading BIOS ROM...\r\n"

.even

|-------------------------------------------------------------------------------
|
|	Load tiles usage bitmap.
|
|-------------------------------------------------------------------------------

load_tiles_usage_bitmap:
	Cconws	loading_tiles_usage_bitmap_text

	Fopen	tiles_usage_bitmap_file_name,#0
	move	d0,d7
	jmi		1f

	Fread	d7,#0x10000,TILES_USAGE_BITMAP

	Fclose	d7

	rts
1:
	lea		TILES_USAGE_BITMAP,a0
	move.l	a0,a1
	add.l	#0x10000,a1
1:
	clr.l	(a0)+

	cmp.l	a1,a0
	jlt		1b

	rts

tiles_usage_bitmap_file_name:
	.asciz	"tilesbmp.dat"

loading_tiles_usage_bitmap_text:
	.asciz	"Loading tiles usage bitmap...\r\n"

.even

|-------------------------------------------------------------------------------
|
|	Save tiles usage bitmap.
|
|-------------------------------------------------------------------------------

save_tiles_usage_bitmap:
	Cconws	saving_tiles_usage_bitmap_text

	Fcreate	tiles_usage_bitmap_file_name,#0
	move	d0,d7

	Fwrite	d7,#0x10000,TILES_USAGE_BITMAP

	Fclose	d7

	rts

saving_tiles_usage_bitmap_text:
	.asciz	"Saving tiles usage bitmap...\r\n"

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

	move.l	d0,(a0)
	add.l	#16*4*4+0x2,(a0)+													| Reference to TIC 1.

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
	add.l	#16*4*3+0x02,(a0)+													| Reference to TIC 0 (again).

	| TIC 0.

	move.l	d1,(a0)
	add.l	#PROGRAM_ROM_1_OFFSET+0x05,(a0)+									| Program ROM 1.

	move.l	d0,(a0)
	add.l	#16*4*5+0x02,(a0)+													| Reference to TID 0.

	move.l	d1,(a0)
	add.l	#PROGRAM_ROM_2_OFFSET+0x05,(a0)+									| Program ROM 2.

	clr.l	(a0)+

	move.l	d0,(a0)
	add.l	#16*4*5+32*4+0x02,(a0)+												| Reference to TID 1.

	move.l	#0x00500000+0x01,(a0)+												| Emulator program(?).
	move.l	#0x00600000+0x01,(a0)+
	move.l	#0x00700000+0x01,(a0)+

	move.l	#0x00800000+0x01,(a0)+												| Memory card (disabled so space is free for sprites, etc.).
	move.l	#0x00900000+0x01,(a0)+
	move.l	#0x00a00000+0x01,(a0)+
	move.l	#0x00b00000+0x01,(a0)+

	move.l	d0,(a0)
	add.l	#16*4*5+32*4*2+0x02,(a0)+											| Reference to TID 2.

	move.l	d0,(a0)
	add.l	#16*4*5+32*4*3+0x02,(a0)+											| Reference to TID 3.

	move.l	#0x00e00000+0x01,(a0)+												| TOS.
	move.l	#0x00f00000+0x41,(a0)+												| Atari hardware registers.

	| TIC 1.

	move.l	#0x00700000+0x01,(a0)+
	move.l	#0x00800000+0x01,(a0)+
	move.l	#0x00900000+0x01,(a0)+
	move.l	#0x00a00000+0x01,(a0)+
	move.l	#0x00b00000+0x01,(a0)+

	move.l	d0,(a0)
	add.l	#16*4*5+32*4*4+0x02,(a0)+											| Reference to TID 4.

	move.l	d0,(a0)
	add.l	#16*4*5+32*4*5+0x02,(a0)+											| Reference to TID 5.

	move.l	#0x01700000+0x01,(a0)+
	move.l	#0x01800000+0x01,(a0)+
	move.l	#0x01900000+0x01,(a0)+
	move.l	#0x01a00000+0x01,(a0)+
	move.l	#0x01b00000+0x01,(a0)+
	move.l	#0x01c00000+0x01,(a0)+
	move.l	#0x01d00000+0x01,(a0)+
	move.l	#0x01e00000+0x01,(a0)+
	move.l	#0x01f00000+0x01,(a0)+

	| TID 0.

	move.l	d1,(a0)
	add.l	#WORK_RAM_OFFSET+0x01,(a0)+											| Work RAM.

	move.l	d1,(a0)
	add.l	#WORK_RAM_OFFSET+0x8000+0x01,(a0)+									| Work RAM + 32k.

.rept 32-2
	clr.l	(a0)+
.endr

	| TID 1.

	move.l	d1,(a0)
	add.l	#PALETTE_RAM_OFFSET+0x01,(a0)+										| Palette RAM.

.rept 32-1
	clr.l	(a0)+
.endr

	| TID 2.

	move.l	d1,(a0)
	add.l	#BIOS_ROM_OFFSET+0x05,(a0)+											| BIOS ROM.

	move.l	d1,(a0)
	add.l	#BIOS_ROM_OFFSET+0x8000+0x05,(a0)+									| BIOS ROM + 32k.

	move.l	d1,(a0)
	add.l	#BIOS_ROM_OFFSET+0x8000*2+0x05,(a0)+								| BIOS ROM + 64k.

	move.l	d1,(a0)
	add.l	#BIOS_ROM_OFFSET+0x8000*3+0x05,(a0)+								| BIOS ROM + 96k.

.rept 32-4
	clr.l	(a0)+
.endr

	| TID 3.

	move.l	d1,(a0)
	add.l	#BACKUP_RAM_OFFSET+0x01,(a0)+										| Backup RAM.

	move.l	d1,(a0)
	add.l	#BACKUP_RAM_OFFSET+0x8000+0x01,(a0)+								| Backup RAM + 32k.

.rept 32-2
	clr.l	(a0)+
.endr

	| TID 4.

	move.l	#0x00c20000+0x01,(a0)+
	move.l	#0x00c28000+0x01,(a0)+
	move.l	#0x00c30000+0x01,(a0)+
	move.l	#0x00c38000+0x01,(a0)+
	move.l	#0x00c40000+0x01,(a0)+
	move.l	#0x00c48000+0x01,(a0)+
	move.l	#0x00c50000+0x01,(a0)+
	move.l	#0x00c58000+0x01,(a0)+
	move.l	#0x00c60000+0x01,(a0)+
	move.l	#0x00c68000+0x01,(a0)+
	move.l	#0x00c70000+0x01,(a0)+
	move.l	#0x00c78000+0x01,(a0)+
	move.l	#0x00c80000+0x01,(a0)+
	move.l	#0x00c88000+0x01,(a0)+
	move.l	#0x00c90000+0x01,(a0)+
	move.l	#0x00c98000+0x01,(a0)+
	move.l	#0x00ca0000+0x01,(a0)+
	move.l	#0x00ca8000+0x01,(a0)+
	move.l	#0x00cb0000+0x01,(a0)+
	move.l	#0x00cb8000+0x01,(a0)+
	move.l	#0x00cc0000+0x01,(a0)+
	move.l	#0x00cc8000+0x01,(a0)+
	move.l	#0x00cd0000+0x01,(a0)+
	move.l	#0x00cd8000+0x01,(a0)+
	move.l	#0x00ce0000+0x01,(a0)+
	move.l	#0x00ce8000+0x01,(a0)+
	move.l	#0x00cf0000+0x01,(a0)+
	move.l	#0x00cf8000+0x01,(a0)+
	move.l	#0x00d10000+0x01,(a0)+
	move.l	#0x00d18000+0x01,(a0)+
	move.l	#0x00d20000+0x01,(a0)+
	move.l	#0x00d28000+0x01,(a0)+

	| TID 5.

	move.l	#0x00d30000+0x01,(a0)+
	move.l	#0x00d38000+0x01,(a0)+
	move.l	#0x00d40000+0x01,(a0)+
	move.l	#0x00d48000+0x01,(a0)+
	move.l	#0x00d50000+0x01,(a0)+
	move.l	#0x00d58000+0x01,(a0)+
	move.l	#0x00d60000+0x01,(a0)+
	move.l	#0x00d68000+0x01,(a0)+
	move.l	#0x00d70000+0x01,(a0)+
	move.l	#0x00d78000+0x01,(a0)+
	move.l	#0x00d80000+0x01,(a0)+
	move.l	#0x00d88000+0x01,(a0)+
	move.l	#0x00d90000+0x01,(a0)+
	move.l	#0x00d98000+0x01,(a0)+
	move.l	#0x00da0000+0x01,(a0)+
	move.l	#0x00da8000+0x01,(a0)+
	move.l	#0x00db0000+0x01,(a0)+
	move.l	#0x00db8000+0x01,(a0)+
	move.l	#0x00dc0000+0x01,(a0)+
	move.l	#0x00dc8000+0x01,(a0)+
	move.l	#0x00dd0000+0x01,(a0)+
	move.l	#0x00dd8000+0x01,(a0)+
	move.l	#0x00de0000+0x01,(a0)+
	move.l	#0x00de8000+0x01,(a0)+
	move.l	#0x00df0000+0x01,(a0)+
	move.l	#0x00df8000+0x01,(a0)+

.rept 32-26
	clr.l	(a0)+
.endr

	rts

|-------------------------------------------------------------------------------

.data

|-------------------------------------------------------------------------------

.bss

mmu_tables_start:
	ds.l	1

mmu_tables:
	ds.l	16+16*2+16*2+32*6
	ds.b	16																	| Padding (16 Bytes).

neogeo_memory_pages_start:
	ds.l	1

neogeo_memory_pages:
	ds.b	PROGRAM_ROM_1_SIZE+WORK_RAM_SIZE+PROGRAM_ROM_2_SIZE+PALETTE_RAM_SIZE+BIOS_ROM_SIZE+BACKUP_RAM_SIZE

	ds.b	0x00008000															| Padding (32 kiB).

.end
