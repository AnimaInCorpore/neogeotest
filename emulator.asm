.global emulator
.global emulator_end

.equ	BREAKPOINT_ADDRESS,0xc11fb0
.equ	SCREEN_ADDRESS,0x600000+512*2*16
.equ	VRAM_ADDRESS,0x580000
.equ	SPRITE_INFOS_ADDRESS,VRAM_ADDRESS+0x20000
.equ	PALETTES_ADDRESS,SPRITE_INFOS_ADDRESS+0x2000
.equ	COMPILED_SPRITES_ADDRESS,PALETTES_ADDRESS+0x4000

.text

|-------------------------------------------------------------------------------
|
|	Emulator program. Relative addressing only!
|
|	d0.l = NeoGeo MMU table address.
|	a0.l = NeoGeo memory pages address.
|
|-------------------------------------------------------------------------------

emulator:
	move	#0x2700,sr

	lea		old_sp(pc),a1
	move.l	sp,(a1)																| Save the Atari stack pointer.

	| Set emulator exception/interrupt handlers (in the NeoGeo memory pages!).

	lea		bus_error_handler(pc),a1
	move.l	a1,0x8(a0)

	lea		trace_handler(pc),a1
	move.l	a1,0x24(a0)

	lea		hbl_handler(pc),a1
	move.l	a1,0x68(a0)

	lea		vbl_handler(pc),a1
	move.l	a1,0x70(a0)

	lea		ikbd_handler(pc),a1
	move.l	a1,0x118(a0)

	| Enable the NeoGeo mode.

	lea		mmu_data(pc),a0

	clr.l	(a0)
	pmove	(a0),tc																| Disable address translation.

	move.l	#0x80000002,(a0)
	move.l	d0,4(a0)
	pmove	(a0),crp															| Set the new MMU table address.

	move.l	#0x80f04445,(a0)
	pmove	(a0),tc																| Enable address translation.

	| Clear CPU caches.

	movec	cacr,d0
	bset	#11,d0
	bset	#3,d0
	movec	d0,cacr

	| Clear screen memory.

	lea		SCREEN_ADDRESS,a0
1:
	clr.l	(a0)+

	cmp.l	#SCREEN_ADDRESS+512*2*224,a0
	jlt		1b

	| Clear VRAM memory.

	lea		VRAM_ADDRESS,a0
1:
	clr.l	(a0)+

	cmp.l	#VRAM_ADDRESS+0x10000*2,a0
	jlt		1b

	| Set screen memory.

	move.l	#SCREEN_ADDRESS,d0
|	move.l	#VRAM_ADDRESS,d0
	swap	d0
	move.b	d0,0x8201.w
	swap	d0
	move	d0,d1
	ror		#8,d0
	move.b	d0,0x8203.w
	move.b	d1,0x820d.w

	| Start the emulation.

|	lea		0x10F300,sp															| Set the initial NeoGeo stack pointer.
	lea		emulator_end(pc),sp
	add.l	#0x4000*4,sp														| The NeoGeo stack pointer is not usable because the BIOS RAM check fails while the trace and bus error exceptions are active.
	jbra	0xc00402															| Call NeoGeo BIOS init routine.

|-------------------------------------------------------------------------------

emulator_exit:
	move	#0x2700,sr

	| Restore the Atari mode.

	lea		mmu_data(pc),a0

	clr.l	(a0)
	pmove	(a0),tc																| Disable address translation.

	move.l	#0x80000002,(a0)
	move.l	#0x00000700,4(a0)
	pmove	(a0),crp															| Restore the Atari MMU table address.

	move.l	#0x80f04445,(a0)
	pmove	(a0),tc																| Enable address translation.

	| Clear CPU caches.

	movec	cacr,d0
	bset	#11,d0
	bset	#3,d0
	movec	d0,cacr

	move.l	old_sp(pc),sp														| Restore the Atari stack pointer.

	rts

old_sp:
	ds.l	1

mmu_data:
	ds.l	2

|-------------------------------------------------------------------------------
|
|	Bus error handler.
|
|-------------------------------------------------------------------------------

bus_error_handler:
	move	#0x2700,sr
|	move.l	#0x000000ff,0x9800.w

	movem.l	d0-a6,-(sp)

	move.l	15*4+0x10(sp),d0													| Access address.
	move	15*4+0xa(sp),d1														| "Special Status Word".

	| REG_VRAMADDR.

	cmp.l	#0x3c0000,d0
	jne		2f

	btst	#6,d1																| Read access?
	jne		1f

	lea		vram_address(pc),a0
	move.l	15*4+0x18(sp),d0

	and		#0x0030,d1															| Check for long data size write access.
	jne		4f

|	move	#0b0000000000011111,d2
|	jbsr	write_long_data
|	jbsr	write_space
|	jbsr	write_new_line

	swap	d0
	move	d0,(a0)																| Write (word sized) data to REG_VRAMADDR.

	jra		5f
4:
|	move	#0b0000000000011111,d2
|	jbsr	write_word_data
|	jbsr	write_space
|	jbsr	write_new_line

	move	d0,(a0)																| Write (word sized) data to REG_VRAMADDR.

	jra		3f
1:
	move	vram_address(pc),15*4+0x2c+0x2(sp)									| Read (word sized) data from REG_VRAMADDR.

	jra		3f
2:
	| REG_VRAMRW.

	cmp.l	#0x3c0002,d0
	jne		2f

	btst	#6,d1																| Read access?
	jne		1f

|	move.l	#0x00ff0000,0x9800.w

	lea		vram_address(pc),a0
	move	(a0),d0
5:
	lea		VRAM_ADDRESS,a1
	clr.l	d1
	move	d0,d1
	move	15*4+0x18+0x2(sp),(a1,d1.l*2)										| Write (word sized) data to REG_VRAMRW.

|	move	#0xffff,d2
|	jbsr	write_word_data
|	jbsr	write_space

	lea		vram_increment(pc),a1
	add		(a1),d0
	move	d0,(a0)

|	move	15*4+0x18+0x2(sp),d0
|	jbsr	write_word_data
|	jbsr	write_space
|	jbsr	write_new_line

	jra		3f
1:
	lea		vram_address(pc),a0
	move	(a0),d0

	lea		VRAM_ADDRESS,a1
	clr.l	d1
	move	d0,d1
	move	(a1,d1.l*2),15*4+0x2c+0x2(sp)										| Read (word sized) data from REG_VRAMRW.

	jra		3f
2:
	| REG_VRAMMOD.

	cmp.l	#0x3c0004,d0
	jne		2f

	btst	#6,d1																| Read access?
	jne		1f

	lea		vram_increment(pc),a0
	move	15*4+0x18+0x2(sp),(a0)												| Write (word sized) data to REG_VRAMMOD.

	jra		3f
1:
	move	vram_increment(pc),15*4+0x2c+0x2(sp)								| Read (word sized) data from REG_VRAMMOD.

	jra		3f
2:
	| REG_DIPSW (write = kick watchdog).

	cmp.l	#0x300001,d0
	jne		2f

	cmp.b	#0x01,0xfc02.w
	jeq		emulator_exit

	cmp.b	#0x39,0xfc02.w
	jeq		1f

	lea		sprite_draw_counter(pc),a0
	move	(a0),d0
	and		#0x7,d0
	jne		1f

	jbsr	draw_dummy_sprites
	addq	#1,(a0)
1:
	move.b	#0xff,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_DIPSW.

	jra		3f
2:
	| REG_SOUND.

	cmp.l	#0x320000,d0
	jne		2f

	btst	#6,d1																| Read access?
	jne		1f

|	move	15*4+0x18+0x2(sp),(a0)												| Write (byte sized) data to REG_SOUND.

	jra		3f
1:
	move.b	#0x01,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_SOUND.

	jra		3f
2:
	| REG_P1CNT.

	cmp.l	#0x300000,d0
	jne		2f

	move.b	#0xff,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_P1CNT.

	jra		3f
2:
	| REG_P2CNT.

	cmp.l	#0x340000,d0
	jne		2f

	move.b	#0xff,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_P2CNT.

	jra		3f
2:
	| REG_STATUS_A.

	cmp.l	#0x320001,d0
	jne		2f

	lea		reg_status_a_counter(pc),a0
	eor		#0x0040,(a0)
|	move.b	#0x3d,0x10fee4

	move.b	1(a0),15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_STATUS_A.

	jra		3f
2:
	| REG_STATUS_B.

	cmp.l	#0x380000,d0
	jne		2f

	move.b	#0xff,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_STATUS_B.

	jra		3f
2:
	| REG_SWPBIOS.

	cmp.l	#0x3a0003,d0
	jne		2f

	lea		use_cartridge_vector_table(pc),a0
	clr		(a0)

	jra		3f
2:
	| REG_SWPROM.

	cmp.l	#0x3a0013,d0
	jne		2f

	lea		use_cartridge_vector_table(pc),a0
	move	#-1,(a0)

	jra		3f
2:
	| REG_300081.

	cmp.l	#0x300081,d0
	jne		2f

	move.b	#0x80,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_300081.

	jra		3f
2:
	| Write unhandled access addresses on screen.

|	move.l	#0xff000000,0x9800.w

	jra		3f

	move	#0b0000011111100000,d2												| Red access = green color.

	btst	#6,d1																| Read access?
	jne		1f

	move	#0b1111100000000000,d2												| Write access = red color.
1:
	move.l	15*4+0x2(sp),d0
	jbsr	write_long_data

	jbsr	write_space

	move.l	15*4+0x10(sp),d0
	jbsr	write_long_data

	jbsr	write_space

	move	15*4+0xa(sp),d0
	jbsr	write_word_data

	jbsr	write_space
	jbsr	write_new_line

	and		#0xf000,d1
	jeq		3f
1:
	cmp.b	#0x01,0xfc02.w
	jne		1b
	jbra	emulator_exit
3:
	movem.l	(sp)+,d0-a6

|	or		#0x8000,(sp)														| Reenable tracing.
	bclr	#8,0xa(sp)															| Data fault processed.

|	clr.l	0x9800.w

	rte

vram_address:
	ds.w	1

vram_increment:
	ds.w	1

use_cartridge_vector_table:
	ds.w	1

reg_status_a_counter:
	dc.w	0x007f

sprite_draw_counter:
	ds.w	1

|-------------------------------------------------------------------------------
|
|	Draw dummy sprites.
|
|-------------------------------------------------------------------------------

draw_dummy_sprites:
	movem.l	d0-a6,-(sp)

	lea		VRAM_ADDRESS+0x8200*2,a0
	lea		SCREEN_ADDRESS-512*2*16,a1

	clr		d4 | Previous sprite height.
	clr		d5 | Previous sprite X position.
	clr		d6 | Previous sprite Y position.

	move	#448-1,d7
1:
	move	0x200*2(a0),d0 | Sprite X position.
	move	(a0)+,d1 | Sprite Y position + sticky bit + height.

	btst	#6,d1 | Check sticky bit.
	jeq		3f

	move	d4,d3 | Use previous height.
	jeq		2f | Avoid having 0 as the height.

	add		#16,d5
	move	d5,d0 | Use previous X position + 16.

	move	d6,d2 | use previous Y position.

	jra		4f
3:
	move	d1,d3
	and		#0x3f,d3 | Sprite height.
	move	d3,d4 | Save sprite height.
	jeq		2f

	lsr		#7,d1
	move	#512,d2
	sub		d1,d2
	move	d2,d6 | Save Y position.

	lsr		#7,d0
	move	d0,d5 | Save X position.
4:
	| Check sprite X position boundaries.

	cmp		#320,d0 | Right screen border.
	jlt		6f

	sub		#512,d0

	cmp		#-16,d0 | Left screen border.
	jle		2f
6:
	| Calculate sprite screen address.

	swap	d2
	clr		d2
	lsr.l	#7,d2
	ext.l	d0
	add.l	d0,d2
	lea		(a1,d2.l*2),a2

	subq	#1,d3
3:
	move.l	a2,a3

	cmp.l	#SCREEN_ADDRESS+512*2*224,a3
	jlt		4f

	sub.l	#512*2*512,a3

	cmp.l	#SCREEN_ADDRESS-512*2*16,a3
	jle		5f
4:
	movem.l	d0-a0,-(sp)

	move	d7,d0
	add		d3,d0
	lsl		#3,d0
	move.l	#512*2,a0

.rept 16
	move	d0,(a3)+
.endr

	lea		-16*2(a3),a3
	movem.l	(a3),d0-d7
	add.l	a0,a3

.rept 16-1
	movem.l	d0-d7,(a3)
	add.l	a0,a3
.endr

	movem.l	(sp)+,d0-a0
5:
	add.l	#512*2*16,a2

	dbf		d3,3b
2:
	dbf		d7,1b

	movem.l	(sp)+,d0-a6

	rts

|-------------------------------------------------------------------------------
|
|	Draw sprites.
|
|-------------------------------------------------------------------------------

draw_sprites:
	lea		SPRITE_INFOS_ADDRESS,a1
1:
	move.l	(a1)+,d0															| Palette address.
	jeq		2f

	move.l	d0,a2
	move.l	(a1)+,a6															| Screen address.
	move.l	(a1)+,d0															| Sprite drawing code address.
	lea		3f(pc),a0															| Return address.
	movem.l	d0/a0-a1,-(sp)
	movem.l	(a2),d0-a5															| Load palette colors.
	rts																			| Jump to sprite drawing code.
3:
	move.l	(sp)+,a1
	jbra	1b
2:

|-------------------------------------------------------------------------------
|
|	Build sprite infos.
|
|	Each entry consists of the palette address, the screen address and the drawing address.
|
|-------------------------------------------------------------------------------

build_sprite_infos:
	movem.l	d0-a6,-(sp)

	lea		VRAM_ADDRESS+0x8200*2,a0											| Sprite Y positions + sticky bit + height.
	lea		VRAM_ADDRESS,a2														| Sprite tilemaps.

	lea		SPRITE_INFOS_ADDRESS,a3												| Converted sprite infos.
	lea		COMPILED_SPRITES_ADDRESS,a4											| Compiled sprites.
	lea		SCREEN_ADDRESS,a5													| Screen address.
	lea		PALETTES_ADDRESS,a6													| Palettes address.

	clr		d0 																	| Sprite counter.
	clr		d4 																	| Previous sprite height.
	clr		d5 																	| Previous sprite X position.
	clr		d6 																	| Previous sprite Y position.
1:
	move	0x200*2(a0),d7 														| Sprite X position.
	move	(a0)+,d1 															| Sprite Y position + sticky bit + height.

	btst	#6,d1 																| Check sticky bit.
	jeq		3f

	add		#16,d5
	move	d5,d7 																| Use previous X position + 16.
	move	d6,d2 																| use previous Y position.
	move	d4,d3 																| Use previous height.
	jeq		2f 																	| Avoid having 0 as the height.

	jra		4f
3:
	move	d1,d3
	and		#0x3f,d3 															| Sprite height.
	move	d3,d4 																| Save sprite height.
	jeq		2f

	lsr		#7,d1
	move	#496,d2
	sub		d1,d2
	move	d2,d6 																| Save Y position.

	lsr		#7,d7
	move	d7,d5 																| Save X position.
4:
	| Check sprite X position boundaries.


	cmp		#320,d7 															| Right screen border.
	jlt		6f

	sub		#512,d7

	cmp		#-16,d7 															| Left screen border.
	jle		2f
6:
	| Calculate sprite screen address.

	swap	d2
	clr		d2
	lsr.l	#7,d2
	ext.l	d7
	add.l	d7,d2
	lea		(a2,d2.l*2),a3

	subq	#1,d3
3:
	cmp.l	#SCREEN_ADDRESS+512*2*256,a3
	jlt		4f

	sub.l	#512*2*512,a3
4:
	cmp.l	#SCREEN_ADDRESS-512*2*16,a3
	jgt		4f

	add.l	#512*2*16,a3
	jra		5f
4:
	cmp.l	#SCREEN_ADDRESS+512*2*224,a3
	jlt		4f

	add.l	#512*2*16,a3
	jra		5f
4:



	movem.l	d0-d2/a0,-(sp)

	movem.l	(sp)+,d0-d2/a0




5:
	dbf		d3,3b
2:
	lea		32*2*2(a2),a2

	addq	#1,d0
	cmp		#448,d0
	jne		1b

	movem.l	(sp)+,d0-a6

	rts

highest_tilemap:
	ds.l	1

|-------------------------------------------------------------------------------
|
|	Trace handler.
|
|-------------------------------------------------------------------------------

trace_handler:
	cmp.b	#0x01,0xfc02.w
	jeq		emulator_exit

	cmp.l	#BREAKPOINT_ADDRESS,0x8(sp)
	jeq		2f

	cmp.b	#0x39,0xfc02.w
	jne		1f
2:
	movem.l	d0-a6,-(sp)

	move	#0xffff,d2

	move.l	15*4+0x8(sp),d0
	jbsr	write_long_data

	jbsr	write_space

	move.l	d0,a0
	move	(a0),d0
	jbsr	write_word_data

	jbsr	write_space

	move	2(a0),d0
	jbsr	write_word_data

	jbsr	write_space

	move	4(a0),d0
	jbsr	write_word_data

	jbsr	write_space

	move.l	15*4+0xc(sp),d0
	jbsr	write_long_data

	jbsr	write_space
	jbsr	write_new_line

	clr		d1

	move	#4-1,d7
2:
	move	#4-1,d6
3:
	move.l	(sp,d1.w*4),d0
	jbsr	write_long_data

	jbsr	write_space

	addq	#1,d1

	dbf		d6,3b

	jbsr	write_new_line

	dbf		d7,2b

	jbsr	write_home

	movem.l	(sp)+,d0-a6
1:
	cmp.l	#BREAKPOINT_ADDRESS,0x8(sp)
	jne		2f
1:
	cmp.b	#0x39,0xfc02.w
	jne		1b
2:
	rte

|-------------------------------------------------------------------------------
|
|	HBL interrupt handler.
|
|-------------------------------------------------------------------------------

hbl_handler:
|	not.l	0x9800.w

	or		#0x0300,(sp)														| Disable HBL interrupts.

	rte

|-------------------------------------------------------------------------------
|
|	VBL interrupt handler.
|
|-------------------------------------------------------------------------------

vbl_handler:
	move.l	a0,-(sp)

	lea		sprite_draw_counter(pc),a0
	addq	#1,(a0)

	move.l	(sp)+,a0

	tst		use_cartridge_vector_table(pc)
	jne		1f

	jmp		0xc00438															| Jump to the BIOS VBL routine.
1:
	move.l	0x64.w,-(sp)														| Jump to the cartridge VBL routine.

	rts

|-------------------------------------------------------------------------------
|
|	IKBD interrupt handler.
|
|-------------------------------------------------------------------------------

ikbd_handler:
|	cmp.b	#0x01,0xfc02.w
|	jeq		emulator_exit

	rte

|-------------------------------------------------------------------------------
|
|	Write space.
|
|-------------------------------------------------------------------------------

write_space:
	movem.l	d0-a6,-(sp)

	move.l	write_display_address(pc),a0

	move	#8-1,d7
1:
	move	#8-1,d6
2:
	clr		(a0)+

	dbf		d6,2b

	lea		512*2-8*2(a0),a0

	dbf		d7,1b

	lea		-512*2*8+8*2(a0),a0

	lea		write_display_address(pc),a1
	move.l	a0,(a1)

	movem.l	(sp)+,d0-a6

	rts

|-------------------------------------------------------------------------------
|
|	Write new line.
|
|-------------------------------------------------------------------------------

write_new_line:
	movem.l	d0-a6,-(sp)

	lea		write_display_address(pc),a0

	move.l	(a0),d0
	add.l	#512*2*8,d0
	and.l	#0xffffe000,d0

	cmp.l	#SCREEN_ADDRESS+512*2*224,d0
	jlt		1f

	move.l	#SCREEN_ADDRESS,d0
1:
	move.l	d0,(a0)

	movem.l	(sp)+,d0-a6

	rts

|-------------------------------------------------------------------------------
|
|	Write home.
|
|-------------------------------------------------------------------------------

write_home:
	movem.l	d0-a6,-(sp)

	lea		write_display_address(pc),a0
	move.l	#SCREEN_ADDRESS,(a0)

	movem.l	(sp)+,d0-a6

	rts

|-------------------------------------------------------------------------------
|
|	Write byte data.
|
|	d0.b = data to be written.
|	d2.w = 16 bit RGB text color.
|
|-------------------------------------------------------------------------------

write_byte_data:
	movem.l	d0-d1,-(sp)

	swap	d0
	lsl.l	#8,d0
	move	#2,d1
	jbsr	write_data

	movem.l	(sp)+,d0-d1

	rts

|-------------------------------------------------------------------------------
|
|	Write word data.
|
|	d0.w = data to be written.
|	d2.w = 16 bit RGB text color.
|
|-------------------------------------------------------------------------------

write_word_data:
	movem.l	d0-d1,-(sp)

	swap	d0
	move	#4,d1
	jbsr	write_data

	movem.l	(sp)+,d0-d1

	rts

|-------------------------------------------------------------------------------
|
|	Write long data.
|
|	d0.l = data to be written.
|	d2.w = 16 bit RGB text color.
|
|-------------------------------------------------------------------------------

write_long_data:
	movem.l	d0-d1,-(sp)

	move	#8,d1
	jbsr	write_data

	movem.l	(sp)+,d0-d1

	rts


|-------------------------------------------------------------------------------
|
|	Write data.
|
|	d0.l = data to be written.
|	d1.l = number of characters of the data to be written.
|	d2.w = 16 bit RGB text color.
|
|-------------------------------------------------------------------------------

write_data:
	movem.l	d0-a6,-(sp)

	move	d2,d4

	move.l	write_display_address(pc),a0
	lea		character_bitmaps(pc),a1

	move	d1,d7
	subq	#1,d7
1:
	rol.l	#4,d0
	move	d0,d1
	and		#0xf,d1

	move.l	a1,a2

	move	#8-1,d6
2:
	move.b	(a2,d1.w*8),d2

	move	#8-1,d5
3:
	add.b	d2,d2
	scs		d3
	ext		d3
	and		d4,d3
	move	d3,(a0)+

	dbf		d5,3b

	lea		512*2-8*2(a0),a0
	addq	#1,a2

	dbf		d6,2b

	lea		-512*2*8+8*2(a0),a0

	dbf		d7,1b

	lea		write_display_address(pc),a1
	move.l	a0,(a1)

	movem.l	(sp)+,d0-a6

	rts

write_display_address:
	dc.l	SCREEN_ADDRESS

character_bitmaps:
	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00011000
	dc.b	0b00111000
	dc.b	0b00011000
	dc.b	0b00011000
	dc.b	0b00011000
	dc.b	0b01111110
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b00001100
	dc.b	0b00011000
	dc.b	0b00110000
	dc.b	0b01111110
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b00001100
	dc.b	0b00000110
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00001100
	dc.b	0b00011100
	dc.b	0b00111100
	dc.b	0b01101100
	dc.b	0b01111110
	dc.b	0b00001100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b01111110
	dc.b	0b01100000
	dc.b	0b01111100
	dc.b	0b00000110
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100000
	dc.b	0b01111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b01111110
	dc.b	0b00000110
	dc.b	0b00001100
	dc.b	0b00011000
	dc.b	0b00110000
	dc.b	0b00110000
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b00111110
	dc.b	0b00000110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01111110
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b01111100
	dc.b	0b01100110
	dc.b	0b01111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b00111100
	dc.b	0b01100110
	dc.b	0b01100000
	dc.b	0b01100000
	dc.b	0b01100110
	dc.b	0b00111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b01111100
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01100110
	dc.b	0b01111100
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b01111110
	dc.b	0b01100000
	dc.b	0b01111100
	dc.b	0b01100000
	dc.b	0b01100000
	dc.b	0b01111110
	dc.b	0b00000000

	dc.b	0b00000000
	dc.b	0b01111110
	dc.b	0b01100000
	dc.b	0b01111100
	dc.b	0b01100000
	dc.b	0b01100000
	dc.b	0b01100000
	dc.b	0b00000000

emulator_end:

.end
