.include "../bios.asm"
.include "../xbios.asm"
.include "../gemdos.asm"

.global f030_init
.global f030_deinit

.equ SCREEN_WIDTH, 320
.equ SCREEN_HEIGHT, 240

.text

| -----------------------------------------------------------------------------
|
| -----------------------------------------------------------------------------

f030_init:
	Super	0

	move	#0x2700,sr

	move.b	0xfa07.w,old_fa07
	move.b	0xfa09.w,old_fa09
	move.b	0xfa13.w,old_fa13
	move.b	0xfa15.w,old_fa15

	move.l	0x2c.w,old_line_f
	move.l	0xbc.w,old_trap_f
	move.l	0x70.w,old_vbl
	move.l	0x118.w,old_keyboard

	move.b	0x8201.w,old_screen+1
	move.b	0x8203.w,old_screen+2
	move.b	0x820d.w,old_screen+3

	move.l	0x820e.w,d0
	move.l	0x8264.w,d1
	movem.l	0x8282.w,d2-d5
	movem.l	0x82a2.w,d6-a0
	move.l	0x82c0.w,a1
	move	0x820a.w,a2
	movem.l	d0-a2,old_videl

	clr.b	0xfa07.w
	clr.b	0xfa09.w
	clr.b	0xfa13.w
	clr.b	0xfa15.w

|	move.l	#vbl,0x70.w
|	move.l	#keyboard,0x118.w

	bset	#6,0xfa09.w															| IKBD interrupt enable.
	bset	#6,0xfa15.w															| IKBD interrupt mask.

	bclr	#3,0xfa17.w

	lea		0x9800.w,a0
	lea		old_palette,a1
	move	#256-1,d7
f030_init_palette_copy_loop:
	move.l	(a0)+,(a1)+
	dbra	d7,f030_init_palette_copy_loop

	| Set true color mode.

	lea		screen_mode_table,a0

	btst	#6,0x8006.w
	jeq		f030_init_set_vga_mode

f030_init_set_rgb_tv_loop:
	tst		30(a0)
	bne		f030_init_set_rgb_tv_continue

	move	32(a0),d0
	cmp		#SCREEN_WIDTH,d0
	jne		f030_init_set_rgb_tv_continue

	move.l	(a0)+,0x8282.w
	move.l	(a0)+,0x8286.w
	move.l	(a0)+,0x828a.w
	move.l	(a0)+,0x82a2.w
	move.l	(a0)+,0x82a6.w
	move.l	(a0)+,0x82aa.w
	move	(a0)+,0x820a.w
	move	(a0)+,0x82c0.w
	clr		0x8266.w
	move	(a0)+,0x8266.w
	move	(a0)+,0x82c2.w
	move	(a0)+,0x8210.w

	jra		f030_init_set_rgb_tv_vga_go_on

f030_init_set_rgb_tv_continue:
	lea		34(a0),a0

	jra		f030_init_set_rgb_tv_loop

f030_init_set_vga_mode:
f030_init_set_vga_loop:
	cmp		#0x5,30(a0)
	jne		f030_init_set_vga_continue

	move	32(a0),d0
	cmp		#SCREEN_WIDTH,d0
	jne		f030_init_set_vga_continue

	move.l	(a0)+,0x8282.w
	move.l	(a0)+,0x8286.w
	move.l	(a0)+,0x828a.w
	move.l	(a0)+,0x82a2.w
	move.l	(a0)+,0x82a6.w
	move.l	(a0)+,0x82aa.w
	move	(a0)+,0x820a.w
	move	(a0)+,0x82c0.w
	clr		0x8266.w
	move	(a0)+,0x8266.w
	move	(a0)+,0x82c2.w
	move	(a0)+,0x8210.w

	jra		f030_init_set_rgb_tv_vga_go_on

f030_init_set_vga_continue:
	lea		34(a0),a0

	jra		f030_init_set_vga_loop

f030_init_set_rgb_tv_vga_go_on:

	move	#512-SCREEN_WIDTH,0x820e.w

	clr.l	0x9800.w															| Black background.

|	move	#0x2300,sr

	rts

| -----------------------------------------------------------------------------
|
| -----------------------------------------------------------------------------

f030_deinit:
	move	#0x2700,sr

	move.b	old_fa07,0xfa07.w
	move.b	old_fa09,0xfa09.w
	move.b	old_fa13,0xfa13.w
	move.b	old_fa15,0xfa15.w

	move.l	old_line_f,0x2c.w
	move.l	old_trap_f,0xbc.w
	move.l	old_vbl,0x70.w
	move.l	old_keyboard,0x118.w

	move.b	old_screen+1,0x8201.w
	move.b	old_screen+2,0x8203.w
	move.b	old_screen+3,0x820d.w

	movem.l	old_videl,d0-a2
	move.l	d0,0x820e.w
	move.l	d1,0x8264.w
	movem.l	d2-d5,0x8282.w
	movem.l	d6-a0,0x82a2.w
	move.l	a1,0x82c0.w
	move	a2,0x820a.w

	lea		old_palette,a0
	lea		0x9800.w,a1
	move	#256-1,d7
f030_deinit_copy_palette_loop:
	move.l	(a0)+,(a1)+
	dbf		d7,f030_deinit_copy_palette_loop

	move	#0x2300,sr

	Pterm0

.data

screen_mode_table:
|screen_rgb_tv_320_200:
|	dc.l	0xfe00c9
|	dc.l	0x27002e
|	dc.l	0x8f00d9
|	dc.l	0x20d0201
|	dc.l	0x17004d
|	dc.l	0x1dd0207
|	dc.w	0x200
|	dc.w	0x181
|	dc.w	0x100
|	dc.w	0x0
|	dc.w	0x140

screen_rgb_tv_320_224:
	dc.l	0xfe00c9
	dc.l	0x27002e
	dc.l	0x8f00d9
	dc.l	0x20d0201
	dc.l	0x170035
	dc.l	0x1f50207
	dc.w	0x200
	dc.w	0x181
	dc.w	0x100
	dc.w	0x0
	dc.w	0x140

screen_rgb_tv_256_240:
	dc.l	0xfe00cb
	dc.l	0x28004f
	dc.l	0x7000da
	dc.l	0x20d0201
	dc.l	0x170025
	dc.l	0x1fd0207
	dc.w	0x200
	dc.w	0x183
	dc.w	0x100
	dc.w	0x0
	dc.w	0x100

screen_rgb_tv_384_240:
	dc.l	0xfe00cb
	dc.l	0x280019
	dc.l	0xba00da
	dc.l	0x20d0201
	dc.l	0x170025
	dc.l	0x2050207
	dc.w	0x200
	dc.w	0x183
	dc.w	0x100
	dc.w	0x0
	dc.w	0x180

screen_rgb_tv_224_240:
	dc.l	0xfe00cb
	dc.l	0x28005f
	dc.l	0x6000da
	dc.l	0x20d0201
	dc.l	0x170025
	dc.l	0x1fd0207
	dc.w	0x200
	dc.w	0x183
	dc.w	0x100
	dc.w	0x0
	dc.w	0xe0

screen_vga_320_240:
	dc.l	0xc6008d
	dc.l	0x1502ac
	dc.l	0x8d0097
	dc.l	0x41903ff
	dc.l	0x3f003d
	dc.l	0x3fd0415
	dc.w	0x200
	dc.w	0x186
	dc.w	0x100
	dc.w	0x5
	dc.w	0x140

screen_vga_256_240:
	dc.l	0xc6008d
	dc.l	0x150004
	dc.l	0x6d0097
	dc.l	0x41903ff
	dc.l	0x3f003d
	dc.l	0x3fd0415
	dc.w	0x200
	dc.w	0x186
	dc.w	0x100
	dc.w	0x5
	dc.w	0x100

screen_vga_224_240:
	dc.l	0xc6008d
	dc.l	0x150014
	dc.l	0x5d0097
	dc.l	0x41903ff
	dc.l	0x3f003d
	dc.l	0x3fd0415
	dc.w	0x200
	dc.w	0x186
	dc.w	0x100
	dc.w	0x5
	dc.w	0xe0

.bss

old_screen:
	ds.l	1
old_palette:
	ds.l	256
old_videl:
	ds.l	11

old_line_f:
	ds.l	1
old_trap_f:
	ds.l	1
old_vbl:
	ds.l	1
old_keyboard:
	ds.l	1

old_fa07:
	ds.b	1
old_fa09:
	ds.b	1
old_fa13:
	ds.b	1
old_fa15:
	ds.b	1

.end
