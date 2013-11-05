.global emulator
.global emulator_end

.equ	BREAKPOINT_ADDRESS,0xc11d8e
.equ	SCREEN_ADDRESS,0x600000

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

	| Set screen memory.

	move.l	#SCREEN_ADDRESS,d0
	swap	d0
	move.b	d0,0x8201.w
	swap	d0
	move	d0,d1
	ror		#8,d0
	move.b	d0,0x8203.w
	move.b	d1,0x820d.w

	| Clear screen memory.

	lea		SCREEN_ADDRESS,a0
1:
	clr.l	(a0)+

	cmp.l	#SCREEN_ADDRESS+512*2*224,a0
	jlt		1b

	| Start the emulation.

|	lea		0x10F300,sp															| Set the initial NeoGeo stack pointer.
	lea		0x600000,sp															| The NeoGeo stack pointer is not usable because the BIOS RAM check fails while the trace and bus error exceptions are active.
|	move	#0xa000,sr															| Trace start.
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
	movem.l	d0-a6,-(sp)

	move.l	15*4+0x10(sp),d0													| Access address.
	move	15*4+0xa(sp),d1														| "Special Status Word".

	| REG_VRAMADDR.

	cmp.l	#0x3c0000,d0
	jne		2f

	btst	#6,d1																| Read access?
	jne		1f

	lea		vram_address(pc),a0
	move	15*4+0x18+0x2(sp),(a0)												| Write (word sized) data to REG_VRAMADDR.

	jra		3f
1:
|	move	d1,d2
|	and		#0x0030,d2															| Mask out "data size".

	move	vram_address(pc),15*4+0x2c+0x2(sp)									| Read (word sized) data from REG_VRAMADDR.

	jra		3f
2:
	| REG_VRAMRW.

	cmp.l	#0x3c0002,d0
	jne		2f

	btst	#6,d1																| Read access?
	jne		1f

	lea		vram_address(pc),a0
	move	(a0),d0

	lea		0x580000,a1
	move	15*4+0x18+0x2(sp),(a1,d0.w*2)										| Write (word sized) data to REG_VRAMRW.

	lea		vram_increment(pc),a1
	add		(a1),d0
	move	d0,(a0)

	jra		3f
1:
	lea		vram_address(pc),a0
	move	(a0),d0

	lea		0x580000,a1
	move	(a1,d0.w*2),15*4+0x2c+0x2(sp)										| Read (word sized) data from REG_VRAMRW.

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

	move.b	#0xff,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_DIPSW.

	jra		3f
2:
	| REG_STATUS_A.

	cmp.l	#0x320001,d0
	jne		2f

	lea		reg_status_a_counter(pc),a0
	move	(a0),d0
	addq	#1,d0
	move	d0,(a0)
	and		#0x3f,d0
	sne		d0
	and		#0x7f,d0
	or		#0x3f,d0

	move.b	d0,15*4+0x2c+0x3(sp)												| Read (byte sized) data from REG_STATUS_A.

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

	| Write unhandled access addresses on screen.

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
	or		#0x8000,(sp)														| Reenable tracing.
	bclr	#8,0xa(sp)															| Data fault processed.

	rte

vram_address:
	ds.w	1

vram_increment:
	ds.w	1

use_cartridge_vector_table:
	ds.w	1

reg_status_a_counter:
	ds.w	1

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

	move.l	15*4+0x8(sp),d0
	move	#0xffff,d2
	jbsr	write_long_data

	jbsr	write_space

	move.l	d0,a0
	move	(a0),d0
	move	#0xffff,d2
	jbsr	write_word_data

	jbsr	write_space

	move.l	15*4+0xc(sp),d0
	move	#0xffff,d2
	jbsr	write_long_data

	jbsr	write_space
	jbsr	write_new_line

	clr		d1

	move	#4-1,d7
2:
	move	#4-1,d6
3:
	move.l	(sp,d1.w*4),d0
	move	#0xffff,d2
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

	rte

|-------------------------------------------------------------------------------
|
|	VBL interrupt handler.
|
|-------------------------------------------------------------------------------

vbl_handler:
	add.l	#0x01010001,0x9800.w

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
