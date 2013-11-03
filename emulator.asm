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

	| Set emulator interrupt handlers (in the NeoGeo memory pages!).

	lea		emulator_vbl_handler(pc),a1
	move.l	a1,0x70(a0)

	lea		emulator_ikbd_handler(pc),a1
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

	move	#0x2300,sr															| Emulation started.




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

emulator_vbl_handler:
	movem.l	a0-a1,-(sp)

	lea		test_address(pc),a0
	move.l	(a0),a1
	move	#0xffff,(a1)+
	move.l	a1,(a0)

	movem.l	(sp)+,a0-a1

	rte

test_address:
	dc.l	0x600000

emulator_ikbd_handler:

	rte

emulator_end:

.end
