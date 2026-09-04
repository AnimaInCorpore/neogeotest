; Start neogeotest.tos with a game name on its command line.
;
; neogeotest takes the game to run from its basepage command tail -- main.asm
; does "lea 0x81(a0),a0" and hands that to select_game -- but Hatari's
; autostart only carries a program name: INF_SetAutoStart() has nowhere to put
; arguments. So this Pexec()s the emulator with the tail filled in.
;
; run.sh rewrites the game name below and assembles this with
;   vasmm68k_mot -Ftos -o RUNNER.PRG runner.asm
; Motorola syntax, so it needs none of preprocess.py's rewriting.

	text

start:
	move.l	4(sp),a5						; our basepage

	; Give the rest of the TPA back, or there is nothing for the child.
	move.l	12(a5),d0						; text length
	add.l	20(a5),d0						; data length
	add.l	28(a5),d0						; bss length
	add.l	#$100,d0						; and the basepage itself
	move.l	d0,-(sp)
	move.l	a5,-(sp)
	clr.w	-(sp)
	move.w	#$4a,-(sp)						; Mshrink
	trap	#1
	lea		12(sp),sp

	; Pexec(0, "neogeotest.tos", "\5mslug", NULL) -- load and go.
	clr.l	-(sp)							; inherit our environment
	pea		command_tail
	pea		program_name
	clr.w	-(sp)							; mode 0
	move.w	#$4b,-(sp)						; Pexec
	trap	#1
	lea		16(sp),sp

	clr.w	-(sp)							; Pterm0
	trap	#1

	data

program_name:
	dc.b	"neogeotest.tos",0

; A command tail is a length byte followed by the text; neogeotest reads from
; the text and relies on the NUL, so keep both.
command_tail:
	dc.b	game_name_end-game_name
game_name:
	dc.b	"mslug"							; <-- run.sh rewrites this line
game_name_end:
	dc.b	0

	end
