.include "../defines.asm"

.include "../gemdos.asm"

.global load_roms
.global load_tiles_usage_bitmap
.global save_tiles_usage_bitmap

.global	select_game

.global game_info_pointer

.text

|-------------------------------------------------------------------------------
|
|	Select game.
|
|	a0.l = argv[1]
|
|-------------------------------------------------------------------------------
select_game:
	lea		game_info_list,a1
1:
	move.l	(a1)+,a2
	tst.l	a2
	jeq		1f

	move.l	4(a2),a3
	move.l	a0,a4
2:
	cmp.b	(a3)+,(a4)+
	jeq		2b

	tst.b	-(a4)
	jne		1b

	move.l	a2,game_info_pointer

	jra		1f
1:
	Cconws	loading_game_text_1

	move.l	game_info_pointer,a0
	move.l	(a0),a0
	Cconws	(a0)

	Cconws	loading_game_text_2

	rts

|-------------------------------------------------------------------------------
|
|	Load ROM data.
|
|-------------------------------------------------------------------------------

load_roms:
	| Load the program ROM.

	Cconws	loading_program_roms_text

	move.l	game_info_pointer,a0
	move.l	3*4(a0),a0
	jbsr	(a0)

	| Reorder program ROMs.

	Cconws	reordering_program_roms_text

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

bios_rom_file_name:
	.asciz	"sp-s2.sp1"

loading_program_roms_text:
	.asciz	"Loading program ROMs...\r\n"

reordering_program_roms_text:
	.asciz	"Reordering program ROMs...\r\n"

loading_bios_rom_text:
	.asciz	"Loading BIOS ROM...\r\n"

.even

|-------------------------------------------------------------------------------
|
|	Load program ROM.
|
|-------------------------------------------------------------------------------

load_program_rom_1:
	move.l	game_info_pointer,a0
	move.l	4*4(a0),a0

	Fopen	(a0),#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_1_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_1_SIZE,(a0)

	Fclose	d7

	rts

load_program_rom_2:
	move.l	game_info_pointer,a0
	move.l	4*4(a0),a0

	Fopen	(a0),#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_2_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_2_SIZE,(a0)

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_1_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_1_SIZE,(a0)

	Fclose	d7

	rts

load_program_rom_3:
	move.l	game_info_pointer,a0
	move.l	4*4(a0),a0

	Fopen	(a0),#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_1_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_1_SIZE,(a0)

	Fclose	d7

	move.l	game_info_pointer,a0
	move.l	5*4(a0),a0

	Fopen	(a0),#0
	move	d0,d7

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_2_OFFSET,a0
	Fread	d7,#PROGRAM_ROM_2_SIZE,(a0)

	Fclose	d7

	rts

|-------------------------------------------------------------------------------
|
|	Load tiles usage bitmap.
|
|-------------------------------------------------------------------------------

load_tiles_usage_bitmap:
	Cconws	loading_tiles_usage_bitmap_text

	move.l	game_info_pointer,a0
	move.l	2*4(a0),a0

	Fopen	(a0),#0
	move	d0,d7
	jmi		1f

	Fread	d7,#0x20000,TILES_USAGE_BITMAP

	Fclose	d7

	rts
1:
	lea		TILES_USAGE_BITMAP,a0
	move.l	a0,a1
	add.l	#0x20000,a1
1:
	clr.l	(a0)+

	cmp.l	a1,a0
	jlt		1b

	rts

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

	move.l	game_info_pointer,a0
	move.l	2*4(a0),a0

	Fcreate	(a0),#0
	move	d0,d7

	Fwrite	d7,#0x20000,TILES_USAGE_BITMAP

	Fclose	d7

	rts

saving_tiles_usage_bitmap_text:
	.asciz	"Saving tiles usage bitmap...\r\n"

.even

|-------------------------------------------------------------------------------

.data

loading_game_text_1:
	.asciz	"Loading "

loading_game_text_2:
	.asciz	"...\r\n"

.even

game_info_list:
	dc.l	mslug_info
	dc.l	mslug2_info
	dc.l	neobombe_info
	dc.l	kof94_info
	dc.l	pulstar_info
	dc.l	viewpoin_info
	dc.l	nitdbl_info
	dc.l	pbobblen_info
	dc.l	tophuntr_info
	dc.l	0

game_info_pointer:
	dc.l	mslug_info

mslug_info:
	dc.l	mslug_game_name
	dc.l	mslug_compiled_tiles_file_name,mslug_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,mslug_p1_rom_file_name,0
	dc.l	0x1000000															| Total tiles ROM size.
	dc.l	0x800000,mslug_c1_rom_file_name,mslug_c2_rom_file_name
	dc.l	0x800000,mslug_c3_rom_file_name,mslug_c4_rom_file_name

mslug_game_name:
	.asciz	"Metal Slug"

mslug_compiled_tiles_file_name:
	.asciz	"mslug\\mslug.tls"

mslug_tiles_usage_bitmap_file_name:
	.asciz	"mslug\\mslug.ubm"

mslug_p1_rom_file_name:
	.asciz	"mslug\\201-p1.p1"

mslug_c1_rom_file_name:
	.asciz	"mslug\\201-c1.c1"

mslug_c2_rom_file_name:
	.asciz	"mslug\\201-c2.c2"

mslug_c3_rom_file_name:
	.asciz	"mslug\\201-c3.c3"

mslug_c4_rom_file_name:
	.asciz	"mslug\\201-c4.c4"

.even

mslug2_info:
	dc.l	mslug2_game_name
	dc.l	mslug2_compiled_tiles_file_name,mslug2_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,mslug2_p1_rom_file_name,mslug2_p2_rom_file_name
	dc.l	0x2000000															| Total tiles ROM size.
	dc.l	0x1000000,mslug2_c1_rom_file_name,mslug2_c2_rom_file_name
	dc.l	0x1000000,mslug2_c3_rom_file_name,mslug2_c4_rom_file_name

mslug2_game_name:
	.asciz	"Metal Slug 2"

mslug2_compiled_tiles_file_name:
	.asciz	"mslug2\\mslug2.tls"

mslug2_tiles_usage_bitmap_file_name:
	.asciz	"mslug2\\mslug2.ubm"

mslug2_p1_rom_file_name:
	.asciz	"mslug2\\241-p1.p1"

mslug2_p2_rom_file_name:
	.asciz	"mslug2\\241-p2.sp2"

mslug2_c1_rom_file_name:
	.asciz	"mslug2\\241-c1.c1"

mslug2_c2_rom_file_name:
	.asciz	"mslug2\\241-c2.c2"

mslug2_c3_rom_file_name:
	.asciz	"mslug2\\241-c3.c3"

mslug2_c4_rom_file_name:
	.asciz	"mslug2\\241-c4.c4"

.even

neobombe_info:
	dc.l	neobombe_game_name
	dc.l	neobombe_compiled_tiles_file_name,neobombe_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,neobombe_p1_rom_file_name,0
	dc.l	0x900000															| Total tiles ROM size.
	dc.l	0x800000,neobombe_c1_rom_file_name,neobombe_c2_rom_file_name
	dc.l	0x100000,neobombe_c3_rom_file_name,neobombe_c4_rom_file_name

neobombe_game_name:
	.asciz	"Neo Bomberman"

neobombe_compiled_tiles_file_name:
	.asciz	"neobombe\\neobombe.tls"

neobombe_tiles_usage_bitmap_file_name:
	.asciz	"neobombe\\neobombe.ubm"

neobombe_p1_rom_file_name:
	.asciz	"neobombe\\093-p1.p1"

neobombe_c1_rom_file_name:
	.asciz	"neobombe\\093-c1.c1"

neobombe_c2_rom_file_name:
	.asciz	"neobombe\\093-c2.c2"

neobombe_c3_rom_file_name:
	.asciz	"neobombe\\093-c3.c3"

neobombe_c4_rom_file_name:
	.asciz	"neobombe\\093-c4.c4"

.even

kof94_info:
	dc.l	kof94_game_name
	dc.l	kof94_compiled_tiles_file_name,kof94_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,kof94_p1_rom_file_name,0
	dc.l	0x1000000															| Total tiles ROM size.
	dc.l	0x400000,kof94_c1_rom_file_name,kof94_c2_rom_file_name
	dc.l	0x400000,kof94_c3_rom_file_name,kof94_c4_rom_file_name
	dc.l	0x400000,kof94_c5_rom_file_name,kof94_c6_rom_file_name
	dc.l	0x400000,kof94_c7_rom_file_name,kof94_c8_rom_file_name

kof94_game_name:
	.asciz	"The King of Fighters '94"

kof94_compiled_tiles_file_name:
	.asciz	"kof94\\kof94.tls"

kof94_tiles_usage_bitmap_file_name:
	.asciz	"kof94\\kof94.ubm"

kof94_p1_rom_file_name:
	.asciz	"kof94\\055-p1.p1"

kof94_c1_rom_file_name:
	.asciz	"kof94\\055-c1.c1"

kof94_c2_rom_file_name:
	.asciz	"kof94\\055-c2.c2"

kof94_c3_rom_file_name:
	.asciz	"kof94\\055-c3.c3"

kof94_c4_rom_file_name:
	.asciz	"kof94\\055-c4.c4"

kof94_c5_rom_file_name:
	.asciz	"kof94\\055-c5.c5"

kof94_c6_rom_file_name:
	.asciz	"kof94\\055-c6.c6"

kof94_c7_rom_file_name:
	.asciz	"kof94\\055-c7.c7"

kof94_c8_rom_file_name:
	.asciz	"kof94\\055-c8.c8"

.even

pulstar_info:
	dc.l	pulstar_game_name
	dc.l	pulstar_compiled_tiles_file_name,pulstar_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,pulstar_p1_rom_file_name,pulstar_p2_rom_file_name
	dc.l	0x1c00000															| Total tiles ROM size.
	dc.l	0x800000,pulstar_c1_rom_file_name,pulstar_c2_rom_file_name
	dc.l	0x800000,pulstar_c3_rom_file_name,pulstar_c4_rom_file_name
	dc.l	0x800000,pulstar_c5_rom_file_name,pulstar_c6_rom_file_name
	dc.l	0x400000,pulstar_c7_rom_file_name,pulstar_c8_rom_file_name

pulstar_game_name:
	.asciz	"Pulstar"

pulstar_compiled_tiles_file_name:
	.asciz	"pulstar\\pulstar.tls"

pulstar_tiles_usage_bitmap_file_name:
	.asciz	"pulstar\\pulstar.ubm"

pulstar_p1_rom_file_name:
	.asciz	"pulstar\\089-p1.p1"

pulstar_p2_rom_file_name:
	.asciz	"pulstar\\089-p2.sp2"

pulstar_c1_rom_file_name:
	.asciz	"pulstar\\089-c1.c1"

pulstar_c2_rom_file_name:
	.asciz	"pulstar\\089-c2.c2"

pulstar_c3_rom_file_name:
	.asciz	"pulstar\\089-c3.c3"

pulstar_c4_rom_file_name:
	.asciz	"pulstar\\089-c4.c4"

pulstar_c5_rom_file_name:
	.asciz	"pulstar\\089-c5.c5"

pulstar_c6_rom_file_name:
	.asciz	"pulstar\\089-c6.c6"

pulstar_c7_rom_file_name:
	.asciz	"pulstar\\089-c7.c7"

pulstar_c8_rom_file_name:
	.asciz	"pulstar\\089-c8.c8"

.even

viewpoin_info:
	dc.l	viewpoin_game_name
	dc.l	viewpoin_compiled_tiles_file_name,viewpoin_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,viewpoin_p1_rom_file_name,0
	dc.l	0x400000															| Total tiles ROM size.
	dc.l	0x400000,viewpoin_c1_rom_file_name,viewpoin_c2_rom_file_name

viewpoin_game_name:
	.asciz	"Viewpoint"

viewpoin_compiled_tiles_file_name:
	.asciz	"viewpoin\\viewpoin.tls"

viewpoin_tiles_usage_bitmap_file_name:
	.asciz	"viewpoin\\viewpoin.ubm"

viewpoin_p1_rom_file_name:
	.asciz	"viewpoin\\051-p1.p1"

viewpoin_c1_rom_file_name:
	.asciz	"viewpoin\\051-c1.c1"

viewpoin_c2_rom_file_name:
	.asciz	"viewpoin\\051-c2.c2"

.even

nitdbl_info:
	dc.l	nitdbl_game_name
	dc.l	nitdbl_compiled_tiles_file_name,nitdbl_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,nitdbl_p1_rom_file_name,0
	dc.l	0x800000															| Total tiles ROM size.
	dc.l	0x400000,nitdbl_c1_rom_file_name,nitdbl_c2_rom_file_name
	dc.l	0x400000,nitdbl_c3_rom_file_name,nitdbl_c4_rom_file_name

nitdbl_game_name:
	.asciz	"Nightmare in the Dark (bootleg)"

nitdbl_compiled_tiles_file_name:
	.asciz	"nitdbl\\nitdbl.tls"

nitdbl_tiles_usage_bitmap_file_name:
	.asciz	"nitdbl\\nitdbl.ubm"

nitdbl_p1_rom_file_name:
	.asciz	"nitdbl\\nitd-p1.bin"

nitdbl_c1_rom_file_name:
	.asciz	"nitdbl\\nitd-c1.bin"

nitdbl_c2_rom_file_name:
	.asciz	"nitdbl\\nitd-c2.bin"

nitdbl_c3_rom_file_name:
	.asciz	"nitdbl\\nitd-c3.bin"

nitdbl_c4_rom_file_name:
	.asciz	"nitdbl\\nitd-c4.bin"

.even

pbobblen_info:
	dc.l	pbobblen_game_name
	dc.l	pbobblen_compiled_tiles_file_name,pbobblen_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,pbobblen_p1_rom_file_name,0
	dc.l	0x400000															| Total tiles ROM size.
	dc.l	0x200000,pbobblen_c1_rom_file_name,pbobblen_c2_rom_file_name
	dc.l	0x200000,pbobblen_c3_rom_file_name,pbobblen_c4_rom_file_name

pbobblen_game_name:
	.asciz	"Puzzle Bobble"

pbobblen_compiled_tiles_file_name:
	.asciz	"pbobblen\\pbobblen.tls"

pbobblen_tiles_usage_bitmap_file_name:
	.asciz	"pbobblen\\pbobblen.ubm"

pbobblen_p1_rom_file_name:
	.asciz	"pbobblen\\d96-07.ep1"

pbobblen_c1_rom_file_name:
	.asciz	"pbobblen\\068-c1.c1"

pbobblen_c2_rom_file_name:
	.asciz	"pbobblen\\068-c2.c2"

pbobblen_c3_rom_file_name:
	.asciz	"pbobblen\\068-c3.c3"

pbobblen_c4_rom_file_name:
	.asciz	"pbobblen\\068-c4.c4"

.even

tophuntr_info:
	dc.l	tophuntr_game_name
	dc.l	tophuntr_compiled_tiles_file_name,tophuntr_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,tophuntr_p1_rom_file_name,tophuntr_p2_rom_file_name
	dc.l	0x800000															| Total tiles ROM size.
	dc.l	0x200000,tophuntr_c1_rom_file_name,tophuntr_c2_rom_file_name
	dc.l	0x200000,tophuntr_c3_rom_file_name,tophuntr_c4_rom_file_name
	dc.l	0x200000,tophuntr_c5_rom_file_name,tophuntr_c6_rom_file_name
	dc.l	0x200000,tophuntr_c7_rom_file_name,tophuntr_c8_rom_file_name

tophuntr_game_name:
	.asciz	"Top Hunter"

tophuntr_compiled_tiles_file_name:
	.asciz	"tophuntr\\tophuntr.tls"

tophuntr_tiles_usage_bitmap_file_name:
	.asciz	"tophuntr\\tophuntr.ubm"

tophuntr_p1_rom_file_name:
	.asciz	"tophuntr\\046-p1.p1"

tophuntr_p2_rom_file_name:
	.asciz	"tophuntr\\046-p2.sp2"

tophuntr_c1_rom_file_name:
	.asciz	"tophuntr\\046-c1.c1"

tophuntr_c2_rom_file_name:
	.asciz	"tophuntr\\046-c2.c2"

tophuntr_c3_rom_file_name:
	.asciz	"tophuntr\\046-c3.c3"

tophuntr_c4_rom_file_name:
	.asciz	"tophuntr\\046-c4.c4"

tophuntr_c5_rom_file_name:
	.asciz	"tophuntr\\046-c5.c5"

tophuntr_c6_rom_file_name:
	.asciz	"tophuntr\\046-c6.c6"

tophuntr_c7_rom_file_name:
	.asciz	"tophuntr\\046-c7.c7"

tophuntr_c8_rom_file_name:
	.asciz	"tophuntr\\046-c8.c8"

.even

|-------------------------------------------------------------------------------

.bss

.end
