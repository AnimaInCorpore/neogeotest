.global start

.include "../gemdos.asm"

|-------------------------------------------------------------------------------

.text

|-------------------------------------------------------------------------------
|
|	Main program.
|
|-------------------------------------------------------------------------------

start:
	Cconws	emulator_text

	move.l	4(sp),a0
	lea		0x81(a0),a0
	jbsr	select_game

	jbsr	load_tiles_usage_bitmap
	jbsr	compile_tiles
	jbsr	build_mmu_tables
	jbsr	load_roms

	jbsr	f030_init

	| Copy emulator program to 0x500000.

	move.l	game_info_pointer,a0												| Fixme: awkward way to prevent the tile index overflow.
	move.l	6*4(a0),d0
	lsr.l	#4+3-2,d0

	moveq.l	#1,d1
1:
	cmp.l	d0,d1
	jge		1f

	add.l	d1,d1
	jra		1b
1:
	subq.l	#1,d1
	move.l	d1,tiles_index_mask

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

.data

emulator_text:
	.ascii	"Neo Geo Emulator for the Atari Falcon.\r\n"
	.ascii	"Programmed by Sascha Springer.\r\n"
	.ascii	"Pre-Alpha Version 20131215.\r\n"
	.ascii	"Greetings to all Atari fans.\r\n"
	.asciz	"\r\n"

|-------------------------------------------------------------------------------

.bss

.end
