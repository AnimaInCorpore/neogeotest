#!/usr/bin/env python3
r"""Prepare neogeotest sources for vasm's std syntax module (vasmm68k_std).

neogeotest was written for GNU-as-style syntax with `|` comments; vasm 1.9d's
std module accepts the dotted directives but not three things this tree uses:

  1. C-style /* ... */ block comments  -> rewritten to ';' line comments.
  2. '|' comments -> ';' (std only knows ';' and '#' as comment starters).
     Every '|' outside a string literal is a comment: GNU as m68k reserves the
     character, so it is never bitwise-or here.  Leaving an inline one in place
     is not safe -- std parses it as part of the operand, which merely warns
     ("trailing garbage") after an instruction but silently ORs in the comment
     text after a dc.w.
  3. String escapes inside .ascii/.asciz ("\r\n"): vasm std aborts the literal
     at the first backslash -> escapes are emitted as separate byte operands.
  4. The GNU as m68k jump aliases (jbsr, jra, j<cc>) -> the plain b<cc> forms;
     vasm picks the branch size itself, which is what the aliases were for.
  5. Motorola dc.b/w/l and ds.b/w/l, which the sources mix in with the dotted
     directives -> .byte/.word/.long and .space.
  6. Bare 16-bit absolute short addresses for the Atari I/O registers, both
     literal (0x8006.w) and via .equ (the Blitter block, used as Endmask1.w)
     -> their sign-extended form, 0xffff8006.
  7. 0b binary literals -> hex.  std parses "0b01111110" as 0 followed by
     garbage, so this one is a silent wrong-code bug rather than an error.
  8. .end, which std does not know -> dropped (it only marks end of source).

The .include "../xxx.asm" paths in the sources resolve relative to the CWD, so
everything is assembled from stage/src/ (see build.sh).
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
FILES = ['main.asm', 'init.asm', 'emulator.asm', 'compiler.asm', 'mmu.asm',
         'roms.asm', 'bios.asm', 'xbios.asm', 'gemdos.asm', 'defines.asm']
ESCAPES = {'r': 13, 'n': 10, '0': 0, 't': 9, '"': 34, '\\': 92}
BRANCHES = ('bsr', 'ra', 'cc', 'cs', 'eq', 'ne', 'ge', 'gt', 'hi', 'le',
            'ls', 'lt', 'mi', 'pl', 'vc', 'vs')
JUMP_RE = re.compile(r'^(\s*(?:\w+:\s*)?)j(%s)\b' % '|'.join(BRANCHES))
LABEL = r'^(\s*(?:\w+:\s*)?)'
DC_RE = re.compile(LABEL + r'dc\.([bwl])(\s)')
DS_RE = re.compile(LABEL + r'ds\.([bwl])\s+(\S.*)$')
WIDTH = {'b': ('.byte', 1), 'w': ('.word', 2), 'l': ('.long', 4)}
SHORTADDR_RE = re.compile(r'\b0x([0-9a-fA-F]{1,4})\.w\b')
SHORTSYM_RE = re.compile(r'\b([A-Za-z_]\w*)\.w\b')
EQU_RE = re.compile(r'^(\s*\.equ\s+(\w+)\s*,\s*)0x([0-9a-fA-F]+)\s*$')
BINARY_RE = re.compile(r'\b0b([01]+)\b')
ALIAS_RE = re.compile(LABEL + r'j(ra|bsr)(\s+)(\S.*?)\s*$')
BRANCHABLE_RE = re.compile(r'^([A-Za-z_.][\w.]*|\d+[fb])$')


def fix_jumps(line):
    """jbsr -> bsr, jra -> bra, j<cc> -> b<cc>; jsr/jmp are left alone.

    Only a label reference can be branched to, so jra/jbsr to anything else --
    an absolute address, or (a0) -- become jmp/jsr, the fallback GNU as picks
    for the alias as well.
    """
    m = ALIAS_RE.match(line)
    if m and not BRANCHABLE_RE.match(m.group(4)):
        return '%s%s%s%s' % (m.group(1), 'jmp' if m.group(2) == 'ra' else 'jsr',
                             m.group(3), m.group(4))

    def sub(m):
        alias = m.group(2)
        return m.group(1) + (alias if alias == 'bsr' else 'b' + alias)
    return JUMP_RE.sub(sub, line)


def fix_binary(line):
    """0b01111110 -> 0x7e; vasm std knows neither 0b nor the Motorola %."""
    if '"' in line:
        return line
    return BINARY_RE.sub(
        lambda m: '0x%0*x' % ((len(m.group(1)) + 3) // 4, int(m.group(1), 2)),
        line)


def fix_equ(line, shortsyms):
    """Sign-extend an .equ that names an I/O register addressed as SYM.w."""
    m = EQU_RE.match(line)
    if m and m.group(2) in shortsyms:
        value = int(m.group(3), 16)
        if 0x8000 <= value <= 0xffff:
            return '%s0x%08x' % (m.group(1), 0xffff0000 | value)
    return line


def collect_short_symbols(sources):
    """Names used anywhere as SYM.w, i.e. via absolute short addressing."""
    return {m.group(1) for lines in sources.values() for line in lines
            for m in SHORTSYM_RE.finditer(line)}


def fix_data(line):
    """dc.<s> -> .byte/.word/.long, ds.<s> <n> -> .space <n> * <s>."""
    m = DS_RE.match(line)
    if m:
        size = WIDTH[m.group(2)][1]
        count = m.group(3).strip()
        if size > 1:
            count = '(%s) * %d' % (count, size)
        return '%s.space\t%s' % (m.group(1), count)
    return DC_RE.sub(lambda m: m.group(1) + WIDTH[m.group(2)][0] + m.group(3),
                     line)


def fix_shortaddr(line):
    """0x8006.w -> 0xffff8006.w, for the Atari I/O registers.

    Absolute short addressing sign-extends, so GNU as takes the bare 16-bit
    form; vasm range-checks the operand as signed and rejects anything above
    0x7fff.  Writing the sign-extended address out assembles to the same two
    bytes without having to turn -no-typechk on for the whole file.
    """
    if '"' in line:
        return line
    return SHORTADDR_RE.sub(
        lambda m: '0x%08x.w' % (0xffff0000 | int(m.group(1), 16))
        if int(m.group(1), 16) > 0x7fff else m.group(0), line)


def split_comment(line):
    """Split a line into code and its trailing '|' comment, if any."""
    instr, esc = False, False
    for i, ch in enumerate(line):
        if esc:
            esc = False
        elif instr and ch == '\\':
            esc = True
        elif ch == '"':
            instr = not instr
        elif ch == '|' and not instr:
            return line[:i].rstrip(), '\t; ' + line[i + 1:].strip()
    return line.rstrip(), ''


def emit_string(body, nul):
    args, plain = [], ''
    for unit in body:
        if isinstance(unit, int):
            if plain:
                args.append('"%s"' % plain)
                plain = ''
            args.append(str(unit))
        else:
            plain += unit
    if plain:
        args.append('"%s"' % plain)
    elif not args:
        args.append('""')
    if nul:
        args.append('0')
    return args


def fix_string_line(line):
    stripped = line.strip()
    kind, nulflag = None, False
    for name, nul in (('.asciz', True), ('.ascii', False)):
        if stripped.startswith(name):
            kind, nulflag = name, nul
            break
    if kind is None:
        return line
    idx = line.index(kind) + len(kind)
    head, rest = line[:idx], line[idx:]

    bodies, cur, instr, esc = [], [], False, False
    for ch in rest:
        if esc:
            cur.append(ESCAPES.get(ch, '\\' + ch))
            esc = False
            continue
        if instr and ch == '\\':
            esc = True
            continue
        if ch == '"':
            instr = not instr
            if not instr:
                bodies.append(cur)
                cur = []
            continue
        if instr:
            cur.append(ch)
    flat = [u for body in bodies for u in body]
    return head + '\t' + ','.join(emit_string(flat, nulflag))


def convert(line, inblock, shortsyms):
    if inblock:
        return ('; ' + line), ('*/' not in line)
    if line.lstrip().startswith('/*'):
        return '; ' + line, ('*/' not in line)
    if line.lstrip().startswith('|'):
        return '; ' + line, inblock
    code, comment = split_comment(line)
    if code.strip() == '.end':
        return '; ' + code + comment + '\n', inblock
    code = fix_binary(fix_jumps(code))
    code = fix_string_line(fix_data(fix_shortaddr(fix_equ(code, shortsyms))))
    return code + comment + '\n', inblock


def main():
    outdir = os.path.join(HERE, 'build')
    os.makedirs(outdir, exist_ok=True)
    sources = {f: open(os.path.join(HERE, f)).readlines() for f in FILES}
    shortsyms = collect_short_symbols(sources)
    for f in FILES:
        res, inblock = [], False
        for line in sources[f]:
            new, inblock = convert(line, inblock, shortsyms)
            res.append(new)
        open(os.path.join(outdir, f), 'w').writelines(res)
        print('preprocessed', f)


if __name__ == '__main__':
    main()
