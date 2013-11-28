.include "../gemdos.asm"

.include "../defines.asm"

.global compile_tiles

.text

|-------------------------------------------------------------------------------
|
|	Compile tiles.
|
|-------------------------------------------------------------------------------

compile_tiles:
	Cconws	loading_compiled_tiles_text

	| Load compiled tiles.

	move.l	mslug_info,a0
	Fopen	(a0),#0
	move	d0,d7
	jmi		1f

	Fread	d7,#0x500000,COMPILED_TILES_ADDRESS
	Fclose	d7

	rts
1:
	Cconws	compiling_tiles_text

	| Compiling preparation.

	lea		COMPILED_TILES_ADDRESS,a0
	move.l	mslug_info+4,d1														| Tiles ROM size.
	lsr.l	#7,d1																| Max. tile ROM index = tiles ROM size / (16 * 8).
	lsl.l	#2,d1																| Max. compiled tiles index = max. tile ROM index * 4.
	move.l	d1,max_compiled_tiles_index
	lsl.l	#2,d1																| Max. compiled tiles index = max. compiled tiles index * 4.
	add.l	a0,d1
	move.l	d1,a1																| Compiled tiles code address.

	clr.l	d0																	| Current compiled tile index.
1:
	| Check if the tile ROM buffer needs to be refreshed.

	move.l	d0,d1
	lsl.l	#4+3-2,d1															| Work tile ROM offset = (Compiled tile index * 16 * 8 / 4) % 0x10000.
	and.l	#0xffffff80,d1														| Mask out the bits for horizontal and vertical flip.
	tst		d1
	jne		2f

	movem.l	d0/a0-a1,-(sp)

	and.l	#0x00030000,d1
	jne		5f

	Cconws	progress_text
5:
	clr.l	d0
	lea		mslug_info+2*4,a0
4:
	move.l	d0,d2
	add.l	(a0)+,d0
	cmp.l	d0,d1
	jlt		5f

	addq.l	#8,a0
	jra		4b
5:
	| Refresh tiles ROM buffers.

	move.l	(a0)+,a5															| Odd tiles ROM filename.
	move.l	(a0)+,a6															| Even tiles ROM filename.
	move.l	d1,d6
	sub.l	d2,d6
	lsr.l	#1,d6																| Tiles ROM seek position.

	Fopen	(a5),#0
	move	d0,d7
	Fseek	d6,d7,#0
	Fread	d7,#0x8000,odd_tiles_rom_buffer
	Fclose	d7

	Fopen	(a6),#0
	move	d0,d7
	Fseek	d6,d7,#0
	Fread	d7,#0x8000,even_tiles_rom_buffer
	Fclose	d7

	| Reorder tiles ROM buffers.

	lea		odd_tiles_rom_buffer,a0
	lea		even_tiles_rom_buffer,a1
	lea		tiles_rom_buffer,a2
	move.l	a2,a3
	add.l	#0x10000,a3
4:
	move.b	(a0)+,(a2)+
	move.b	(a1)+,(a2)+

	cmp.l	a3,a2
	jlt		4b

	movem.l	(sp)+,d0/a0-a1
2:
	| Check if tile is in use.

	lea		TILES_USAGE_BITMAP,a2

	move.l	d0,d1
	and		#0x7,d1
	move	#0x80,d2
	lsr		d1,d2

	move.l	d0,d1
	lsr.l	#3,d1
	and.b	(a2,d1.l),d2
	jne		2f

	clr.l	(a0)+																| Unused tiles are stored as NULL addresses for the code.

	jra		3f
2:
	| Decode tile.

	movem.l	d0/a0-a1,-(sp)

	lea		tiles_rom_buffer,a0
	lea		tile_pixels_buffer+16,a1

	move.l	d0,d1
	lsl.l	#4+3-2,d1															| Tile ROM offset = Compiled tile index * 16 * 8 / 4.
	and.l	#0x0000ff80,d1														| Mask out the bits for horizontal and vertical flip and keep the index within the buffer.
	add.l	d1,a0

	| Block #1.

	move	#8-1,d6
7:
	move.b	(a0)+,d3
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.b	(a0)+,d0

	move	#8-1,d5
8:
	clr		d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	move.b	d4,-(a1)

	dbf		d5,8b

	lea		16+8(a1),a1

	dbf		d6,7b

	| Block #2.

	move	#8-1,d6
7:
	move.b	(a0)+,d3
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.b	(a0)+,d0

	move	#8-1,d5
8:
	clr		d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	move.b	d4,-(a1)

	dbf		d5,8b

	lea		16+8(a1),a1

	dbf		d6,7b

	sub.l	#16*16+8,a1

	| Block #3.

	move	#8-1,d6
7:
	move.b	(a0)+,d3
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.b	(a0)+,d0

	move	#8-1,d5
8:
	clr		d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	move.b	d4,-(a1)

	dbf		d5,8b

	lea		16+8(a1),a1

	dbf		d6,7b

	| Block #4.

	move	#8-1,d6
7:
	move.b	(a0)+,d3
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.b	(a0)+,d0

	move	#8-1,d5
8:
	clr		d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	move.b	d4,-(a1)

	dbf		d5,8b

	lea		16+8(a1),a1

	dbf		d6,7b

	movem.l	(sp)+,d0/a0-a1

	| Flip tile.

	movem.l	d0/a0-a1,-(sp)

	btst	#0,d0																| Horizontal flip?
	jeq		4f

	lea		tile_pixels_buffer,a0
	lea		16(a0),a1

	move	#16-1,d7
5:
	move	#8-1,d6
6:
	move.b	(a0),d1
	move.b	-(a1),(a0)+
	move.b	d1,(a1)

	dbf		d6,6b

	addq	#16-8,a0
	add		#16+8,a1

	dbf		d7,5b
4:
	btst	#1,d0																| Vertical flip?
	jeq		4f

	lea		tile_pixels_buffer,a0
	lea		15*16(a0),a1

	move	#8-1,d7
5:
	move.l	(a0),d1
	move.l	(a1),(a0)+
	move.l	d1,(a1)+

	move.l	(a0),d1
	move.l	(a1),(a0)+
	move.l	d1,(a1)+

	move.l	(a0),d1
	move.l	(a1),(a0)+
	move.l	d1,(a1)+

	move.l	(a0),d1
	move.l	(a1),(a0)+
	move.l	d1,(a1)+

	sub		#16*2,a1

	dbf		d7,5b
4:
	movem.l	(sp)+,d0/a0-a1

	| Compile tile.

	move.l	a1,(a0)+

	movem.l	d0/a0,-(sp)

	lea		tile_pixels_buffer,a0

	clr		d0																	| Pixel color value.
	clr		d1																	| Offset counter.
	clr		d2																	| Current color flag for d0.

	move	#16-1,d7
4:
	move	#16-1,d6
5:
	move.b	(a0)+,d0
	jne		6f

	addq	#2,d1																| A transparent pixel increments the offset counter by 2.

	jra		8f
6:
	tst		d1																	| Is the offset counter greater than 0?
	jeq		6f

	cmp		#8,d1																| Check if "addq" can be used.
	jle		7f

	move	#0xdcfc,(a1)+														| "adda.w #x,a6".
	move	d1,(a1)+															| "x".

	jra		6f
7:
	and		#0x7,d1
	lsl		#8,d1
	add		d1,d1
	add		#0x504e,d1															| "addq.w #x,a6".
	move	d1,(a1)+
6:
	clr		d1

	cmp		#14,d0
	seq		d4
	cmp		#15,d0
	seq		d5
	cmp.b	d4,d5																| Color #14 or #15?
	jeq		7f

	cmp.b	d5,d2																| Was the last color in d0 the same like the current one?
	jeq		7f

	move	#0x4840,(a1)+														| "swap d0".
	move.b	d5,d2
7:
	cmp		#14,d0																| Use word moves only for d0 (color #14 and #15).
	jlt		6f

	move	#0x3cc0,(a1)+														| "move.w d0,(a6)+".

	jra		8f
6:
	move	#0x3cc0-1,d4														| "move.w dx,(a6)+".
	add		d0,d4																| "x".

	cmp		-2(a1),d4															| Is the last opcode also "move.w dx,(a6)+"? This is legit because the value can never be written by the "add" above!
	jne		6f

	sub		#0x1000,d4															| Convert the current opcode to "move.l dx,(a6)+".
	subq	#2,a1
6:
	move	d4,(a1)+
8:
	dbf		d6,5b

	add		#(512-16)*2,d1														| Increase the offset to the next line.

	dbf		d7,4b

	move	#0x4e75,(a1)+														| "rts".

	movem.l	(sp)+,d0/a0




3:
	addq.l	#4,d0
	cmp.l	max_compiled_tiles_index,d0
	jlt		1b

	movem.l	a0-a1,-(sp)

	Cconws	saving_compiled_tiles_text

	movem.l	(sp)+,a0-a1

	| Save compiled tiles.

	move.l	a1,d6
	sub.l	#COMPILED_TILES_ADDRESS,d6

	move.l	mslug_info,a0
	Fcreate	(a0),#0
	move	d0,d7

	Fwrite	d7,d6,COMPILED_TILES_ADDRESS

	Fclose	d7

	rts

|-------------------------------------------------------------------------------

.data

mslug_info:
	dc.l	mslug_compiled_tiles_file_name										| Compiled tiles file name.
	dc.l	0x1000000															| Total tiles ROM size.
	dc.l	0x800000,mslug_c1_rom_file_name,mslug_c2_rom_file_name
	dc.l	0x800000,mslug_c3_rom_file_name,mslug_c4_rom_file_name

loading_compiled_tiles_text:
	.asciz	"Loading compiled tiles...\r\n"

compiling_tiles_text:
	.asciz	"Compiled tiles file not found.\r\nCompiling tiles"

progress_text:
	.asciz	"."

saving_compiled_tiles_text:
	.asciz	"\r\nSaving compiled tiles...\r\n"

mslug_compiled_tiles_file_name:
	.asciz	"mslug.tls"

mslug_c1_rom_file_name:
	.asciz	"201-c1.c1"

mslug_c2_rom_file_name:
	.asciz	"201-c2.c2"

mslug_c3_rom_file_name:
	.asciz	"201-c3.c3"

mslug_c4_rom_file_name:
	.asciz	"201-c4.c4"

.even

|-------------------------------------------------------------------------------

.bss

max_compiled_tiles_index:
	ds.l	1

tile_pixels_buffer:
	ds.b	16*16

tiles_rom_buffer:
	ds.b	0x10000

odd_tiles_rom_buffer:
	ds.b	0x8000

even_tiles_rom_buffer:
	ds.b	0x8000

.end
