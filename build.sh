#!/bin/sh
# Build neogeotest.tos — "Neo Geo Emulator for the Atari Falcon" (S. Springer,
# pre-alpha 20131230) — with the vendored vlink + a vasmm68k built from
# third_party/vasm using the *std* syntax module.
#
# The sources are GNU-as style (.equ/.global/.asciz, '|' and /* */ comments).
# The vendored vasmm68k_mot only speaks motorola syntax, so this tree needs
# vasmm68k_std, which is not shipped prebuilt. Build it once with:
#
#   cd ../vasm && make -f Makefile CPU=m68k SYNTAX=std PRE="obj_std/m68k_std_"
#
# preprocess.py rewrites the three constructs vasmm68k_std rejects (block
# comments, line-leading '|' comments, \r\n escapes in .ascii/.asciz) plus
# jbsr -> bsr. Stage 1: preprocessed copy in stage/src; stage 2: the same files
# one level up, because the sources .include "../xxx.asm" and vasm resolves
# those paths relative to the CWD, not to the including file.
#
# Note: running the resulting .tos additionally needs Neo Geo ROM files
# (sp-s2.sp1, <game>\<roms>, e.g. mslug\) next to it; see roms.asm.
set -e
cd "$(dirname "$0")"

VASM=../vasm/vasmm68k_std
VLINK=../vlink/vlink
for t in "$VASM" "$VLINK"; do
	[ -x "$t" ] || [ -x "$t.exe" ] || { echo "missing tool: $t (build $VASM first, see comments)"; exit 1; }
done

python3 preprocess.py
rm -rf stage
mkdir -p stage/src
cp build/*.asm stage/src/
cp build/*.asm stage/

OBJS=""
for f in main init emulator compiler mmu roms; do
	echo "assembling $f.asm"
	# CWD must be stage/src so that .include "../xxx.asm" finds the stage/ copy.
	(cd stage/src && "../../$VASM" -quiet -Faout -m68030 -nosym -o $f.o $f.asm)
	OBJS="$OBJS stage/src/$f.o"
done

"$VLINK" -bataritos -tos-flags 7 -estart $OBJS -o neogeotest.tos
ls -la neogeotest.tos
