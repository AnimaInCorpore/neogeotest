# 68030 MMU: stale opcode executed at the interrupt vector after a frame-$B bus fault

Report against Hatari's WinUAE-derived CPU core. The observed event is a single
mis-paired instruction dispatch: after an `RTE` from a format-$B (long) bus
fault arms a retry, an interrupt is taken, and the preserved opcode is then
executed at the *interrupt vector's* PC instead of at the faulted instruction.
The resulting bogus branch target is unmapped, and the guest wedges.

## Environment

| | |
| --- | --- |
| Hatari | `2.6.1-devel`, fork `AnimaInCorpore/hatari` @ `021ed365` |
| CPU core | WinUAE 6.1.0 beta11+ (2026/08/07), per `src/cpu/winuae_readme.txt` |
| Host | Windows 11, MSYS2 UCRT64, CMake Release |
| Machine | `--machine falcon --tos tos404.img --memsize 14 --ttram 0 --cpulevel 3 --mmu true` |
| Modes | `cachesize=0`, `cpu_compatible=1`, `cpu_memory_cycle_exact=1` (so the
`m68k_do_rte_mmu030c` / `..._state` prefetch path is the one in use) |

## Guest

`third_party/neogeotest` — a Neo Geo emulator for the Atari Falcon (S. Springer,
pre-alpha 20131230). **These sources are confirmed to run correctly on real
Falcon hardware.** It emulates Neo Geo hardware by installing its own 68030
translation tree, marking the Neo Geo I/O pages invalid, and servicing each
access from its bus error handler: it decodes SSW plus the frame's fault
address, supplies read data via the frame's data input buffer at `+$2c`, clears
SSW's DF bit to say "access already performed", and `RTE`s.

## Local CPU-core patches (must be disclosed — the bug is observed *with* these)

Two changes were needed to get this far. Both are in the repo as a 26-line diff.

1. **`gencpu.c`, `genastore_2()`** — suppress the last-write/format-$A path for
   absolute addressing only:

   ```c
   if (!(flags & GF_NOFAULTPC)) {
       bool abs_ea = (mode == absw || mode == absl);
       gen_set_fault_pc (false, abs_ea);
   }
   ```

   Rationale: with `MMU68030_LAST_WRITE` applied to `absw`/`absl`, a faulting
   `move.b Dn,(xxx).L` is reported as format $A with the PC advanced past the
   instruction. Real hardware reports format $B with the PC *at* it. The guest's
   handler encodes this distinction empirically — it identifies the faulting
   opcode at `(a0)` for `13C0`/`13FC` (absolute) but at `-2(a0)`/`-4(a0)` for
   `1080`/`10BC` (register indirect) — and that table was derived on hardware.
   Verified in generated `cpuemu_32.c`: `LASTWRITE` now emitted for `op_1080`
   and `op_10bc`, not for `op_11c0`/`op_13c0`/`op_13fc`.

2. **`cpummu030.c`, `m68k_do_rte_mmu030c()`** — gate the Hatari-local `[NP]`
   frame-$B prefetch fixup on the fault still needing to be redone:

   ```c
   if (frame == 0xb) {
       if (ssw & MMU030_SSW_DF) {
           mmu030_opcode = -1;
           fill_prefetch_030_ntx();
       }
   }
   ```

   Rationale: with DF cleared by the handler, that fixup makes continuation
   impossible three ways — `mmu030_opcode = -1` routes the run loop through
   `insretry`; `fill_prefetch_030_ntx()` itself does
   `mmu030_idx = mmu030_idx_done = 0`, so the emulated access is repeated and
   the instruction never retires; and the refill re-reads the instruction
   stream, splicing freshly-read words into the access being resumed (visible as
   a computed EA of `$4E714E71` — two `NOP`s — when the handler had patched the
   instruction). Note this block is inside `#ifdef WINUAE_FOR_HATARI`, so
   upstream WinUAE does not have it; the divergence is Hatari's.

## The defect

Ring buffer of the last 128 executed `(m68k_getpci(), regs.opcode)` pairs,
recorded in the `m68k_run_mmu030()` inner loop and dumped on the first
supervisor-program (`FC=6`) fetch fault:

```
102 pc=00500292 op=4E73     rte at end of the guest's bus_error_handler
103 pc=00C18394 op=51C9     resumes the guest's dbf d1 at $C18394     <- correct
...
126 pc=00500292 op=4E73     rte again
127 pc=00500BF6 op=51C9     PC = vbl_handler entry, opcode STILL 51C9 <- wrong
```

Entry 103 is the intended behaviour: the `RTE` restores `mmu030_opcode = $51C9`
and the PC of the faulted `dbf`, and the retry executes it there.

Entry 127 is the bug: between the `RTE` and the retry, the level-4 VBL is taken.
The PC becomes `$500BF6` (the guest's `vbl_handler`, whose real opcode is
`$48E7`, `movem.l d0-d1/a0,-(sp)`), but `regs.opcode` is still the preserved
`$51C9`.

`dbf` at `$500BF6` therefore takes its 16-bit displacement from `$500BF8`, which
holds `$C080` — the second word of that `movem.l`:

```
$500BF8 + (int16)$C080 = $500BF8 - $3F80 = $4FCC78
```

`$4FCC78` is exactly the faulting fetch address, and it is outside the guest's
mapped code (`emulator.o` `.text` is `$F80` bytes based at `$500000`). Every
subsequent fetch there faults; the guest is wedged.

```
FETCHFAULT fetch=004FCC78 livepc=004FCC78 opcode=51C9
```

## What was excluded

Each candidate was instrumented and measured, not reasoned about:

| candidate | measurement | result |
| --- | --- | --- |
| stale icache holding register | invalidate `regs.cacheholdingaddr020` on resume | no change |
| inconsistent resume pipe | defer `fill_prefetch_030_ntx()` until after retirement | no change |
| resume pending at exception entry | log `mmu030_retry`/`mmu030_opcode` in `Exception_mmu030()` | always `retry=0 opcode=-1` |
| resume applied at wrong PC | guard the retry on `m68k_getpci()` == the RTE's restored PC | guard never fires |
| stale `regs.irc` feeding `insretry` | log `regs.irc` around the exception's `fill_prefetch()` | `irc_after=$48E7`, correct |

`Exception_mmu030()`'s `fill_prefetch()` is also correct — measured for both
interrupts the guest hooks, the resulting pipe matches the real code bytes:

| vector | newpc | pipe after refill | code there |
| --- | --- | --- | --- |
| 28 (VBL) | `$500BF6` | `C080/203A/0094` | `48E7 C080 203A 0094` |
| 26 (HBL) | `$500BF0` | `0300/4E73/48E7` | `or #$0300,(sp)` / `rte` |

## Where the stale opcode enters: `insretry` via `regs.irc`

Tagging which branch of the run loop supplied `regs.opcode`, and triggering on
the anomaly itself rather than on a sample count, catches it directly:

```
ANOMALY#1 pc=00500BF6 opcode=51C9 src=1 mmuop=000051C9 irc=51C9
```

`src=1` is the `insretry` path. So with the PC already moved to the interrupt
vector `$500BF6`, `insretry` executed

```c
if (currprefs.cpu_compatible)
    regs.opcode = regs.irc;
```

with `regs.irc` still holding `$51C9` — the previous instruction's opcode.

This matters because `regs.irc` is written by the resume machinery itself.
`m68k_do_rte_mmu030c()` does, right after restoring the PC:

```c
m68k_setpci (pc);
if (mmu030_opcode != -1) {
    regs.opcode = regs.irc = mmu030_opcode;   // <-- irc := the resumed opcode
}
```

Tagging each dispatch with a global count of `Exception_mmu030()` entries shows
the full sequence. Ring of the last dispatches before the anomaly:

```
44 pc=0050028C op=3081 irc=3081 src=1 exc=13649
45 pc=0050028E op=4CDF irc=4CDF src=1 exc=13649
46 pc=00500292 op=4E73 irc=4E73 src=1 exc=13649   <- the rte
47 pc=00500BF6 op=51C9 irc=51C9 src=1 exc=13650   <- anomaly, one exception later
```

So, measured end to end:

1. The `rte` at `$500292` sets `regs.irc = mmu030_opcode = $51C9` and rewinds
   the PC to the faulted instruction.
2. **Exactly one** exception intervenes before the resume dispatches — the
   level-4 VBL — which sets the PC to `$500BF6`.
3. `insretry` then takes `regs.opcode = regs.irc` and gets the stale `$51C9`.

The one unresolved link: `Exception_mmu030()` calls `fill_prefetch()` after
`m68k_setpci(newpc)`, and that *was* measured to refresh `regs.irc` correctly at
this very PC (`irc_before=$4EBA → irc_after=$48E7` for `newpc=$500BF6`,
`cachesize=0 compat=1`). On the occasion that produces the anomaly it evidently
does not stick. Whether that is an ordering problem inside the exception path, or
a later write restoring the old value, is the remaining question — and it is now
a question about two adjacent lines rather than about the MMU.

### Methodology warning for anyone re-running these probes

Two earlier probes returned false negatives because they were capped at the
first N events while the anomaly occurs later:

- logging the opcode `insretry` chooses at `$500BF6`/`$500BF0` — the first 8 are
  all correct (`48E7` / `0057`, both from `irc`), which wrongly appears to
  exclude this path;
- logging the PC either side of the execute step for every `RTE` that armed a
  retry — the first 8 are all healthy resumes (`pc_after` = the faulted
  instruction, `regs.opcode == mmu030_opcode`), which wrongly appears to exclude
  an interrupt interleaving there. That exclusion should be treated as
  **inconclusive**, not proven.

Trigger on the anomalous condition, not on a counter. `cpu_cycle_exact` is
confirmed set, so the execute step is `(*cpufunctbl_noret[])` +
`wait_memory_cycles()`.

## Reproduction

```sh
cd third_party/neogeotest
./build.sh                     # needs vasmm68k_std + vlink
python3 install_roms.py        # stages Neo Geo ROMs from a MAME set
./run.sh mslug
```

Add the ring buffer to `m68k_run_mmu030()`'s inner loop (record after
`mmu030_retry = false;`) and dump it from `mmu030_page_fault()` on the first
`fc == 6` fault.

## Notes for anyone instrumenting this

- `regs.instruction_pc` is assigned only at `insretry`, so it is stale during a
  retry iteration. Log `m68k_getpci()` alongside it — an earlier pass of this
  investigation chased the wrong instruction for exactly this reason.
- `write_log()` is `Log_Printf(LOG_DEBUG, ...)`, so `--log-level debug` is
  required to see anything; `MMUDEBUG` in `src/cpu/mmu_common.h` enables the
  existing fault trace.
- Do not score progress as "executions of instruction X dropped to zero" — that
  also happens when the guest stops *reaching* X, which made one regression look
  like a fix.
