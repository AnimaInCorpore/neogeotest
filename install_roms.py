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

ROMs alone are not enough to see anything.  The emulator draws sprites from
*compiled* tiles -- 68030 code generated per tile -- and compile_tiles() only
compiles a tile whose bit is set in the tiles-usage bitmap it loads from
"<game>\<game>.ubm".  That bitmap is a profile the emulator records while a
game runs and writes on exit.  Without it the very first run compiles nothing,
saves an all-zero "<game>\<game>.tls", and -- because compile_tiles() returns
early whenever a .tls opens -- every later run loads those zeros and draws
nothing but the backdrop.  So the caches are staged from the author's own
distribution archive (DIST_ZIP) when it is present; see install_cache().

Usage: python3 install_roms.py [<mame-rom-dir>] [game ...]
"""
import collections
import contextlib
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_MAME = 'G:/MAME/roms'
BIOS = 'sp-s2.sp1'
BIOS_ZIP = 'neogeo'
GENERATED = ('.tls', '.ubm')

# The author's own release.  Not a ROM set: it carries the compiled-tile
# caches (.tls) and tiles-usage bitmaps (.ubm) that cannot be derived from the
# ROMs, plus sfix.sfi.  Optional -- the ROMs install without it.
DIST_ZIP = os.path.join(HERE, 'neogeo_full.zip')
DIST_EXTRA = ('sfix.sfi', BIOS)

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


def dist_index(archive=DIST_ZIP):
    """game -> {lowercase basename: member name} for the distribution archive.

    Preferred over the MAME set wherever it has the file: it is laid out under
    exactly the names roms.asm asks for, so it needs no RENAMES entry, and for
    bangbead/ganryu/sengoku3 it carries the decrypted C-ROMs that a current
    MAME set no longer ships under those names.
    """
    if not os.path.exists(archive):
        return {}
    out = collections.defaultdict(dict)
    with zipfile.ZipFile(archive) as z:
        for name in z.namelist():
            part = name.split('/')
            if len(part) == 3:
                out[part[1].lower()][part[2].lower()] = name
    return out


def install_cache(archive=DIST_ZIP, only=None):
    """Stage .tls/.ubm caches (and sfix.sfi) from the author's distribution.

    Laid out as NEOGEO/<GAME>/<GAME>.TLS; names are folded to lower case to
    match what roms.asm opens.  A game directory that install() did not create
    is skipped rather than invented -- the caches are useless without ROMs.
    """
    if not os.path.exists(archive):
        return ['%-10s no distribution archive: %s' % ('cache', archive)]
    problems, count = [], collections.Counter()
    with zipfile.ZipFile(archive) as z:
        for name in z.namelist():
            part = name.split('/')
            base = part[-1].lower()
            if len(part) == 2 and base in DIST_EXTRA:
                out = os.path.join(HERE, base)
            elif len(part) == 3 and base.endswith(GENERATED):
                game = part[1].lower()
                if only and game not in only:
                    continue
                if not os.path.isdir(os.path.join(HERE, game)):
                    continue
                out = os.path.join(HERE, game, base)
            else:
                continue
            with z.open(name) as fsrc, open(out, 'wb') as fdst:
                while True:
                    chunk = fsrc.read(1 << 20)
                    if not chunk:
                        break
                    fdst.write(chunk)
            count[os.path.splitext(base)[1]] += 1
    print('staged caches: %s' % (dict(count) or 'none'))
    return problems


def install(mame, only=None):
    games = read_roms_asm()
    if only:
        unknown = sorted(set(only) - set(games))
        if unknown:
            sys.exit('not games in roms.asm: %s' % ', '.join(unknown))
        games = {g: v for g, v in games.items() if g in only}

    dist = dist_index()
    done, problems, from_dist = [], [], 0
    for game in sorted(games):
        have, zp = members(mame, game)
        if have is None and game not in dist:
            problems.append('%-10s no such zip: %s' % (game, zp))
            continue
        outdir = os.path.join(HERE, game)
        os.makedirs(outdir, exist_ok=True)
        count = 0
        mz = zipfile.ZipFile(zp) if have is not None else None
        with contextlib.ExitStack() as stack:
            if mz is not None:
                stack.enter_context(mz)
            dz = None
            if game in dist:
                dz = stack.enter_context(zipfile.ZipFile(DIST_ZIP))
            for name, expect in sorted(games[game].items()):
                # The distribution wins: it stores files under the names
                # roms.asm uses, so no rename can go wrong there.
                z, member = None, dist.get(game, {}).get(name.lower())
                if member is not None:
                    z, info = dz, dz.getinfo(member)
                    from_dist += 1
                elif have is not None:
                    src = RENAMES.get(game, {}).get(name, name)
                    info = have.get(src.lower())
                    z = mz
                else:
                    info = None
                if info is None:
                    problems.append('%-10s %s: in neither %s nor the archive' %
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

    # Before the BIOS check: the archive carries sp-s2.sp1 and sfix.sfi at its
    # root, so a tree staged from it needs no MAME neogeo.zip at all.
    problems += install_cache(only=only)

    zp = os.path.join(mame, BIOS_ZIP + '.zip')
    if os.path.exists(os.path.join(HERE, BIOS)):
        pass                      # already staged, from the archive or before
    elif os.path.exists(zp):
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
    print('installed %d/%d games (%d of %d files, %d from the archive)' %
          (len(ok), len(done), sum(d[1] for d in done),
           sum(d[2] for d in done), from_dist))
    for line in problems:
        print('  ! ' + line)
    return 1 if problems else 0


if __name__ == '__main__':
    args = sys.argv[1:]
    root = DEFAULT_MAME
    if args and os.path.isdir(args[0]):
        root, args = args[0], args[1:]
    sys.exit(install(root, args or None))
