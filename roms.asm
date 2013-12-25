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

|	Cconws	loading_program_roms_text

	move.l	game_info_pointer,a0
	move.l	3*4(a0),a0
	jbsr	(a0)

	| Reorder program ROMs.

|	Cconws	reordering_program_roms_text

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

	| Patch Viewpoint.

	cmp.l	#viewpoin_info,game_info_pointer
	jne		1f

	move.l	neogeo_memory_pages_start,a0
	add.l	#PROGRAM_ROM_1_OFFSET+0x5aba,a0
	move	#0x508f,(a0)
1:
	| Load the BIOS ROM.

|	Cconws	loading_bios_rom_text

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

load_program_rom_4:
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
	add.l	#PROGRAM_ROM_1_OFFSET+0x80000,a0
	Fread	d7,#0x80000,(a0)

	Fclose	d7

	rts

|-------------------------------------------------------------------------------
|
|	Load tiles usage bitmap.
|
|-------------------------------------------------------------------------------

load_tiles_usage_bitmap:
|	Cconws	loading_tiles_usage_bitmap_text

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
|	Cconws	saving_tiles_usage_bitmap_text

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
	dc.l	alpham2_info
	dc.l	androdun_info
	dc.l	bjourney_info
	dc.l	blazstar_info
	dc.l	burningf_info
	dc.l	ctomaday_info
	dc.l	eightman_info
	dc.l	fatfury1_info
	dc.l	flipshot_info
	dc.l	ganryu_info
	dc.l	gowcaizr_info
	dc.l	gpilots_info
	dc.l	ironclad_info
	dc.l	kabukikl_info
	dc.l	kizuna_info
	dc.l	kof94_info
	dc.l	kotm_info
	dc.l	kotm2_info
	dc.l	lresort_info
	dc.l	maglord_info
	dc.l	mslug_info
	dc.l	mslug2_info
	dc.l	mutnat_info
	dc.l	neobombe_info
	dc.l	neomrdo_info
	dc.l	nitdbl_info
	dc.l	pbobblen_info
	dc.l	pulstar_info
	dc.l	roboarmy_info
	dc.l	samsho_info
	dc.l	samsho2_info
	dc.l	savagere_info
	dc.l	sengoku_info
	dc.l	sengoku2_info
	dc.l	sengoku3_info
	dc.l	sonicwi2_info
	dc.l	sonicwi3_info
	dc.l	spinmast_info
	dc.l	tophuntr_info
	dc.l	twinspri_info
	dc.l	viewpoin_info
	dc.l	zedblade_info
	dc.l	zupapa_info
	dc.l	0

game_info_pointer:
	dc.l	mslug_info

mslug_info:
	dc.l	mslug_game_name
	dc.l	mslug_compiled_tiles_file_name,mslug_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,mslug_p1_rom_file_name,0
	dc.l	0x1000000
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
	dc.l	0x2000000
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
	dc.l	0x900000
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
	dc.l	0x1000000
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
	dc.l	0x1c00000
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
	dc.l	0x400000
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
	dc.l	0x800000
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
	dc.l	0x500000
	dc.l	0x200000,pbobblen_c1_rom_file_name,pbobblen_c2_rom_file_name
	dc.l	0x200000,pbobblen_c3_rom_file_name,pbobblen_c4_rom_file_name
	dc.l	0x100000,pbobblen_c5_rom_file_name,pbobblen_c6_rom_file_name

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

pbobblen_c5_rom_file_name:
	.asciz	"pbobblen\\d96-02.c5"

pbobblen_c6_rom_file_name:
	.asciz	"pbobblen\\d96-03.c6"

.even

tophuntr_info:
	dc.l	tophuntr_game_name
	dc.l	tophuntr_compiled_tiles_file_name,tophuntr_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,tophuntr_p1_rom_file_name,tophuntr_p2_rom_file_name
	dc.l	0x800000
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

sengoku_info:
	dc.l	sengoku_game_name
	dc.l	sengoku_compiled_tiles_file_name,sengoku_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_4,sengoku_p1_rom_file_name,sengoku_p2_rom_file_name
	dc.l	0x400000
	dc.l	0x200000,sengoku_c1_rom_file_name,sengoku_c2_rom_file_name
	dc.l	0x200000,sengoku_c3_rom_file_name,sengoku_c4_rom_file_name

sengoku_game_name:
	.asciz	"Sengoku"

sengoku_compiled_tiles_file_name:
	.asciz	"sengoku\\sengoku.tls"

sengoku_tiles_usage_bitmap_file_name:
	.asciz	"sengoku\\sengoku.ubm"

sengoku_p1_rom_file_name:
	.asciz	"sengoku\\017-p1.p1"

sengoku_p2_rom_file_name:
	.asciz	"sengoku\\017-p2.p2"

sengoku_c1_rom_file_name:
	.asciz	"sengoku\\017-c1.c1"

sengoku_c2_rom_file_name:
	.asciz	"sengoku\\017-c2.c2"

sengoku_c3_rom_file_name:
	.asciz	"sengoku\\017-c3.c3"

sengoku_c4_rom_file_name:
	.asciz	"sengoku\\017-c4.c4"

.even

sengoku2_info:																	| Note the strange C-ROM order!
	dc.l	sengoku2_game_name
	dc.l	sengoku2_compiled_tiles_file_name,sengoku2_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,sengoku2_p1_rom_file_name,0
	dc.l	0x500000
	dc.l	0x200000,sengoku2_c1_rom_file_name,sengoku2_c2_rom_file_name
	dc.l	0x100000,sengoku2_c3_rom_file_name,sengoku2_c4_rom_file_name
	dc.l	0x200000,sengoku2_c1_rom_file_name,sengoku2_c2_rom_file_name

sengoku2_game_name:
	.asciz	"Sengoku 2"

sengoku2_compiled_tiles_file_name:
	.asciz	"sengoku2\\sengoku2.tls"

sengoku2_tiles_usage_bitmap_file_name:
	.asciz	"sengoku2\\sengoku2.ubm"

sengoku2_p1_rom_file_name:
	.asciz	"sengoku2\\040-p1.p1"

sengoku2_c1_rom_file_name:
	.asciz	"sengoku2\\040-c1.c1"

sengoku2_c2_rom_file_name:
	.asciz	"sengoku2\\040-c2.c2"

sengoku2_c3_rom_file_name:
	.asciz	"sengoku2\\040-c3.c3"

sengoku2_c4_rom_file_name:
	.asciz	"sengoku2\\040-c4.c4"

.even

blazstar_info:
	dc.l	blazstar_game_name
	dc.l	blazstar_compiled_tiles_file_name,blazstar_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,blazstar_p1_rom_file_name,blazstar_p2_rom_file_name
	dc.l	0x2000000
	dc.l	0x800000,blazstar_c1_rom_file_name,blazstar_c2_rom_file_name
	dc.l	0x800000,blazstar_c3_rom_file_name,blazstar_c4_rom_file_name
	dc.l	0x800000,blazstar_c5_rom_file_name,blazstar_c6_rom_file_name
	dc.l	0x800000,blazstar_c7_rom_file_name,blazstar_c8_rom_file_name

blazstar_game_name:
	.asciz	"Blazing Star"

blazstar_compiled_tiles_file_name:
	.asciz	"blazstar\\blazstar.tls"

blazstar_tiles_usage_bitmap_file_name:
	.asciz	"blazstar\\blazstar.ubm"

blazstar_p1_rom_file_name:
	.asciz	"blazstar\\239-p1.p1"

blazstar_p2_rom_file_name:
	.asciz	"blazstar\\239-p2.sp2"

blazstar_c1_rom_file_name:
	.asciz	"blazstar\\239-c1.c1"

blazstar_c2_rom_file_name:
	.asciz	"blazstar\\239-c2.c2"

blazstar_c3_rom_file_name:
	.asciz	"blazstar\\239-c3.c3"

blazstar_c4_rom_file_name:
	.asciz	"blazstar\\239-c4.c4"

blazstar_c5_rom_file_name:
	.asciz	"blazstar\\239-c5.c5"

blazstar_c6_rom_file_name:
	.asciz	"blazstar\\239-c6.c6"

blazstar_c7_rom_file_name:
	.asciz	"blazstar\\239-c7.c7"

blazstar_c8_rom_file_name:
	.asciz	"blazstar\\239-c8.c8"

.even

lresort_info:
	dc.l	lresort_game_name
	dc.l	lresort_compiled_tiles_file_name,lresort_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,lresort_p1_rom_file_name,0
	dc.l	0x300000
	dc.l	0x200000,lresort_c1_rom_file_name,lresort_c2_rom_file_name
	dc.l	0x100000,lresort_c3_rom_file_name,lresort_c4_rom_file_name

lresort_game_name:
	.asciz	"Last Resort"

lresort_compiled_tiles_file_name:
	.asciz	"lresort\\lresort.tls"

lresort_tiles_usage_bitmap_file_name:
	.asciz	"lresort\\lresort.ubm"

lresort_p1_rom_file_name:
	.asciz	"lresort\\024-p1.p1"

lresort_c1_rom_file_name:
	.asciz	"lresort\\024-c1.c1"

lresort_c2_rom_file_name:
	.asciz	"lresort\\024-c2.c2"

lresort_c3_rom_file_name:
	.asciz	"lresort\\024-c3.c3"

lresort_c4_rom_file_name:
	.asciz	"lresort\\024-c4.c4"

.even

sonicwi2_info:
	dc.l	sonicwi2_game_name
	dc.l	sonicwi2_compiled_tiles_file_name,sonicwi2_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,sonicwi2_p1_rom_file_name,0
	dc.l	0x800000
	dc.l	0x400000,sonicwi2_c1_rom_file_name,sonicwi2_c2_rom_file_name
	dc.l	0x400000,sonicwi2_c3_rom_file_name,sonicwi2_c4_rom_file_name

sonicwi2_game_name:
	.asciz	"Aero Fighters 2 / Sonic Wings 2"

sonicwi2_compiled_tiles_file_name:
	.asciz	"sonicwi2\\sonicwi2.tls"

sonicwi2_tiles_usage_bitmap_file_name:
	.asciz	"sonicwi2\\sonicwi2.ubm"

sonicwi2_p1_rom_file_name:
	.asciz	"sonicwi2\\075-p1.p1"

sonicwi2_c1_rom_file_name:
	.asciz	"sonicwi2\\075-c1.c1"

sonicwi2_c2_rom_file_name:
	.asciz	"sonicwi2\\075-c2.c2"

sonicwi2_c3_rom_file_name:
	.asciz	"sonicwi2\\075-c3.c3"

sonicwi2_c4_rom_file_name:
	.asciz	"sonicwi2\\075-c4.c4"

.even

sonicwi3_info:
	dc.l	sonicwi3_game_name
	dc.l	sonicwi3_compiled_tiles_file_name,sonicwi3_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,sonicwi3_p1_rom_file_name,0
	dc.l	0xc00000
	dc.l	0x800000,sonicwi3_c1_rom_file_name,sonicwi3_c2_rom_file_name
	dc.l	0x400000,sonicwi3_c3_rom_file_name,sonicwi3_c4_rom_file_name

sonicwi3_game_name:
	.asciz	"Aero Fighters 3 / Sonic Wings 3"

sonicwi3_compiled_tiles_file_name:
	.asciz	"sonicwi3\\sonicwi3.tls"

sonicwi3_tiles_usage_bitmap_file_name:
	.asciz	"sonicwi3\\sonicwi3.ubm"

sonicwi3_p1_rom_file_name:
	.asciz	"sonicwi3\\097-p1.p1"

sonicwi3_c1_rom_file_name:
	.asciz	"sonicwi3\\097-c1.c1"

sonicwi3_c2_rom_file_name:
	.asciz	"sonicwi3\\097-c2.c2"

sonicwi3_c3_rom_file_name:
	.asciz	"sonicwi3\\097-c3.c3"

sonicwi3_c4_rom_file_name:
	.asciz	"sonicwi3\\097-c4.c4"

.even

kabukikl_info:
	dc.l	kabukikl_game_name
	dc.l	kabukikl_compiled_tiles_file_name,kabukikl_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,kabukikl_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x800000,kabukikl_c1_rom_file_name,kabukikl_c2_rom_file_name
	dc.l	0x800000,kabukikl_c3_rom_file_name,kabukikl_c4_rom_file_name

kabukikl_game_name:
	.asciz	"Kabuki Klash"

kabukikl_compiled_tiles_file_name:
	.asciz	"kabukikl\\kabukikl.tls"

kabukikl_tiles_usage_bitmap_file_name:
	.asciz	"kabukikl\\kabukikl.ubm"

kabukikl_p1_rom_file_name:
	.asciz	"kabukikl\\092-p1.p1"

kabukikl_c1_rom_file_name:
	.asciz	"kabukikl\\092-c1.c1"

kabukikl_c2_rom_file_name:
	.asciz	"kabukikl\\092-c2.c2"

kabukikl_c3_rom_file_name:
	.asciz	"kabukikl\\092-c3.c3"

kabukikl_c4_rom_file_name:
	.asciz	"kabukikl\\092-c4.c4"

.even

kizuna_info:
	dc.l	kizuna_game_name
	dc.l	kizuna_compiled_tiles_file_name,kizuna_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,kizuna_p1_rom_file_name,0
	dc.l	0x1c00000
	dc.l	0x800000,kizuna_c1_rom_file_name,kizuna_c2_rom_file_name
	dc.l	0x800000,kizuna_c3_rom_file_name,kizuna_c4_rom_file_name
	dc.l	0x800000,kizuna_c5_rom_file_name,kizuna_c6_rom_file_name
	dc.l	0x400000,kizuna_c7_rom_file_name,kizuna_c8_rom_file_name

kizuna_game_name:
	.asciz	"Kizuna Encounter: Super Tag Battle"

kizuna_compiled_tiles_file_name:
	.asciz	"kizuna\\kizuna.tls"

kizuna_tiles_usage_bitmap_file_name:
	.asciz	"kizuna\\kizuna.ubm"

kizuna_p1_rom_file_name:
	.asciz	"kizuna\\216-p1.p1"

kizuna_c1_rom_file_name:
	.asciz	"kizuna\\059-c1.c1"

kizuna_c2_rom_file_name:
	.asciz	"kizuna\\059-c2.c2"

kizuna_c3_rom_file_name:
	.asciz	"kizuna\\216-c3.c3"

kizuna_c4_rom_file_name:
	.asciz	"kizuna\\216-c4.c4"

kizuna_c5_rom_file_name:
	.asciz	"kizuna\\059-c5.c5"

kizuna_c6_rom_file_name:
	.asciz	"kizuna\\059-c6.c6"

kizuna_c7_rom_file_name:
	.asciz	"kizuna\\059-c7.c7"

kizuna_c8_rom_file_name:
	.asciz	"kizuna\\059-c8.c8"

.even

kotm_info:
	dc.l	kotm_game_name
	dc.l	kotm_compiled_tiles_file_name,kotm_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_4,kotm_p1_rom_file_name,kotm_p2_rom_file_name
	dc.l	0x400000
	dc.l	0x200000,kotm_c1_rom_file_name,kotm_c2_rom_file_name
	dc.l	0x200000,kotm_c3_rom_file_name,kotm_c4_rom_file_name

kotm_game_name:
	.asciz	"King of the Monsters"

kotm_compiled_tiles_file_name:
	.asciz	"kotm\\kotm.tls"

kotm_tiles_usage_bitmap_file_name:
	.asciz	"kotm\\kotm.ubm"

kotm_p1_rom_file_name:
	.asciz	"kotm\\016-p1.p1"

kotm_p2_rom_file_name:
	.asciz	"kotm\\016-p2.p2"

kotm_c1_rom_file_name:
	.asciz	"kotm\\016-c1.c1"

kotm_c2_rom_file_name:
	.asciz	"kotm\\016-c2.c2"

kotm_c3_rom_file_name:
	.asciz	"kotm\\016-c3.c3"

kotm_c4_rom_file_name:
	.asciz	"kotm\\016-c4.c4"

.even

kotm2_info:
	dc.l	kotm2_game_name
	dc.l	kotm2_compiled_tiles_file_name,kotm2_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,kotm2_p1_rom_file_name,kotm2_p2_rom_file_name
	dc.l	0x600000
	dc.l	0x200000,kotm2_c1_rom_file_name,kotm2_c2_rom_file_name
	dc.l	0x100000,kotm2_c3_rom_file_name,kotm2_c4_rom_file_name
	dc.l	0x200000,kotm2_c1_rom_file_name,kotm2_c2_rom_file_name

kotm2_game_name:
	.asciz	"King of the Monsters 2"

kotm2_compiled_tiles_file_name:
	.asciz	"kotm2\\kotm2.tls"

kotm2_tiles_usage_bitmap_file_name:
	.asciz	"kotm2\\kotm2.ubm"

kotm2_p1_rom_file_name:
	.asciz	"kotm2\\039-p1.p1"

kotm2_p2_rom_file_name:
	.asciz	"kotm2\\039-p2.p2"

kotm2_c1_rom_file_name:
	.asciz	"kotm2\\039-c1.c1"

kotm2_c2_rom_file_name:
	.asciz	"kotm2\\039-c2.c2"

kotm2_c3_rom_file_name:
	.asciz	"kotm2\\039-c3.c3"

kotm2_c4_rom_file_name:
	.asciz	"kotm2\\039-c4.c4"

.even

burningf_info:
	dc.l	burningf_game_name
	dc.l	burningf_compiled_tiles_file_name,burningf_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,burningf_p1_rom_file_name,0
	dc.l	0x400000
	dc.l	0x200000,burningf_c1_rom_file_name,burningf_c2_rom_file_name
	dc.l	0x200000,burningf_c3_rom_file_name,burningf_c4_rom_file_name

burningf_game_name:
	.asciz	"Burning Fight"

burningf_compiled_tiles_file_name:
	.asciz	"burningf\\burningf.tls"

burningf_tiles_usage_bitmap_file_name:
	.asciz	"burningf\\burningf.ubm"

burningf_p1_rom_file_name:
	.asciz	"burningf\\018-p1.p1"

burningf_c1_rom_file_name:
	.asciz	"burningf\\018-c1.c1"

burningf_c2_rom_file_name:
	.asciz	"burningf\\018-c2.c2"

burningf_c3_rom_file_name:
	.asciz	"burningf\\018-c3.c3"

burningf_c4_rom_file_name:
	.asciz	"burningf\\018-c4.c4"

.even

gpilots_info:
	dc.l	gpilots_game_name
	dc.l	gpilots_compiled_tiles_file_name,gpilots_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_4,gpilots_p1_rom_file_name,gpilots_p2_rom_file_name
	dc.l	0x400000
	dc.l	0x200000,gpilots_c1_rom_file_name,gpilots_c2_rom_file_name
	dc.l	0x200000,gpilots_c3_rom_file_name,gpilots_c4_rom_file_name

gpilots_game_name:
	.asciz	"Ghost Pilots"

gpilots_compiled_tiles_file_name:
	.asciz	"gpilots\\gpilots.tls"

gpilots_tiles_usage_bitmap_file_name:
	.asciz	"gpilots\\gpilots.ubm"

gpilots_p1_rom_file_name:
	.asciz	"gpilots\\020-p1.p1"

gpilots_p2_rom_file_name:
	.asciz	"gpilots\\020-p2.p2"

gpilots_c1_rom_file_name:
	.asciz	"gpilots\\020-c1.c1"

gpilots_c2_rom_file_name:
	.asciz	"gpilots\\020-c2.c2"

gpilots_c3_rom_file_name:
	.asciz	"gpilots\\020-c3.c3"

gpilots_c4_rom_file_name:
	.asciz	"gpilots\\020-c4.c4"

.even

samsho2_info:
	dc.l	samsho2_game_name
	dc.l	samsho2_compiled_tiles_file_name,samsho2_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,samsho2_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x400000,samsho2_c1_rom_file_name,samsho2_c2_rom_file_name
	dc.l	0x400000,samsho2_c3_rom_file_name,samsho2_c4_rom_file_name
	dc.l	0x400000,samsho2_c5_rom_file_name,samsho2_c6_rom_file_name
	dc.l	0x400000,samsho2_c7_rom_file_name,samsho2_c8_rom_file_name

samsho2_game_name:
	.asciz	"Samurai Shodown 2"

samsho2_compiled_tiles_file_name:
	.asciz	"samsho2\\samsho2.tls"

samsho2_tiles_usage_bitmap_file_name:
	.asciz	"samsho2\\samsho2.ubm"

samsho2_p1_rom_file_name:
	.asciz	"samsho2\\063-p1.p1"

samsho2_c1_rom_file_name:
	.asciz	"samsho2\\063-c1.c1"

samsho2_c2_rom_file_name:
	.asciz	"samsho2\\063-c2.c2"

samsho2_c3_rom_file_name:
	.asciz	"samsho2\\063-c3.c3"

samsho2_c4_rom_file_name:
	.asciz	"samsho2\\063-c4.c4"

samsho2_c5_rom_file_name:
	.asciz	"samsho2\\063-c5.c5"

samsho2_c6_rom_file_name:
	.asciz	"samsho2\\063-c6.c6"

samsho2_c7_rom_file_name:
	.asciz	"samsho2\\063-c7.c7"

samsho2_c8_rom_file_name:
	.asciz	"samsho2\\063-c8.c8"

.even

samsho_info:
	dc.l	samsho_game_name
	dc.l	samsho_compiled_tiles_file_name,samsho_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,samsho_p1_rom_file_name,samsho_p2_rom_file_name
	dc.l	0x1000000
	dc.l	0x400000,samsho_c1_rom_file_name,samsho_c2_rom_file_name
	dc.l	0x400000,samsho_c3_rom_file_name,samsho_c4_rom_file_name
	dc.l	0x200000,samsho_c5_rom_file_name,samsho_c6_rom_file_name

samsho_game_name:
	.asciz	"Samurai Shodown"

samsho_compiled_tiles_file_name:
	.asciz	"samsho\\samsho.tls"

samsho_tiles_usage_bitmap_file_name:
	.asciz	"samsho\\samsho.ubm"

samsho_p1_rom_file_name:
	.asciz	"samsho\\045-p1.p1"

samsho_p2_rom_file_name:
	.asciz	"samsho\\045-pg2.sp2"

samsho_c1_rom_file_name:
	.asciz	"samsho\\045-c1.c1"

samsho_c2_rom_file_name:
	.asciz	"samsho\\045-c2.c2"

samsho_c3_rom_file_name:
	.asciz	"samsho\\045-c3.c3"

samsho_c4_rom_file_name:
	.asciz	"samsho\\045-c4.c4"

samsho_c5_rom_file_name:
	.asciz	"samsho\\045-c51.c5"

samsho_c6_rom_file_name:
	.asciz	"samsho\\045-c61.c6"

.even

mutnat_info:
	dc.l	mutnat_game_name
	dc.l	mutnat_compiled_tiles_file_name,mutnat_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,mutnat_p1_rom_file_name,0
	dc.l	0x400000
	dc.l	0x200000,mutnat_c1_rom_file_name,mutnat_c2_rom_file_name
	dc.l	0x200000,mutnat_c3_rom_file_name,mutnat_c4_rom_file_name

mutnat_game_name:
	.asciz	"Mutation Nation"

mutnat_compiled_tiles_file_name:
	.asciz	"mutnat\\mutnat.tls"

mutnat_tiles_usage_bitmap_file_name:
	.asciz	"mutnat\\mutnat.ubm"

mutnat_p1_rom_file_name:
	.asciz	"mutnat\\014-p1.p1"

mutnat_c1_rom_file_name:
	.asciz	"mutnat\\014-c1.c1"

mutnat_c2_rom_file_name:
	.asciz	"mutnat\\014-c2.c2"

mutnat_c3_rom_file_name:
	.asciz	"mutnat\\014-c3.c3"

mutnat_c4_rom_file_name:
	.asciz	"mutnat\\014-c4.c4"

.even

twinspri_info:
	dc.l	twinspri_game_name
	dc.l	twinspri_compiled_tiles_file_name,twinspri_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,twinspri_p1_rom_file_name,0
	dc.l	0xa00000
	dc.l	0x800000,twinspri_c1_rom_file_name,twinspri_c2_rom_file_name
	dc.l	0x200000,twinspri_c3_rom_file_name,twinspri_c4_rom_file_name

twinspri_game_name:
	.asciz	"Twinkle Star Sprites"

twinspri_compiled_tiles_file_name:
	.asciz	"twinspri\\twinspri.tls"

twinspri_tiles_usage_bitmap_file_name:
	.asciz	"twinspri\\twinspri.ubm"

twinspri_p1_rom_file_name:
	.asciz	"twinspri\\224-p1.p1"

twinspri_c1_rom_file_name:
	.asciz	"twinspri\\224-c1.c1"

twinspri_c2_rom_file_name:
	.asciz	"twinspri\\224-c2.c2"

twinspri_c3_rom_file_name:
	.asciz	"twinspri\\224-c3.c3"

twinspri_c4_rom_file_name:
	.asciz	"twinspri\\224-c4.c4"

.even

ctomaday_info:
	dc.l	ctomaday_game_name
	dc.l	ctomaday_compiled_tiles_file_name,ctomaday_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,ctomaday_p1_rom_file_name,0
	dc.l	0x800000
	dc.l	0x800000,ctomaday_c1_rom_file_name,ctomaday_c2_rom_file_name

ctomaday_game_name:
	.asciz	"Captain Tomaday"

ctomaday_compiled_tiles_file_name:
	.asciz	"ctomaday\\ctomaday.tls"

ctomaday_tiles_usage_bitmap_file_name:
	.asciz	"ctomaday\\ctomaday.ubm"

ctomaday_p1_rom_file_name:
	.asciz	"ctomaday\\249-p1.p1"

ctomaday_c1_rom_file_name:
	.asciz	"ctomaday\\249-c1.c1"

ctomaday_c2_rom_file_name:
	.asciz	"ctomaday\\249-c2.c2"

.even

alpham2_info:
	dc.l	alpham2_game_name
	dc.l	alpham2_compiled_tiles_file_name,alpham2_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_4,alpham2_p1_rom_file_name,alpham2_p2_rom_file_name
	dc.l	0x300000
	dc.l	0x200000,alpham2_c1_rom_file_name,alpham2_c2_rom_file_name
	dc.l	0x100000,alpham2_c3_rom_file_name,alpham2_c4_rom_file_name

alpham2_game_name:
	.asciz	"Alpha Mission 2"

alpham2_compiled_tiles_file_name:
	.asciz	"alpham2\\alpham2.tls"

alpham2_tiles_usage_bitmap_file_name:
	.asciz	"alpham2\\alpham2.ubm"

alpham2_p1_rom_file_name:
	.asciz	"alpham2\\007-p1.p1"

alpham2_p2_rom_file_name:
	.asciz	"alpham2\\007-p2.p2"

alpham2_c1_rom_file_name:
	.asciz	"alpham2\\007-c1.c1"

alpham2_c2_rom_file_name:
	.asciz	"alpham2\\007-c2.c2"

alpham2_c3_rom_file_name:
	.asciz	"alpham2\\007-c3.c3"

alpham2_c4_rom_file_name:
	.asciz	"alpham2\\007-c4.c4"

.even

ironclad_info:
	dc.l	ironclad_game_name
	dc.l	ironclad_compiled_tiles_file_name,ironclad_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,ironclad_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x800000,ironclad_c1_rom_file_name,ironclad_c2_rom_file_name
	dc.l	0x800000,ironclad_c3_rom_file_name,ironclad_c4_rom_file_name

ironclad_game_name:
	.asciz	"Iron Clad"

ironclad_compiled_tiles_file_name:
	.asciz	"ironclad\\ironclad.tls"

ironclad_tiles_usage_bitmap_file_name:
	.asciz	"ironclad\\ironclad.ubm"

ironclad_p1_rom_file_name:
	.asciz	"ironclad\\proto_22.p1"

ironclad_c1_rom_file_name:
	.asciz	"ironclad\\proto_22.c1"

ironclad_c2_rom_file_name:
	.asciz	"ironclad\\proto_22.c2"

ironclad_c3_rom_file_name:
	.asciz	"ironclad\\proto_22.c3"

ironclad_c4_rom_file_name:
	.asciz	"ironclad\\proto_22.c4"

.even

zedblade_info:
	dc.l	zedblade_game_name
	dc.l	zedblade_compiled_tiles_file_name,zedblade_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,zedblade_p1_rom_file_name,0
	dc.l	0x800000
	dc.l	0x400000,zedblade_c1_rom_file_name,zedblade_c2_rom_file_name
	dc.l	0x400000,zedblade_c3_rom_file_name,zedblade_c4_rom_file_name

zedblade_game_name:
	.asciz	"Zed Blade"

zedblade_compiled_tiles_file_name:
	.asciz	"zedblade\\zedblade.tls"

zedblade_tiles_usage_bitmap_file_name:
	.asciz	"zedblade\\zedblade.ubm"

zedblade_p1_rom_file_name:
	.asciz	"zedblade\\076-p1.p1"

zedblade_c1_rom_file_name:
	.asciz	"zedblade\\076-c1.c1"

zedblade_c2_rom_file_name:
	.asciz	"zedblade\\076-c2.c2"

zedblade_c3_rom_file_name:
	.asciz	"zedblade\\076-c3.c3"

zedblade_c4_rom_file_name:
	.asciz	"zedblade\\076-c4.c4"

.even

neomrdo_info:
	dc.l	neomrdo_game_name
	dc.l	neomrdo_compiled_tiles_file_name,neomrdo_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,neomrdo_p1_rom_file_name,0
	dc.l	0x400000
	dc.l	0x400000,neomrdo_c1_rom_file_name,neomrdo_c2_rom_file_name

neomrdo_game_name:
	.asciz	"Neo Mr. Do!"

neomrdo_compiled_tiles_file_name:
	.asciz	"neomrdo\\neomrdo.tls"

neomrdo_tiles_usage_bitmap_file_name:
	.asciz	"neomrdo\\neomrdo.ubm"

neomrdo_p1_rom_file_name:
	.asciz	"neomrdo\\207-p1.p1"

neomrdo_c1_rom_file_name:
	.asciz	"neomrdo\\207-c1.c1"

neomrdo_c2_rom_file_name:
	.asciz	"neomrdo\\207-c2.c2"

.even

savagere_info:
	dc.l	savagere_game_name
	dc.l	savagere_compiled_tiles_file_name,savagere_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,savagere_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x400000,savagere_c1_rom_file_name,savagere_c2_rom_file_name
	dc.l	0x400000,savagere_c3_rom_file_name,savagere_c4_rom_file_name
	dc.l	0x400000,savagere_c5_rom_file_name,savagere_c6_rom_file_name
	dc.l	0x400000,savagere_c7_rom_file_name,savagere_c8_rom_file_name

savagere_game_name:
	.asciz	"Savage Reign"

savagere_compiled_tiles_file_name:
	.asciz	"savagere\\savagere.tls"

savagere_tiles_usage_bitmap_file_name:
	.asciz	"savagere\\savagere.ubm"

savagere_p1_rom_file_name:
	.asciz	"savagere\\059-p1.p1"

savagere_c1_rom_file_name:
	.asciz	"savagere\\059-c1.c1"

savagere_c2_rom_file_name:
	.asciz	"savagere\\059-c2.c2"

savagere_c3_rom_file_name:
	.asciz	"savagere\\059-c3.c3"

savagere_c4_rom_file_name:
	.asciz	"savagere\\059-c4.c4"

savagere_c5_rom_file_name:
	.asciz	"savagere\\059-c5.c5"

savagere_c6_rom_file_name:
	.asciz	"savagere\\059-c6.c6"

savagere_c7_rom_file_name:
	.asciz	"savagere\\059-c7.c7"

savagere_c8_rom_file_name:
	.asciz	"savagere\\059-c8.c8"

.even

gowcaizr_info:
	dc.l	gowcaizr_game_name
	dc.l	gowcaizr_compiled_tiles_file_name,gowcaizr_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,gowcaizr_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x400000,gowcaizr_c1_rom_file_name,gowcaizr_c2_rom_file_name
	dc.l	0x400000,gowcaizr_c3_rom_file_name,gowcaizr_c4_rom_file_name
	dc.l	0x400000,gowcaizr_c5_rom_file_name,gowcaizr_c6_rom_file_name
	dc.l	0x400000,gowcaizr_c7_rom_file_name,gowcaizr_c8_rom_file_name

gowcaizr_game_name:
	.asciz	"Voltage Fighter - Gowcaizer"

gowcaizr_compiled_tiles_file_name:
	.asciz	"gowcaizr\\gowcaizr.tls"

gowcaizr_tiles_usage_bitmap_file_name:
	.asciz	"gowcaizr\\gowcaizr.ubm"

gowcaizr_p1_rom_file_name:
	.asciz	"gowcaizr\\094-p1.p1"

gowcaizr_c1_rom_file_name:
	.asciz	"gowcaizr\\094-c1.c1"

gowcaizr_c2_rom_file_name:
	.asciz	"gowcaizr\\094-c2.c2"

gowcaizr_c3_rom_file_name:
	.asciz	"gowcaizr\\094-c3.c3"

gowcaizr_c4_rom_file_name:
	.asciz	"gowcaizr\\094-c4.c4"

gowcaizr_c5_rom_file_name:
	.asciz	"gowcaizr\\094-c5.c5"

gowcaizr_c6_rom_file_name:
	.asciz	"gowcaizr\\094-c6.c6"

gowcaizr_c7_rom_file_name:
	.asciz	"gowcaizr\\094-c7.c7"

gowcaizr_c8_rom_file_name:
	.asciz	"gowcaizr\\059-c8.c8"

.even

ganryu_info:
	dc.l	ganryu_game_name
	dc.l	ganryu_compiled_tiles_file_name,ganryu_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,ganryu_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x1000000,ganryu_c1_rom_file_name,ganryu_c2_rom_file_name

ganryu_game_name:
	.asciz	"Ganryu"

ganryu_compiled_tiles_file_name:
	.asciz	"ganryu\\ganryu.tls"

ganryu_tiles_usage_bitmap_file_name:
	.asciz	"ganryu\\ganryu.ubm"

ganryu_p1_rom_file_name:
	.asciz	"ganryu\\252-p1.p1"

ganryu_c1_rom_file_name:
	.asciz	"ganryu\\gann_c1.rom"

ganryu_c2_rom_file_name:
	.asciz	"ganryu\\gann_c2.rom"

.even

sengoku3_info:
	dc.l	sengoku3_game_name
	dc.l	sengoku3_compiled_tiles_file_name,sengoku3_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_2,sengoku3_p1_rom_file_name,0
	dc.l	0x2000000
	dc.l	0x1000000,sengoku3_c1_rom_file_name,sengoku3_c2_rom_file_name
	dc.l	0x1000000,sengoku3_c3_rom_file_name,sengoku3_c4_rom_file_name

sengoku3_game_name:
	.asciz	"Sengoku 3"

sengoku3_compiled_tiles_file_name:
	.asciz	"sengoku3\\sengoku3.tls"

sengoku3_tiles_usage_bitmap_file_name:
	.asciz	"sengoku3\\sengoku3.ubm"

sengoku3_p1_rom_file_name:
	.asciz	"sengoku3\\261-ph1.p1"

sengoku3_c1_rom_file_name:
	.asciz	"sengoku3\\sen3n_c1.rom"

sengoku3_c2_rom_file_name:
	.asciz	"sengoku3\\sen3n_c2.rom"

sengoku3_c3_rom_file_name:
	.asciz	"sengoku3\\sen3n_c3.rom"

sengoku3_c4_rom_file_name:
	.asciz	"sengoku3\\sen3n_c4.rom"

.even

zupapa_info:
	dc.l	zupapa_game_name
	dc.l	zupapa_compiled_tiles_file_name,zupapa_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,zupapa_p1_rom_file_name,0
	dc.l	0x1000000
	dc.l	0x1000000,zupapa_c1_rom_file_name,zupapa_c2_rom_file_name

zupapa_game_name:
	.asciz	"Zupapa!"

zupapa_compiled_tiles_file_name:
	.asciz	"zupapa\\zupapa.tls"

zupapa_tiles_usage_bitmap_file_name:
	.asciz	"zupapa\\zupapa.ubm"

zupapa_p1_rom_file_name:
	.asciz	"zupapa\\070-p1.p1"

zupapa_c1_rom_file_name:
	.asciz	"zupapa\\zupan_c1.rom"

zupapa_c2_rom_file_name:
	.asciz	"zupapa\\zupan_c2.rom"

.even

maglord_info:
	dc.l	maglord_game_name
	dc.l	maglord_compiled_tiles_file_name,maglord_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,maglord_p1_rom_file_name,0
	dc.l	0x300000
	dc.l	0x100000,maglord_c1_rom_file_name,maglord_c2_rom_file_name
	dc.l	0x100000,maglord_c3_rom_file_name,maglord_c4_rom_file_name
	dc.l	0x100000,maglord_c5_rom_file_name,maglord_c6_rom_file_name

maglord_game_name:
	.asciz	"Magician Lord"

maglord_compiled_tiles_file_name:
	.asciz	"maglord\\maglord.tls"

maglord_tiles_usage_bitmap_file_name:
	.asciz	"maglord\\maglord.ubm"

maglord_p1_rom_file_name:
	.asciz	"maglord\\005-pg1.p1"

maglord_c1_rom_file_name:
	.asciz	"maglord\\005-c1.c1"

maglord_c2_rom_file_name:
	.asciz	"maglord\\005-c2.c2"

maglord_c3_rom_file_name:
	.asciz	"maglord\\005-c3.c3"

maglord_c4_rom_file_name:
	.asciz	"maglord\\005-c4.c4"

maglord_c5_rom_file_name:
	.asciz	"maglord\\005-c5.c5"

maglord_c6_rom_file_name:
	.asciz	"maglord\\005-c6.c6"

.even

roboarmy_info:
	dc.l	roboarmy_game_name
	dc.l	roboarmy_compiled_tiles_file_name,roboarmy_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,roboarmy_p1_rom_file_name,0
	dc.l	0x300000
	dc.l	0x200000,roboarmy_c1_rom_file_name,roboarmy_c2_rom_file_name
	dc.l	0x100000,roboarmy_c3_rom_file_name,roboarmy_c4_rom_file_name

roboarmy_game_name:
	.asciz	"Robo Army"

roboarmy_compiled_tiles_file_name:
	.asciz	"roboarmy\\roboarmy.tls"

roboarmy_tiles_usage_bitmap_file_name:
	.asciz	"roboarmy\\roboarmy.ubm"

roboarmy_p1_rom_file_name:
	.asciz	"roboarmy\\032-p1.p1"

roboarmy_c1_rom_file_name:
	.asciz	"roboarmy\\032-c1.c1"

roboarmy_c2_rom_file_name:
	.asciz	"roboarmy\\032-c2.c2"

roboarmy_c3_rom_file_name:
	.asciz	"roboarmy\\032-c3.c3"

roboarmy_c4_rom_file_name:
	.asciz	"roboarmy\\032-c4.c4"

.even

androdun_info:
	dc.l	androdun_game_name
	dc.l	androdun_compiled_tiles_file_name,androdun_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_4,androdun_p1_rom_file_name,androdun_p2_rom_file_name
	dc.l	0x200000
	dc.l	0x200000,androdun_c1_rom_file_name,androdun_c2_rom_file_name

androdun_game_name:
	.asciz	"Andro Dunos"

androdun_compiled_tiles_file_name:
	.asciz	"androdun\\androdun.tls"

androdun_tiles_usage_bitmap_file_name:
	.asciz	"androdun\\androdun.ubm"

androdun_p1_rom_file_name:
	.asciz	"androdun\\049-p1.p1"

androdun_p2_rom_file_name:
	.asciz	"androdun\\049-p2.p2"

androdun_c1_rom_file_name:
	.asciz	"androdun\\049-c1.c1"

androdun_c2_rom_file_name:
	.asciz	"androdun\\049-c2.c2"

.even

flipshot_info:
	dc.l	flipshot_game_name
	dc.l	flipshot_compiled_tiles_file_name,flipshot_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,flipshot_p1_rom_file_name,0
	dc.l	0x400000
	dc.l	0x400000,flipshot_c1_rom_file_name,flipshot_c2_rom_file_name

flipshot_game_name:
	.asciz	"Flipshot"

flipshot_compiled_tiles_file_name:
	.asciz	"flipshot\\flipshot.tls"

flipshot_tiles_usage_bitmap_file_name:
	.asciz	"flipshot\\flipshot.ubm"

flipshot_p1_rom_file_name:
	.asciz	"flipshot\\247-p1.p1"

flipshot_c1_rom_file_name:
	.asciz	"flipshot\\247-c1.c1"

flipshot_c2_rom_file_name:
	.asciz	"flipshot\\247-c2.c2"

.even

spinmast_info:
	dc.l	spinmast_game_name
	dc.l	spinmast_compiled_tiles_file_name,spinmast_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_3,spinmast_p1_rom_file_name,spinmast_p2_rom_file_name
	dc.l	0x800000
	dc.l	0x200000,spinmast_c1_rom_file_name,spinmast_c2_rom_file_name
	dc.l	0x200000,spinmast_c3_rom_file_name,spinmast_c4_rom_file_name
	dc.l	0x200000,spinmast_c5_rom_file_name,spinmast_c6_rom_file_name
	dc.l	0x200000,spinmast_c7_rom_file_name,spinmast_c8_rom_file_name

spinmast_game_name:
	.asciz	"Spin Master"

spinmast_compiled_tiles_file_name:
	.asciz	"spinmast\\spinmast.tls"

spinmast_tiles_usage_bitmap_file_name:
	.asciz	"spinmast\\spinmast.ubm"

spinmast_p1_rom_file_name:
	.asciz	"spinmast\\062-p1.p1"

spinmast_p2_rom_file_name:
	.asciz	"spinmast\\062-p2.sp2"

spinmast_c1_rom_file_name:
	.asciz	"spinmast\\062-c1.c1"

spinmast_c2_rom_file_name:
	.asciz	"spinmast\\062-c2.c2"

spinmast_c3_rom_file_name:
	.asciz	"spinmast\\062-c3.c3"

spinmast_c4_rom_file_name:
	.asciz	"spinmast\\062-c4.c4"

spinmast_c5_rom_file_name:
	.asciz	"spinmast\\062-c5.c5"

spinmast_c6_rom_file_name:
	.asciz	"spinmast\\062-c6.c6"

spinmast_c7_rom_file_name:
	.asciz	"spinmast\\062-c7.c7"

spinmast_c8_rom_file_name:
	.asciz	"spinmast\\062-c8.c8"

.even

bjourney_info:
	dc.l	bjourney_game_name
	dc.l	bjourney_compiled_tiles_file_name,bjourney_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,bjourney_p1_rom_file_name,0
	dc.l	0x300000
	dc.l	0x200000,bjourney_c1_rom_file_name,bjourney_c2_rom_file_name
	dc.l	0x100000,bjourney_c3_rom_file_name,bjourney_c4_rom_file_name

bjourney_game_name:
	.asciz	"Blue's Journey"

bjourney_compiled_tiles_file_name:
	.asciz	"bjourney\\bjourney.tls"

bjourney_tiles_usage_bitmap_file_name:
	.asciz	"bjourney\\bjourney.ubm"

bjourney_p1_rom_file_name:
	.asciz	"bjourney\\022-p1.p1"

bjourney_c1_rom_file_name:
	.asciz	"bjourney\\022-c1.c1"

bjourney_c2_rom_file_name:
	.asciz	"bjourney\\022-c2.c2"

bjourney_c3_rom_file_name:
	.asciz	"bjourney\\022-c3.c3"

bjourney_c4_rom_file_name:
	.asciz	"bjourney\\022-c4.c4"

.even

eightman_info:
	dc.l	eightman_game_name
	dc.l	eightman_compiled_tiles_file_name,eightman_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_1,eightman_p1_rom_file_name,0
	dc.l	0x300000
	dc.l	0x200000,eightman_c1_rom_file_name,eightman_c2_rom_file_name
	dc.l	0x100000,eightman_c3_rom_file_name,eightman_c4_rom_file_name

eightman_game_name:
	.asciz	"Eight Man"

eightman_compiled_tiles_file_name:
	.asciz	"eightman\\eightman.tls"

eightman_tiles_usage_bitmap_file_name:
	.asciz	"eightman\\eightman.ubm"

eightman_p1_rom_file_name:
	.asciz	"eightman\\025-p1.p1"

eightman_c1_rom_file_name:
	.asciz	"eightman\\025-c1.c1"

eightman_c2_rom_file_name:
	.asciz	"eightman\\025-c2.c2"

eightman_c3_rom_file_name:
	.asciz	"eightman\\025-c3.c3"

eightman_c4_rom_file_name:
	.asciz	"eightman\\025-c4.c4"

.even

fatfury1_info:
	dc.l	fatfury1_game_name
	dc.l	fatfury1_compiled_tiles_file_name,fatfury1_tiles_usage_bitmap_file_name
	dc.l	load_program_rom_4,fatfury1_p1_rom_file_name,fatfury1_p2_rom_file_name
	dc.l	0x400000
	dc.l	0x200000,fatfury1_c1_rom_file_name,fatfury1_c2_rom_file_name
	dc.l	0x200000,fatfury1_c3_rom_file_name,fatfury1_c4_rom_file_name

fatfury1_game_name:
	.asciz	"Fatal Fury - King of Fighters"

fatfury1_compiled_tiles_file_name:
	.asciz	"fatfury1\\fatfury1.tls"

fatfury1_tiles_usage_bitmap_file_name:
	.asciz	"fatfury1\\fatfury1.ubm"

fatfury1_p1_rom_file_name:
	.asciz	"fatfury1\\033-p1.p1"

fatfury1_p2_rom_file_name:
	.asciz	"fatfury1\\033-p2.p2"

fatfury1_c1_rom_file_name:
	.asciz	"fatfury1\\033-c1.c1"

fatfury1_c2_rom_file_name:
	.asciz	"fatfury1\\033-c2.c2"

fatfury1_c3_rom_file_name:
	.asciz	"fatfury1\\033-c3.c3"

fatfury1_c4_rom_file_name:
	.asciz	"fatfury1\\033-c4.c4"

.even

|-------------------------------------------------------------------------------

.bss

.end
