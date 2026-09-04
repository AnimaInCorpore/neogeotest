# 68030 MMU: stale stage-B opcode executed at the interrupt vector after a frame-$B bus fault

Report against Hatari's WinUAE-derived CPU core. **Root cause found and fixed**;
the trigger site is shared UAE code, so the first patch below is believed to be
an upstream WinUAE defect, not a Hatari divergence.

The observed event is a single mis-paired instruction dispatch: an `RTE` from a
format-$B (long) bus fault arms a retry and restores the frame's stage-B opcode;
an interrupt is then taken before the retry dispatches; and the preserved opcode
is executed at the *interrupt vector's* PC instead of at the faulted
instruction. The resulting bogus branch target is unmapped, and the guest wedges.

## Environment

| | |
| --- | --- |
| Hatari | `2.6.1-devel`, fork `AnimaInCorpore/hatari` @ `021ed365` |
| CPU core | WinUAE 6.1.0 beta11+ (2026/08/07), per `src/cpu/winuae_readme.txt` |
| Host | Windows 11, MSYS2 UCRT64, CMake Release |
| Machine | `--machine falcon --tos tos404.img --memsize 14 --ttram 0 --cpulevel 3 --mmu true` |
| Modes | `cachesize=0`, `cpu_compatible=1`, `cpu_memory_cycle_exact=1` (so the `m68k_do_rte_mmu030c` prefetch path is the one in use) |

## Guest

`third_party/neogeotest` — a Neo Geo emulator for the Atari Falcon (S. Springer,
pre-alpha 20131230). **These sources are confirmed to run correctly on real
Falcon hardware.** It emulates Neo Geo hardware by installing its own 68030
translation tree, marking the Neo Geo I/O pages invalid, and servicing each
access from its bus error handler: it decodes SSW plus the frame's fault
address, supplies read data via the frame's data input buffer at `+$2c`, clears
SSW's DF bit to say "access already performed", and `RTE`s.

This is an unusually strict exerciser of the 030 fault/resume path: it takes
*every* Neo Geo access as a bus fault, tens of thousands per second, with VBL
and HBL interrupts live throughout. Any window between "RTE arms a retry" and
"the retry dispatches" is hit constantly.

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

Entry 103 is the intended behaviour: the `RTE` restores the opcode `$51C9` and
the PC of the faulted `dbf`, and the retry executes it there.

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

## Root cause

`insretry` in `m68k_run_mmu030()` (`newcpu.c`) selects the opcode in this order:

```
mmu030_fake_prefetch  ->  mmu030_opcode_stageb  ->  regs.irc
```

`mmu030_opcode_stageb` outranks `regs.irc`. It is set unconditionally by the
frame-$B restore in `m68k_do_rte_mmu030c()` (`cpummu030.c`, ~line 3398):

```c
regs.prefetch020[2] = stagesbc;
regs.prefetch020[1] = stagesbc >> 16;
regs.prefetch020[0] = oc >> 16;
mmu030_opcode_stageb = (uae_u16)oc;     /* <-- survives an intervening exception */
```

`Exception_mmu030()` (`newcpu.c`) then does the right thing for the *pipe* but
not for this variable:

```c
m68k_setpci (newpc);
fill_prefetch ();          /* refreshes regs.irc for newpc -- measured correct */
exception_check_trace (nr);
```

So when an interrupt lands in the window between the `RTE` and the retry
dispatch, `regs.irc` is correctly refreshed to the vector's first opcode while
`mmu030_opcode_stageb` still holds the *previous* instruction stream's stage-B
word — and because stage B wins, the stale word is what executes.

Tagging which branch of the run loop supplied `regs.opcode` catches it directly:

```
tag=4 pc=00500292 irc=FFFF op=FFFF     healthy: stageb=-1 -> takes irc
tag=4 pc=00500BF6 irc=FFFF op=51C9     broken:  stageb=$51C9 stale
tag=3 pc=00500BF6 irc=48E7 op=51C9     irc CORRECT; stageb won anyway
```

The last line is the whole bug in one row: `regs.irc` is right, and it is not
the value used.

Neither the ordering in `insretry` nor the assignment in
`m68k_do_rte_mmu030c()` is inside `#ifdef WINUAE_FOR_HATARI`. This one looks
like an upstream WinUAE defect that Hatari inherits.

## The fix

`newcpu.c`, `Exception_mmu030()`:

```diff
 	m68k_setpci (newpc);
 	fill_prefetch ();
+	// The exception has moved the PC and fill_prefetch() has reloaded the pipe
+	// for it. A stage B opcode captured before the exception belongs to the old
+	// instruction stream, but insretry prefers mmu030_opcode_stageb over
+	// regs.irc, so it would be dispatched at the vector's PC. Drop it.
+	mmu030_opcode_stageb = -1;
 	exception_check_trace (nr);
```

Invalidating the stage-B latch at the same point the pipe is reloaded keeps the
two consistent: after an exception, the only valid opcode source for the new PC
is the one `fill_prefetch()` just produced.

## Two further local patches (prerequisites, must be disclosed)

The defect above is observed *with* these applied; without them the guest does
not get far enough to reach it.

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
   instruction). This block *is* inside `#ifdef WINUAE_FOR_HATARI`, so upstream
   WinUAE does not have it; that divergence is Hatari's.

## Effect

All three patches, same guest, same command line:

| | before | after |
| --- | --- | --- |
| furthest guest PC reached | wedged in BIOS at `$C1100C` | runs past it |
| framebuffer non-zero bytes | 0.00 % | 51.95 % |
| speed | 45 VBL/s | 170.6 VBL/s |
| screen | black | Neo Geo display area drawn |

Total diff: 31 insertions across three files.

Those numbers were taken before a guest-side problem unrelated to the CPU core
was found: the emulator's compiled-tile cache had been poisoned by an earlier
wedged run, so it drew only a flat backdrop. With a valid cache the same build
renders the Neo Geo BIOS logo (VBL 1000), then Metal Slug's attract mode and
title screen (VBL 3000 / 6000), 126 distinct colours on screen. Mentioning it
because it is the sort of thing that makes a "still broken" report out of a
working fix — the emulation was correct at the point those numbers were taken.

## What was excluded

Each candidate was instrumented and measured, not reasoned about:

| candidate | measurement | result |
| --- | --- | --- |
| stale icache holding register | invalidate `regs.cacheholdingaddr020` on resume | no change |
| inconsistent resume pipe | defer `fill_prefetch_030_ntx()` until after retirement | no change |
| resume pending at exception entry | log `mmu030_retry`/`mmu030_opcode` in `Exception_mmu030()` | always `retry=0 opcode=-1` |
| resume applied at wrong PC | guard the retry on `m68k_getpci()` == the RTE's restored PC | guard never fires |
| stale `regs.irc` feeding `insretry` | log `regs.irc` around the exception's `fill_prefetch()` | `irc_after=$48E7`, correct — which is what pointed at stage B instead |

`Exception_mmu030()`'s `fill_prefetch()` is correct — measured for both
interrupts the guest hooks, the resulting pipe matches the real code bytes:

| vector | newpc | pipe after refill | code there |
| --- | --- | --- | --- |
| 28 (VBL) | `$500BF6` | `C080/203A/0094` | `48E7 C080 203A 0094` |
| 26 (HBL) | `$500BF0` | `0300/4E73/48E7` | `or #$0300,(sp)` / `rte` |

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

Trigger on the anomalous condition, not on a counter.

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
