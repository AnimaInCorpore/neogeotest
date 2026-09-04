#!/usr/bin/env python3
r"""Stage the Neo Geo ROMs neogeotest.tos needs, out of a MAME rom set.

roms.asm opens its ROMs by plain GEMDOS path, relative to the program: the
BIOS as "sp-s2.sp1" and each game's as "<game>\<file>".  This unpacks a MAME
set into exactly that layout.

Two things stop it from being a plain unzip:

  * The tree dates from 2013 and asks for the ROM names MAME used then.  A
    current set has renamed several of them (bangbead's "bgn_c1.rom" is now
    "259-c1.c1"), so RENAMES maps the old name onto the new member.
  * A merged set stores a clone inside its parent's zip, under a directory --
    nitdbl lives in nitd.zip as "nitdbl/nitd-p1.bin".  Members are therefore
    matched on basename, and SOURCE_ZIP points a clone at its parent.

Every character ROM is checked against the size roms.asm itself declares for
it (each C row of a game_info block carries the combined size of the pair), so
a wrong rename is caught here rather than as a corrupt screen on the Falcon.

Usage: python3 install_roms.py [<mame-rom-dir>] [game ...]
"""
import collections
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_MAME = 'G:/MAME/roms'
BIOS = 'sp-s2.sp1'
BIOS_ZIP = 'neogeo'
GENERATED = ('.tls', '.ubm')

# Clones that a merged set keeps inside another game's zip.
SOURCE_ZIP = {'nitdbl': 'nitd'}

# What roms.asm asks for -> what a current MAME set calls it.
RENAMES = {
    'bangbead': {'bgn_c1.rom': '259-c1.c1', 'bgn_c2.rom': '259-c2.c2'},
    'ganryu': {'gann_c1.rom': '252-c1.c1', 'gann_c2.rom': '252-c2.c2'},
    'gowcaizr': {'059-c8.c8': '094-c8.c8'},
    'ironclad': {'proto_22.p1': 'proto_220-p1.p1',
                 'proto_22.c1': 'proto_220-c1.c1',
                 'proto_22.c2': 'proto_220-c2.c2',
                 'proto_22.c3': 'proto_220-c3.c3',
                 'proto_22.c4': 'proto_220-c4.c4'},
    'sengoku3': {'sen3n_c1.rom': '261-c1.c1', 'sen3n_c2.rom': '261-c2.c2',
                 'sen3n_c3.rom': '261-c3.c3', 'sen3n_c4.rom': '261-c4.c4'},
}

LABEL_RE = re.compile(r'^(\w+):\s*$')
PATH_RE = re.compile(r'^\s*\.asciz\s+"([^"\\]+)\\\\([^"]+)"')
INFO_RE = re.compile(r'^(\w+)_info:\s*$')
DCL_RE = re.compile(r'^\s*dc\.l\s+(.*?)\s*(?:\|.*)?$')


def read_roms_asm():
    """-> {game: {filename: expected_size_or_None}}, in roms.asm's own order."""
    lines = open(os.path.join(HERE, 'roms.asm')).read().splitlines()

    # label -> (game, filename), for the .asciz path each label points at
    paths, pending = {}, []
    for line in lines:
        m = LABEL_RE.match(line)
        if m:
            pending.append(m.group(1))
            continue
        m = PATH_RE.match(line)
        if m:
            for label in pending:
                paths[label] = (m.group(1), m.group(2))
        pending = []

    # Each C row of a game_info block is
    #     destination, source offset, length, odd-bytes file, even-bytes file
    # with the offset and length in interleaved space, so each file supplies
    # half of them.  A game may read one pair in several chunks (fatfury2 takes
    # its 2M ROMs a megabyte at a time), so the file has to reach the highest
    # source offset any row asks of it.
    sizes = collections.defaultdict(int)
    game = None
    for line in lines:
        m = INFO_RE.match(line)
        if m:
            game = m.group(1)
            continue
        if game is None:
            continue
        m = DCL_RE.match(line)
        if not m:
            game = None
            continue
        fields = [f.strip() for f in m.group(1).split(',')]
        if len(fields) == 5 and fields[3] in paths and fields[4] in paths:
            try:
                end = (int(fields[1], 0) + int(fields[2], 0)) // 2
            except ValueError:
                continue
            for label in fields[3:5]:
                sizes[paths[label]] = max(sizes[paths[label]], end)

    games = collections.defaultdict(dict)
    for game, name in paths.values():
        if not name.endswith(GENERATED):
            games[game][name] = sizes.get((game, name))
    return games


def members(mame, game):
    """Basename -> ZipInfo for the zip that holds this game's ROMs."""
    zp = os.path.join(mame, SOURCE_ZIP.get(game, game) + '.zip')
    if not os.path.exists(zp):
        return None, zp
    with zipfile.ZipFile(zp) as z:
        return {os.path.basename(i.filename).lower(): i
                for i in z.infolist() if not i.is_dir()}, zp


def install(mame, only=None):
    games = read_roms_asm()
    if only:
        unknown = sorted(set(only) - set(games))
        if unknown:
            sys.exit('not games in roms.asm: %s' % ', '.join(unknown))
        games = {g: v for g, v in games.items() if g in only}

    done, problems = [], []
    for game in sorted(games):
        have, zp = members(mame, game)
        if have is None:
            problems.append('%-10s no such zip: %s' % (game, zp))
            continue
        outdir = os.path.join(HERE, game)
        os.makedirs(outdir, exist_ok=True)
        count = 0
        with zipfile.ZipFile(zp) as z:
            for name, expect in sorted(games[game].items()):
                src = RENAMES.get(game, {}).get(name, name)
                info = have.get(src.lower())
                if info is None:
                    problems.append('%-10s %s: not in %s' %
                                    (game, name, os.path.basename(zp)))
                    continue
                if expect is not None and info.file_size != expect:
                    problems.append('%-10s %s: %d bytes, roms.asm wants %d' %
                                    (game, name, info.file_size, expect))
                    continue
                out = os.path.join(outdir, name)
                if not (os.path.exists(out) and
                        os.path.getsize(out) == info.file_size):
                    with z.open(info) as fsrc, open(out, 'wb') as fdst:
                        while True:
                            chunk = fsrc.read(1 << 20)
                            if not chunk:
                                break
                            fdst.write(chunk)
                count += 1
        done.append((game, count, len(games[game])))

    zp = os.path.join(mame, BIOS_ZIP + '.zip')
    if os.path.exists(zp):
        with zipfile.ZipFile(zp) as z:
            info = next((i for i in z.infolist()
                         if os.path.basename(i.filename).lower() == BIOS), None)
            if info is None:
                problems.append('%-10s %s: not in %s.zip' %
                                ('bios', BIOS, BIOS_ZIP))
            else:
                with z.open(info) as fsrc:
                    open(os.path.join(HERE, BIOS), 'wb').write(fsrc.read())
    else:
        problems.append('%-10s no such zip: %s' % ('bios', zp))

    ok = [d for d in done if d[1] == d[2]]
    print('installed %d/%d games (%d of %d files)' %
          (len(ok), len(done), sum(d[1] for d in done),
           sum(d[2] for d in done)))
    for line in problems:
        print('  ! ' + line)
    return 1 if problems else 0


if __name__ == '__main__':
    args = sys.argv[1:]
    root = DEFAULT_MAME
    if args and os.path.isdir(args[0]):
        root, args = args[0], args[1:]
    sys.exit(install(root, args or None))
