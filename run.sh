#!/bin/sh
# Run neogeotest.tos under Hatari with one game selected.
#
#   ./run.sh [game] [extra hatari options ...]     default game: mslug
#   ./run.sh mslug --screenshot /tmp/shot.png      break at --run-vbls and grab
#                                                  the screen, then quit
#
# Four things here are not optional, each of which costs a whole run to
# rediscover (see ../../DEBUGGING.md "Emulators that run on bus errors"):
#
#  * --debug-except none. neogeotest emulates the Neo Geo hardware *out of* its
#    68030 bus error handler, and Hatari's default exception mask is
#    bus|address|dsp -- so the stock settings break into the debugger on the
#    emulator's first hardware access and the run dies there.
#  * --mmu true. The emulator pmoves its own translation tree (emulator.asm);
#    without this the vendored build does not even store the MMU registers.
#  * --ttram 0, per hatari.md, for the TOS 4.04 / 030 profile.
#  * The program is passed as a bare filename with the CWD set here. An
#    absolute forward-slash path is mangled by the autostart INF writer, which
#    then reports 'GEMDOS didn't find filename ...\+ARBEIT+.PRG'.
#
# Hatari's autostart cannot pass arguments to the program, so RUNNER.PRG
# (runner.asm) Pexec()s the emulator with the game name as its command tail.
#
# Expect it to stop in the emulator's own hex dump partway into the Neo Geo
# BIOS. That is an emulator-under-emulator limit, not a fault in this tree:
# Hatari does not build a faithful 68030 bus fault frame, and the handler
# decodes the frame's fault address and data output buffer to do its work. See
# ../../DEBUGGING.md "The 68030 bus fault stack frame is not faithful". Judge
# behaviour on real hardware, not on what this script shows.
set -e
cd "$(dirname "$0")"

HATARI=${HATARI:-../hatari/build-ucrt64/src/hatari.exe}
TOS=${TOS:-../tos/tos404.img}
VASM=${VASM:-../vasm/vasmm68k_mot.exe}
VBLS=${VBLS:-3000}

GAME=mslug
if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then
	GAME=$1
	shift
fi
[ -d "$GAME" ] || { echo "no ROMs for '$GAME' -- run install_roms.py first"; exit 1; }
[ -f neogeotest.tos ] || { echo "neogeotest.tos missing -- run build.sh first"; exit 1; }

SHOT=
if [ "$1" = "--screenshot" ]; then
	SHOT=$2
	shift 2
fi

sed "s/^\tdc.b\t\"mslug\"/\tdc.b\t\"$GAME\"/" runner.asm > runner.gen.asm
"$VASM" -quiet -Ftos -m68000 -o RUNNER.PRG runner.gen.asm

PARSE=
if [ -n "$SHOT" ]; then
	# The debugger's screenshot command needs the display, so this run cannot
	# use --disable-video; a Hatari window will appear.
	printf 'screenshot %s\nquit\n' "$SHOT" > onbreak.gen.ini
	printf 'lock file %s\nb VBL > %s :once\ncont\n' \
		"$(pwd -W 2>/dev/null || pwd)/onbreak.gen.ini" "$VBLS" > parse.gen.ini
	PARSE="--screenshot-format png --parse $(pwd -W 2>/dev/null || pwd)/parse.gen.ini"
else
	PARSE="--disable-video on --benchmark --run-vbls $VBLS"
fi

# TMP/TEMP: a per-session temp dir makes Hatari's autostart fail in
# GetTempFileName (hatari.md); point it at the user's real one.
TMP='C:\Users\sasch\AppData\Local\Temp' \
TEMP='C:\Users\sasch\AppData\Local\Temp' \
PATH=/c/msys64/ucrt64/bin:$PATH \
	"$HATARI" \
	--machine falcon --tos "$TOS" --memsize 14 --ttram 0 --cpulevel 3 \
	--mmu true --monitor rgb --sound off --confirm-quit off --fast-boot true \
	--debug-except none \
	$PARSE "$@" \
	RUNNER.PRG
