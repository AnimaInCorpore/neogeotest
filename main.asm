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
	Cconws	loading_game_text_1

	move.l	game_info_pointer,a0
	move.l	(a0),a0
	Cconws	(a0)

	Cconws	loading_game_text_2

	jbsr	load_tiles_usage_bitmap
	jbsr	compile_tiles
	jbsr	build_mmu_tables
	jbsr	load_roms

	jbsr	f030_init

	| Copy emulator program to 0x500000.

	move.l	game_info_pointer,a0												| Fixme: awkward way to prevent the tile index overflow.
	move.l	6*4(a0),d0
	lsr.l	#4+3-2,d0
	subq.l	#1,d0
	move.l	d0,tiles_index_mask

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

loading_game_text_1:
	.asciz	"Loading "

loading_game_text_2:
	.asciz	"...\r\n"

|-------------------------------------------------------------------------------

.bss

.end
