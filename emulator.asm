.include "../defines.asm"

.global emulator
.global emulator_end

.equ	BREAKPOINT_ADDRESS,0xc11fb0

.equ	SSW_OFFSET,0xa
.equ	ACCESS_ADDRESS_OFFSET,0x10
.equ	DATA_TO_BE_WRITTEN_OFFSET,0x18
.equ	DATA_TO_BE_READ_OFFSET,0x2c

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

	lea		old_tt0(pc),a0
	pmove	tt0,(a0)															| Save old transparent translation #0.

	lea		old_tt1(pc),a0
	pmove	tt1,(a0)															| Save old transparent translation #1.

	lea		mmu_data(pc),a0

	clr.l	(a0)
	pmove	(a0),tc																| Disable address translation.
	pmove	(a0),tt0															| Disable transparent translation #0.
	pmove	(a0),tt1															| Disable transparent translation #1.

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

	| Prepare palette decoder table.

	lea		PALETTE_DECODER_TABLE,a0

	clr		d0
1:
	move	d0,d1
	and		#0b0000000000001111,d1
	lsl		#1,d1

	move	d0,d4
	and		#0b0001000000000000,d4
	rol		#4,d4
	or		d4,d1

	move	d0,d2
	and		#0b0000000011110000,d2
	lsl		#3,d2

	move	d0,d4
	and		#0b0010000000000000,d4
	lsr		#6,d4
	or		d4,d2

	move	d0,d3
	and		#0b0000111100000000,d3
	lsl		#4,d3

	move	d0,d4
	and		#0b0100000000000000,d4
	lsr		#3,d4
	or		d4,d3

	or		d2,d1
	or		d3,d1
	move	d1,(a0)+

	addq	#1,d0
	jne		1b

	| Clear screen memory.

	lea		SCREEN_ADDRESS,a0
1:
	clr.l	(a0)+

	cmp.l	#SCREEN_ADDRESS_2+512*2*(224+16+16),a0
	jlt		1b

	| Clear VRAM memory.

	lea		VRAM_ADDRESS,a0
1:
	clr.l	(a0)+

	cmp.l	#VRAM_ADDRESS+0x10000*2,a0
	jlt		1b

	| Set screen memory.

	move.l	#SCREEN_ADDRESS_2+512*2*16+8*2,d0
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
	jra		0xc00402															| Call NeoGeo BIOS init routine.

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

	lea		old_tt0(pc),a0
	pmove	(a0),tt0															| Restore old transparent translation #0.

	lea		old_tt1(pc),a0
	pmove	(a0),tt1															| Restore old transparent translation #1.

	lea		mmu_data(pc),a0
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

old_tt0:
	ds.l	1

old_tt1:
	ds.l	1

mmu_data:
	ds.l	2

|-------------------------------------------------------------------------------
|
|	Bus error handler.
|
|-------------------------------------------------------------------------------

bus_error_handler:
|	not.l	0x9800.w

	move	#0x2700,sr

	bclr	#8,SSW_OFFSET(sp)													| Data fault processed.
|	or		#0x8000,(sp)														| Reenable tracing.

	| REG_VRAMADDR, REG_VRAMRW, REG_VRAMMOD, REG_LSPCMODE, REG_TIMERHIGH, REG_TIMERLOW, REG_IRQACK, REG_TIMERSTOP.

	cmp		#0x003c,ACCESS_ADDRESS_OFFSET(sp)
	jne		1f

	| REG_VRAMADDR.

	tst		ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	movem.l	d0-d1/a0-a1,-(sp)

	move	4*4+SSW_OFFSET(sp),d0												| "Special Status Word".

	lea		vram_address(pc),a0

	btst	#6,d0																| Read access?
	jne		3f

	move.l	4*4+DATA_TO_BE_WRITTEN_OFFSET(sp),d1

	and		#0x0030,d0															| Check for long data size write access.
	jne		4f

	lea		VRAM_ADDRESS,a1
	clr.l	d0
	swap	d1
	move	d1,d0
	swap	d1
	move	d1,(a1,d0.l*2)														| Write (word sized) data to REG_VRAMRW.
	swap	d1

	lea		vram_increment(pc),a1
	add		(a1),d1
4:
	move	d1,(a0)																| Write (word sized) data to REG_VRAMADDR.

	movem.l	(sp)+,d0-d1/a0-a1

	rte
3:
	move	(a0),4*4+DATA_TO_BE_READ_OFFSET+2(sp)								| Read (word sized) data from REG_VRAMADDR.

	movem.l	(sp)+,d0-d1/a0-a1

	rte
2:
	| REG_VRAMRW.

	cmp		#0x0002,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	movem.l	d0-d1/a0-a1,-(sp)

	lea		vram_address(pc),a0
	move	(a0),d1

	lea		VRAM_ADDRESS,a1

	btst	#6,4*4+SSW_OFFSET+1(sp)												| Read access?
	jne		3f

	clr.l	d0
	move	d1,d0
	move	4*4+DATA_TO_BE_WRITTEN_OFFSET+2(sp),(a1,d0.l*2)						| Write (word sized) data to REG_VRAMRW.

	lea		vram_increment(pc),a1
	add		(a1),d1
	move	d1,(a0)

	movem.l	(sp)+,d0-d1/a0-a1

	rte
3:
	clr.l	d0
	move	d1,d0
	move	(a1,d0.l*2),4*4+DATA_TO_BE_READ_OFFSET+2(sp)						| Read (word sized) data from REG_VRAMRW.

	movem.l	(sp)+,d0-d1/a0-a1

	rte
2:
	| REG_VRAMMOD.

	cmp		#0x0004,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	btst	#6,SSW_OFFSET+1(sp)													| Read access?
	jne		3f

	move.l	a0,-(sp)

	lea		vram_increment(pc),a0
	move	1*4+DATA_TO_BE_WRITTEN_OFFSET+2(sp),(a0)							| Write (word sized) data to REG_VRAMMOD.

	move.l	(sp)+,a0

	rte
3:
	move	vram_increment(pc),DATA_TO_BE_READ_OFFSET+2(sp)						| Read (word sized) data from REG_VRAMMOD.

	rte
2:
	| REG_LSPCMODE.

	cmp		#0x0006,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	clr		DATA_TO_BE_READ_OFFSET+2(sp)										| Read (word sized) data from REG_LSPCMODE.

	rte
2:
	rte
1:
	| REG_P1CNT, REG_DIPSW, REG_300081.

	cmp		#0x0030,ACCESS_ADDRESS_OFFSET(sp)
	jne		1f

	| REG_P1CNT.

	tst		ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.l	d0,-(sp)

	move	#0xff,d0

	cmp.b	#0x2a,0xfc02.w														| Left SHIFT.
	jne		3f

	and		#0xef,d0
3:
	cmp.b	#0x1d,0xfc02.w														| CONTROL.
	jne		3f

	and		#0xdf,d0
3:
	cmp.b	#0x4b,0xfc02.w														| Arrow left.
	jne		3f

	and		#0xfb,d0
3:
	cmp.b	#0x4d,0xfc02.w														| Arrow right.
	jne		3f

	and		#0xf7,d0
3:
	cmp.b	#0x48,0xfc02.w														| Arrow up.
	jne		3f

	and		#0xfe,d0
3:
	cmp.b	#0x50,0xfc02.w														| Arrow down.
	jne		3f

	and		#0xfd,d0
3:
	move.b	d0,1*4+DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_P1CNT.

	move.l	(sp)+,d0

	rte
2:
	| REG_DIPSW (write = kick watchdog).

	cmp		#0x0001,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	cmp.b	#0x01,0xfc02.w
	jeq		emulator_exit

	move.b	#0xff,DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_DIPSW.

	rte
2:
	| REG_300081.

	cmp		#0x0081,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.b	#0x80,DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_300081.

	rte
2:
	rte
1:
	| REG_SOUND, REG_STATUS_A.

	cmp		#0x0032,ACCESS_ADDRESS_OFFSET(sp)
	jne		1f

	| REG_SOUND.

	tst		ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	btst	#6,SSW_OFFSET+1(sp)													| Read access?
	jne		3f

	move.l	a0,-(sp)

	lea		sound_command(pc),a0
	move.b	1*4+DATA_TO_BE_WRITTEN_OFFSET+3(sp),(a0)							| Write (byte sized) data to REG_SOUND.

	move.l	(sp)+,a0

	rte
3:
	move.l	d0,-(sp)

	cmp.b	#0x01,sound_command(pc)
	seq		d0
	and		#0x01,d0

	move.b	d0,1*4+DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_SOUND.

	move.l	(sp)+,d0

	rte
2:
	| REG_STATUS_A.

	cmp		#0x0001,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	movem.l	d0/a0,-(sp)

	lea		reg_status_a_counter(pc),a0
	eor		#0x0040,(a0)
	move	(a0),d0

	cmp.b	#0x06,0xfc02.w
	jne		3f

	and		#0xfe,d0
3:
	move.b	d0,2*4+DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_STATUS_A.

	movem.l	(sp)+,d0/a0

	rte
2:
	rte
1:
	| REG_STATUS_B, REG_POUTPUT, REG_CRDBANK, REG_SLOT, REG_LEDLATCHES,
	| REG_LEDDATA, REG_RTCCTRL.

	cmp		#0x0038,ACCESS_ADDRESS_OFFSET(sp)
	jne		1f

	| REG_STATUS_B.

	tst		ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.b	#0xff,DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_STATUS_B.

	cmp.b	#0x02,0xfc02.w
	jne		3f

	move.b	#0xfe,DATA_TO_BE_READ_OFFSET+3(sp)									| Read (byte sized) data from REG_STATUS_B.
3:
	rte
2:
	rte
1:
	| REG_NOSHADOW, REG_SHADOW, REG_SWPBIOS, REG_SWPROM, REG_CRDUNLOCK1,
	| REG_CRDLOCK1, REG_CRDLOCK2, REG_CRDUNLOCK2, REG_CRDREGSEL, REG_CRDNORMAL,
	| REG_BRDFIX, REG_CRTFIX, REG_SRAMLOCK, REG_SRAMULOCK, REG_PALBANK1,
	| REG_PALBANK0.

	cmp		#0x003a,ACCESS_ADDRESS_OFFSET(sp)
	jne		1f

	| REG_SWPBIOS.

	cmp		#0x0003,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.l	a0,-(sp)

	lea		use_cartridge_vector_table(pc),a0
	clr		(a0)

	move.l	(sp)+,a0

	rte
2:
	| REG_SWPROM.

	cmp		#0x0013,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.l	a0,-(sp)

	lea		use_cartridge_vector_table(pc),a0
	move	#-1,(a0)

	move.l	(sp)+,a0

	rte
2:
	| REG_PALBANK1.

	cmp		#0x000f,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.l	a0,-(sp)

	lea		palette_bank_offset(pc),a0
|	move	#0x2000,(a0)														| Fixme: palette!

	move.l	(sp)+,a0

	rte
2:
	| REG_PALBANK0.

	cmp		#0x001f,ACCESS_ADDRESS_OFFSET+2(sp)
	jne		2f

	move.l	a0,-(sp)

	lea		palette_bank_offset(pc),a0
|	clr		(a0)																| Fixme: palette!

	move.l	(sp)+,a0

	rte
2:
	rte
1:
	rte

vram_address:
	ds.w	1

vram_increment:
	ds.w	1

sound_command:
	ds.w	1

use_cartridge_vector_table:
	ds.w	1

palette_bank_offset:
	ds.w	1

reg_status_a_counter:
	dc.w	0x007f

sprite_draw_counter:
	dc.w	1

|-------------------------------------------------------------------------------
|
|	Draw dummy sprites.
|
|-------------------------------------------------------------------------------

draw_dummy_sprites:
	movem.l	d0-a6,-(sp)

	lea		VRAM_ADDRESS+0x8200*2,a0
	lea		VRAM_ADDRESS,a1														| Sprite tile maps.
	lea		work_screen_address(pc),a2
	move.l	(a2),a2

	clr		d4 																	| Previous sprite height.
	clr		d5 																	| Previous sprite X position.
	clr		d6 																	| Previous sprite Y position.

	move	#381-1,d7
1:
	move	0x200*2(a0),d0 														| Sprite X position.
	move	(a0)+,d1 															| Sprite Y position + sticky bit + height.

	btst	#6,d1 																| Check sticky bit.
	jeq		3f

	move	d4,d3 																| Use previous height.
	jeq		2f 																	| Avoid having 0 as the height.

	add		#16,d5
	move	d5,d0 																| Use previous X position + 16.

	move	d6,d2 																| use previous Y position.

	jra		4f
3:
	move	d1,d3
	and		#0x3f,d3 															| Sprite height.
	move	d3,d4 																| Save sprite height.
	jeq		2f

	lsr		#7,d1
	move	#512,d2
	sub		d1,d2
	move	d2,d6 																| Save Y position.

	lsr		#7,d0
	move	d0,d5 																| Save X position.
4:
	| Check sprite X position boundaries.

	cmp		#320,d0 															| Right screen border.
	jlt		6f

	sub		#512,d0

	cmp		#-16,d0 															| Left screen border.
	jle		2f
6:
	| Calculate sprite screen address.

	swap	d2
	clr		d2
	lsr.l	#7,d2
	ext.l	d0
	add.l	d0,d2
	lea		(a2,d2.l*2),a3

	move.l	a1,a4

	subq	#1,d3
3:
	move.l	a3,a6

	move.l	a2,a5
	add.l	#512*2*(224+16),a5

	cmp.l	a5,a6
	jlt		4f

	sub.l	#512*2*512,a6

	cmp.l	a2,a6
	jle		5f
4:
	| Sprite decoding and drawing.

	movem.l	d0-a6,-(sp)

	lea		TILES_USAGE_BITMAP,a0

	clr.l	d0
	move	(a4),d0
	lsl.l	#2,d0

	clr.l	d1
	move	2(a4),d1
	move.l	d1,d2
	and		#0x3,d1
	or		d1,d0

	and		#0x00f0,d2
	swap	d2
	lsr.l	#2,d2
	or.l	d2,d0

	move	d0,d1
	and		#0x7,d1
	move	#0x80,d2
	lsr		d1,d2

	lsr.l	#3,d0
	or.b	d2,(a0,d0.l)
/*
	lea		SPRITES_ADDRESS,a0
	lea		PALETTE_DECODER_TABLE,a1

	lea		PALETTE_RAM,a5
	lea		palette_bank_offset(pc),a2
	add		(a2),a5

	clr.l	d0
	move	(a4)+,d0
	and		#0x7fff,d0
	lsl.l	#7,d0
	add.l	d0,a0

	move	(a4),d0
	clr.b	d0
	lsr		#8-5,d0
	add		d0,a5

	lea		16*2(a6),a6

	| Block #1.

	move	#8-1,d6
7:
	move.b	(a0)+,d3
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.b	(a0)+,d0

	move	#8-1,d5
8:
	subq.l	#2,a6

	clr.l	d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	tst		d4
	jeq		9f

	move	(a5,d4.l*2),d4
	move	(a1,d4.l*2),(a6)
9:
	dbf		d5,8b

	lea		512*2+8*2(a6),a6

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
	subq.l	#2,a6

	clr.l	d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	tst		d4
	jeq		9f

	move	(a5,d4.l*2),d4
	move	(a1,d4.l*2),(a6)
9:
	dbf		d5,8b

	lea		512*2+8*2(a6),a6

	dbf		d6,7b

	sub.l	#512*2*16+8*2,a6

	| Block #3.

	move	#8-1,d6
7:
	move.b	(a0)+,d3
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.b	(a0)+,d0

	move	#8-1,d5
8:
	subq.l	#2,a6

	clr.l	d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	tst		d4
	jeq		9f

	move	(a5,d4.l*2),d4
	move	(a1,d4.l*2),(a6)
9:
	dbf		d5,8b

	lea		512*2+8*2(a6),a6

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
	subq.l	#2,a6

	clr.l	d4

	add.b	d0,d0
	addx	d4,d4
	add.b	d1,d1
	addx	d4,d4
	add.b	d2,d2
	addx	d4,d4
	add.b	d3,d3
	addx	d4,d4

	tst		d4
	jeq		9f

	move	(a5,d4.l*2),d4
	move	(a1,d4.l*2),(a6)
9:
	dbf		d5,8b

	lea		512*2+8*2(a6),a6

	dbf		d6,7b
*/
	movem.l	(sp)+,d0-a6
5:
	addq.l	#4,a4
	add.l	#512*2*16,a3

	dbf		d3,3b
2:
	lea		32*4(a1),a1

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
	jeq		1b

	lea		3f(pc),a0															| Return address.
	movem.l	d0/a0-a1,-(sp)
	movem.l	(a2),d0-a5															| Load palette colors.
	rts																			| Jump to sprite drawing code.
3:
	move.l	(sp)+,a1
	jra		1b
2:

|-------------------------------------------------------------------------------
|
|	Build sprite infos.
|
|	Each entry consists of the palette address, the screen address and the
|	drawing address.
|
|-------------------------------------------------------------------------------

build_sprite_infos:
	movem.l	d0-a6,-(sp)

	lea		VRAM_ADDRESS+0x8200*2,a0											| Sprite Y positions + sticky bit + height.
	lea		VRAM_ADDRESS,a2														| Sprite tilemaps.

	lea		SPRITE_INFOS_ADDRESS,a3												| Converted sprite infos.
	lea		COMPILED_TILES_ADDRESS,a4											| Compiled sprites.
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

	move.l	#SCREEN_ADDRESS,d0
	swap	d0
	move.b	d0,0x8201.w
	swap	d0
	move	d0,d1
	ror		#8,d0
	move.b	d0,0x8203.w
	move.b	d1,0x820d.w

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
	movem.l	d0-d1/a0-a1,-(sp)

	lea		display_screen_address(pc),a0
	move.l	(a0),d0
	add.l	#512*2*16+8*2,d0
|	move.l	#0x400000,d0														| Fixme: test.
	swap	d0
	move.b	d0,0x8201.w
	swap	d0
	move	d0,d1
	ror		#8,d0
	move.b	d0,0x8203.w
	move.b	d1,0x820d.w

	lea		sprite_draw_counter(pc),a0
	move	(a0),d0
	addq	#1,(a0)
	and		#0xf,d0
	jne		1f

	jbsr	draw_dummy_sprites

	lea		display_screen_address(pc),a0
	lea		work_screen_address(pc),a1
	move.l	(a0),d0
	move.l	(a1),(a0)
	move.l	d0,(a1)
1:
	movem.l	(sp)+,d0-d1/a0-a1

	tst		use_cartridge_vector_table(pc)
	jne		1f

	jmp		0xc00438															| Jump to the BIOS VBL routine.
1:
	move.l	0x64.w,-(sp)														| Jump to the cartridge VBL routine.

	rts

display_screen_address:
	dc.l	SCREEN_ADDRESS_2

work_screen_address:
	dc.l	SCREEN_ADDRESS

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
