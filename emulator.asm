.global emulator
.global emulator_end
.global emulator_vbl_handler
.global emulator_ikbd_handler

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

	lea		0x10F300,sp															| Set the NeoGeo stack pointer.

	move	#0x2000,sr															| Emulation started.




	move	#0xa000,sr															| Trace start.
	jbra	0xc00402															| Call NeoGeo BIOS init routine.

1:	cmp.b	#0x39,0xfc02.w														| Wait for SPACE.
	jne		1b




	move	#0x2700,sr															| Emulation stopped.

	| Restore the Atari mode.

	clr.l	(a0)
	pmove	(a0),tc																| Disable address translation.

	move.l	#0x80000002,(a0)
	move.l	#0x00000700,4(a0)
	pmove	(a0),crp															| Restore the Atari MMU table address.

	move.l	#0x80f04445,(a0)
	pmove	(a0),tc																| Enable address translation.

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
	move.l	#0xff000000,0x9800.w

	rte

|-------------------------------------------------------------------------------
|
|	Trace handler.
|
|-------------------------------------------------------------------------------

trace_handler:
	movem.l	d0-a6,-(sp)

	move.l	15*4+2(sp),d0
	jbsr	write_long_data

	movem.l	(sp)+,d0-a6

	rte

|-------------------------------------------------------------------------------
|
|	HBL interrupt handler.
|
|-------------------------------------------------------------------------------

hbl_handler:

	rte

|-------------------------------------------------------------------------------
|
|	VBL interrupt handler.
|
|-------------------------------------------------------------------------------

vbl_handler:
	movem.l	a0-a1,-(sp)

	lea		test_address(pc),a0
	move.l	(a0),a1
	not		(a1)+
	move.l	a1,(a0)

	movem.l	(sp)+,a0-a1

	rte

test_address:
	dc.l	0x600000

|-------------------------------------------------------------------------------
|
|	IKBD interrupt handler.
|
|-------------------------------------------------------------------------------

ikbd_handler:

	rte

|-------------------------------------------------------------------------------
|
|	Write byte data.
|
|	d0.b = data to be written.
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
|
|-------------------------------------------------------------------------------

write_long_data:
	move.l	d1,-(sp)

	move	#8,d1
	jbsr	write_data

	move.l	(sp)+,d1

	rts


|-------------------------------------------------------------------------------
|
|	Write data.
|
|	d0.l = data to be written.
|	d1.l = number of characters of the data to be written.
|
|-------------------------------------------------------------------------------

write_data:
	movem.l	d0-a6,-(sp)

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
	ext.w	d3
	move	d3,(a0)+

	dbf		d5,3b

	lea		512*2-8*2(a0),a0
	addq	#1,a2

	dbf		d6,2b

	lea		-512*2*8+8*2(a0),a0

	dbf		d7,1b

	lea		write_display_address(pc),a0
	move.l	(a0),d0
	add.l	#512*2*8,d0
	cmp.l	#0x600000+512*2*224,d0
	jlt		4f

	move.l	#0x600000,d0
4:
	move.l	d0,(a0)

	movem.l	(sp)+,d0-a6

	rts

write_display_address:
	dc.l	0x600000

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
