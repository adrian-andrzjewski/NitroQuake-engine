# Harness fidelity, the gate, and the legal-BIOS question (2026-09-30)

Extracted verbatim from `ASM486-HANDOFF.md` lines 1762-2126 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## Harness integrity and the measured fidelity result (2026-09-30) — the gate problem is now measured, not asserted

The conclusion at `:775` — stop optimizing against this harness, because it
cannot see what a 486 pays — is now backed by an executable measurement rather
than an argument. This entry records the tooling that establishes it, because
the next passes depend on it.

**Three harness defects fixed first**, since every other number in this ledger
depends on them:

1. **The stale-binary hazard is closed.** `timedemo-dos.ps1` built only
   `if (-not (Test-Path $benchmarkExe))`, keyed on the selector profile alone,
   so a source edit was silently ignored and the previous binary measured (see
   the warning under "**THE TIMEDEMO RUNNER WILL NOT REBUILD AFTER A SOURCE EDIT**"). It now hashes all 163 `.c`/`.s`/`.h` files plus the
   resolved selectors into a fingerprint stored beside the executable, and
   rebuilds on mismatch. **Note there is no `-Clean` switch** — verified; the
   documented remedy did not exist, and that warning and `BUILD-DOS.md` should be
   read with that in mind.
2. **The recorded-but-unenforced constants now fail the run** (`timedemo-dos.ps1`, grep `ExpectedProfileSha256`).
   `timedemo-dos.ps1` compares the profile SHA-256 against
   `F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` and gates
   every run on 969 frames and framebuffer checksum `1047377823`. A wrong value
   fails the run rather than reporting a time; `-AllowGateOverride` records a
   deliberate exception and warns.
3. **Per-function attribution is available.** The link strips with `-s`
   (grep `-s` in `build-dos.ps1` for the line), so the header of `486-cost-model.ps1` could only report
   image totals. The build already retains 103 objects under
   `out\dos<profile>\obj-bench`, so the cost model now disassembles those and
   reports per-symbol x87 cost (new section 1b). `-s` is kept; dropping it would
   perturb an already non-reproducible image.

**Four in-engine probes** (`src\core\host_cmd.c`, `-benchfidelity`, dispatched
via `+bench486`) whose 486 costs are known, used to judge whether an emulator
prices them at all:

| probe | measures |
|---|---|
| `x87chain` | a serialized x87 chain with a real FDIV, the `d_draw16.s:145-198` shape |
| `fpu fistp32` vs `fist16` | 32-bit against 16-bit float-to-int store; the model prices `fistp` at 39 cy |
| `l1-4096` vs `l1-24576` | 4 KB working set (fits the 8 KB L1) against one that cannot |
| `alias-0` vs `alias-64` | two buffers sharing an L1 set against two that do not; the `vid_vga.c:299-304` shape |

**DOSBox-X scores 0 of 4** (`out\fidelity-dosbox-x.json`):

```text
fidelity x87chain   748.1 ns/op
fidelity fpu fistp32 329.2 ns/op
fidelity fpu fist16  329.2 ns/op     -> 1.000x separation
fidelity l1-4096    179.7 ns/op
fidelity l1-24576   179.7 ns/op      -> 1.000x separation
fidelity alias-0    239.5 ns/op
fidelity alias-64   239.5 ns/op      -> 1.000x separation
```

The three 1.000x results are exact ties, not noise: **DOSBox-X has no cache
model whatsoever**, so neither L1 capacity nor set aliasing can move its clock.
`fistp32` and `fist16` tying at 329.2 ns is the flat-FPU model stated directly.
Only the x87 chain separates, at 2.272x, which is closer to the op-count ratio
than to the latency ratio a 486DX charges.

**This is the correct and expected result.** DOSBox-X remains the **parity gate**
— checksum, frame count, functional correctness — where its flat FPU does not
make it *wrong*, only insensitive. It cannot also price 486 costs, and no
lawful automated harness here can supply that measurement instead, as the
sourcing research below establishes.

**The probes were validated on real x86 silicon, and they are sound.**
`tools\fidelity-probe-host.c` is a host-native build of the same four probes,
runnable with `gcc -O2 -march=native -o out\fidelity-probe-host.exe
tools\fidelity-probe-host.c`. Run on this machine (AMD Ryzen 5 3600, Zen 3):

```text
fidelity x87chain  4.66 ns/op
fidelity fpu fistp32  10.89 ns/op
fidelity fpu fist16    9.58 ns/op   -> fistp32/fist16 = 1.136x   PASS
fidelity l1-4096     0.35 ns/op
fidelity l1-24576    0.46 ns/op   -> 1.342x                    PASS
fidelity alias-0     0.55 ns/op
fidelity alias-64    0.53 ns/op   -> 1.034x                    (below the 1.05 gate)
```

**This is the control the DOSBox-X 0/4 result needed.** The probes do detect a
real FISTPL/FIST latency gap and a real L1 capacity cliff when the hardware has
one, so the ties under DOSBox-X are the *emulator's* blind spots rather than
broken probes. The two that do not separate here fail for an instructive reason:
a Zen 3 has a 32 KB L1d and a hardware prefetcher, so a 4 KB versus 24 KB
working set and a 2048-byte set conflict both sit far below its thresholds.
**The probes are calibrated to 486 geometry; this host is not a 486.** That is
precisely the class of difference DOSBox-X cannot express either.

It also bounds what a modern host can be used for: it can validate probe design,
and it cannot stand in for a 486 reference.

### Legal sources for a 486 machine ROM (not pursued here)

Asked to source a 486 machine BIOS, the answer is that the copyrighted-vendor
images are not something to fetch: every machine profile wants a specific
third-party firmware image (AMI, Award, Phoenix, ALi, IBM, SiS, VIA), and the
sites that host them distribute them without permission. Emulators in this
class state that they will never bundle them, and that position is the correct
one.

What is legitimate, if 486 pricing is wanted:

- **A physical 486 machine**, dumping its own ROM. This is the best option: it
  settles every axis, including the ones no emulator models, and the project's
  ledger already recommends a real 486DX2/DX4 as the honest arbiter.
- **A ROM the user already owns**, from a machine in their possession.
- **A freely-licensed BIOS** where an emulator supports one. 86Box is
  ROM-dependent by design, so this is not a general escape.

None of these is available to an automated pass, which is why the pricing gap is
recorded as measured-and-unclosable rather than forced.

## Sourcing research: the legal-BIOS question, answered (2026-09-30)

Because the ROM route is closed, the obvious hope is a ROM-free emulator that is
still cycle-accurate. Researched and **eliminated**, with the decisive evidence
rather than a summary:

**Bochs ships a GPL BIOS and needs no third-party ROM — and is disqualified by
its CPU model.** Its `bochs/cpu/cpu.h` (6151 lines) has **no data cache
whatsoever**: no `bxDCache`, no `bxCache_c`, no set index, no tag array, no
associativity. The only cache class is `bxICache_c` (`:428-429`, `:1442`), and
that is a fetch-unit trace cache, not a set-associative L1. `CACHE_LINE_SIZE` is
a hardcoded `const 64` (`:421`) used only for UMONITOR alignment (`:879`) — and
64 bytes is wrong for a 486 regardless, which has 32-byte lines. There is no
cache configuration option of any kind. The x87 is softfloat (`i387_t` at
`:1100-1101`, `softfloat_status_t` at `:837`) for correctness only, with no
latency model, and `icount` (`:1002`) is incremented by 1 per instruction
(`:6105-6109`) with **no cycle concept anywhere** — grepping
`cycle|latency|stall|ips` over the whole file returns one hit, an unrelated
comment.

So Bochs would score 0/4 on the fidelity suite, for the same reason DOSBox-X
does: it has no data cache and a free FPU. It also has the wrong line size and
the wrong associativity even if a cache existed. **Do not install Bochs as a
486-cost reference.**

**SeaBIOS is GPL and is QEMU's default, but it does not help.** It targets
QEMU's own virtual hardware (i440fx/q35, `fw_cfg`, virtio) and is used by no
period-ISA emulator, so it is not a general escape. QEMU's TCG is, like DOSBox-X,
an instruction-count model with a flat FPU and no cache — it would fail the
same probes. Booting DOS under it is possible but buys nothing for this
project.

**Net conclusion, and it is the honest one:** there is **no legally-obtainable,
ROM-free, cycle-accurate 486 emulator** available. Emulators that model 486
cache and FPU latency (86Box) are ROM-dependent by design, because that
hardware's behaviour is defined by the firmware. Emulators that are ROM-free
(Bochs, QEMU) are not cycle-accurate. The two properties are not separable
without either a BIOS the user owns or real hardware.

That is a stronger result than "we did not find one", and it should end the
search rather than license a repeat of it. The measurement gap is real, it is
now measured (0/4), and it is **not closable within this project's constraints**.

**What this means for the plan.** The Phase 3/Phase 4 candidates stay
unimplemented, and the reason is now stronger than "we lack a measurement":
the available legal harnesses cannot supply the measurement at all, so any
candidate built now would rest on published latencies alone. That is
precisely the reasoning error the ledger documents for the Z-span prologue
(`:799-800`), where an instruction-count estimate said 7.8% and the truth was
0.71%. **The honest position is that the renderer is converged, the reason is
now proven rather than asserted, and the remaining 486-specific wins are real but
unclaimable without hardware the project does not have.**

## 86Box, verified against source (2026-09-30) — the best ROM-free candidate, still disqualified

86Box was the strongest remaining hope, and it was checked properly rather than
dismissed. It is GPL and its emulator is freely installable; the problem is the
same ROM dependency plus a cache model that does not exist.

**The `_cache[2048]` array is not a cache.** This is the load-bearing fact and it
is easy to get wrong from a name. Declared `src/cpu/cpu.c:289-290` (externs at
`cpu.h:640-641`). Its only uses repo-wide are in Pentium-era test-register
emulation, `src/cpu/x86_ops_mov_ctrl.h:424-425`:

```c
_tr[3]      = *(uint32_t *) &(_cache[cache_index]);
cache_index = (cache_index + 4) & 0xf;
```

`cache_index` is a **rotating cursor, not derived from any address** — there is
no shift-mask, no tag array, no replacement policy, and only bytes 0-15 of the
2048-byte array are ever touched. The other 2032 bytes are dead space, and the
symbol is a leftover from an earlier emulator's test-register path. Our own grep
of `cpu.c` independently found zero uses there, which agrees.

**Cache cost is a flat per-model constant**, not a structure. `cpu_update_waitstates()`
(`cpu.c:4543-4588`) assigns one pair of numbers to every read and write
regardless of address:

```c
cpu_cycles_read  = cpu_s->cache_read_cycles;
cpu_cycles_write = cpu_s->cache_write_cycles;
```

There is no cache-size configuration anywhere; `src/config.c` mentions "cache"
only for a host-side disk cache. **86Box therefore cannot answer any capacity,
associativity, geometry, or set-conflict question at all** — a 4 KB and a 24 KB
working set cost it identically because it has no notion of capacity.

**x87 latency is genuine, and is 86Box's one real strength.** `x87_timings_486`
at `src/cpu/x87_timings.c:314` carries Intel-derived per-instruction latencies
(`.fdiv = 73`, `.fild_16 = 14`, `.fild_32 = 10`, `.fmul_32 = 11`) with a separate
`x87_concurrency_486` table for dependency busy-wait. So 86Box is markedly better
than Bochs or DOSBox-X on the x87 axis.

**But the one candidate that matters most is exactly the one 86Box cannot
distinguish.** `.fist_16` and `.fist_32` are **both 31 cycles**
(`x87_timings.c:346-347`) — there is no FIST-versus-FISTPL distinction, because
the 486 penalty is for a 16-bit *integer store destination*, not the opcode.
**Candidate C1 is precisely a 16-bit FIST substitution.** So 86Box would tie on
the exact axis the leading candidate pays for, and would also tie on all three
cache probes. It could not promote C1, and it could not promote C3 or C4 either.

**No cycle-count output and no script interface.** `-S` is `--settings`, not a
script. Automation is `--config` + `--image` + `--logfile` only, and there is no
user-facing emulated-cycle counter (`instr_counts` is a JIT block counter). So
even a legal ROM would leave the promotion signal resting on wall-clock timing,
which is unreliable for a ~31-cycle difference.

The 486 machines want the same vendor firmware as everything else —
`roms/machines/ami495/opt495sx.ami`, `roms/machines/c747/486-C747 Tandon.BIN`,
`roms/machines/pred1plus/PRED1PLUS.BIN` (`src/machine/m_at_386dx_486.c`,
`src/machine/m_at_socket3.c`). The `86box/roms` repository is exactly the
unlicensed vendor-firmware redistribution already ruled out, and its own README
carries no licensing grant at all — only contribution guidelines.

**A DOS image does not help, and this is worth stating because it looks like it
should.** A Windows-hosted DOS install is the *guest OS*, not the *BIOS*; the
firmware that defines the emulated hardware's behaviour is the thing in question,
and DOSBox-X already supplies a perfectly good guest DOS. WinWorldPC's MS-DOS
6.0/6.22 are abandonware and reasonable to use for exactly that purpose, but they
resolve nothing about the ROM. (Its 7.1 page is the China DOS Union custom
build, which the site itself notes it does not normally approve of.)

**So the three suggested routes resolve as:** 86Box's *emulator* is fine to
install but is disqualified on fidelity (no cache model; ties on C1's own axis);
the 86Box *ROMs* repo is the same copyright problem and is not a workaround; a
*DOS image* was never the missing piece. The search is closed.

## The 1800 KB surface-cache wall does not exist (2026-09-29) — root-caused, and the latent win is promoted

Four experiments in this ledger record that growing `SURFCACHE_SIZE_AT_320X200`
past 1800 KB produced checksum `2955717646` and was reverted, throwing away a
claimed 0.4-0.8% win each time. **There is no such defect.** A larger cache
renders correctly and is faster.

`D_SurfaceCacheForRes` (`d_surf.c:58-76`) already honours a runtime
`-surfcachesize <KB>` parameter, so the size can be swept with no rebuild. The
knob is provably live: `-surfcachesize 30000` fails with Quake refusing the
video mode, exactly as the memory guard at `vid_vga.c:269-276` predicts.

| cache | median time | FPS | checksum |
| ---: | ---: | ---: | --- |
| 1800 KB (previous default) | 59.264965 s | 16.350301 | `1047377823` |
| 1900 KB | 59.252435 s | 16.353759 | `1047377823` |
| **2400 KB (new default)** | **59.227329 s** | **16.360690** | `1047377823` |
| 6000 KB | 59.218547 s | 16.363117 | `1047377823` |

**Promoted: 2400 KB, 0.0635% faster, above the 0.05% gate.** Delta 0.037636 s
against a 0.000049 s run spread — roughly 770x the spread, and the checksum was
`1047377823` on all six A/B runs. 6000 KB adds only a further 0.015% for 2.5x
the memory, so 2400 KB is the knee. Instrumented, evictions fall from 2,151 to
2,122 invalidations and surface-cache self time from 7.260873 s to 7.240347 s.

**Why the historical rows were wrong.** They all report the *same* wrong
checksum `2955717646`, and this ledger already notes at `:2127` that it is
"the same hash as the reverted texture-source row-lookup" — an unrelated bug's
signature. A genuine cache-size-dependent defect would not reproduce one
unrelated bug's exact checksum at four different sizes. Those runs were
confounded by an experimental build that was itself rendering incorrectly; the
cache size was an incidental variable. **Do not re-investigate a cache-size
correctness bug; there is none.**

**Raising the default does not weaken the low-memory guard.** The guard at
`vid_vga.c:334-335` is
`memsize - tbuffersize + SURFCACHE_SIZE_AT_320X200 + 0x10000*3 < minimum_memory`,
and at 320x200 `tbuffersize` already contains that same constant, so the two
terms cancel and the guard reduces to `memsize - framebuffer + 192K` whatever
the cache size is. A small machine is exactly as protected as before.

**⚠⚠ THE TIMEDEMO RUNNER WILL NOT REBUILD AFTER A SOURCE EDIT — THIS ALMOST
PRODUCED A FALSE FINDING HERE.** `timedemo-dos.ps1:272` gates the entire build
on `if (-not (Test-Path $benchmarkExe))`, and `$benchmarkExe` is
`out\dos<profile-suffix>\qbench.exe` — keyed only by the *selector profile*, not
by source content. **If that executable exists, a source or header edit is
silently ignored and the previous binary is measured.** Editing
`d_local.h` appeared to do nothing for three timedemos; the binary still
carried `mov $0x1c2000,%eax` (1800 KB) while a direct compile of the same
file emitted `mov $0x258000,%eax` (2400 KB). **Pass `-Clean` to
`build-dos.ps1`, or verify the constant in the linked image, after any source
edit before trusting a timedemo.** This is a live hazard for every source-level
experiment in this project, not just this one.

**RESOLVED 2026-09-30.** The runner now hashes all 163 source files plus the
resolved selectors and rebuilds on mismatch, so neither flag is required and the
false negative can no longer occur. Two corrections to the note above: the
documented `-Clean` switch belongs to `build-dos.ps1`, **not**
`timedemo-dos.ps1`, which never had one; and the anchor `timedemo-dos.ps1:272`
has moved as the file has been edited.

## `Turbulent8` setup precompute (2026-09-30) — priced with a bit-exact dead-scratch probe; 0.034% addressable, below the gate

The last open candidate on the admissible list, quoted at **2.27% of frame**
(the whole `turbulent-spans` bucket). Unlike the previous three this ceiling
was a real bucket share rather than a mis-attribution, so it was measured
properly rather than dismissed arithmetically.

**Structure (PROFILE486 counters in `Turbulent8`):**

```text
profile-turbulent rows 40147 chunks 144705 pixels 1997515
turbulent-spans self 1.927013 s = 2.28% of the profiled frame
```

1,997,515 pixels are blitted and that blit is irreducible, so the only prize is
the s/t setup: one x87 divide plus a dozen flops per row **and** per 16-pixel
chunk.

**The probe.** The setup arithmetic was duplicated into scratch variables inside
the same loops, accumulated into a file-scope global so the compiler could not
eliminate it, and never fed to the blitter. Both probe builds rendered
**checksum `1047377823`, bit-identical to control** — which is what makes this
a sound measurement rather than the failed `z = 1.0f` attempt, which destroyed
the texture coordinates and faulted.

| build | median | delta vs control | % of frame |
|---|---:|---:|---:|
| control | 59.227346 s | — | — |
| row setup duplicated only | 59.247732 s | +0.020386 s | **0.0344%** |
| row + chunk setup duplicated | 59.296962 s | +0.069616 s | **0.1176%** |
| so the chunk share alone | — | +0.049230 s | 0.0831% |

**Dead, and the reason is structural.** The chunk-level setup
(`sdivz += sdivz16stepu; ... z = 0x10000 / zi;`) is a **running accumulation**:
each chunk depends on the previous one's state, so no per-`(surface, row)`
memo can cover it. That is 0.0831% of frame, permanently unaddressable. The
only work a memo could remove is the 40,147 row-level setups, worth
**0.0344% — below the 0.05% gate** — and that is an upper bound assuming a
100% hit rate and a free lookup, before accounting for the fact that the
inputs (`d_sdivzorigin`, `d_sdivzstepu`, ...) are recomputed per surface per
frame from the current view and so change every frame of a moving demo.

**The quoted 2.27% was ~66x the addressable work.** The whole duplicated setup
is 0.1176% of frame against a 2.28% bucket, so ~95% of the bucket is the
1,997,515-pixel blit and its surrounding call overhead, and the rest is
arithmetic no memo can reach.

Two process notes, both learned the hard way here:

- **A dead-scratch probe must not perturb the code it is pricing.** Forcing
  `z = 1.0f` to remove the divides *is* removing the thing the divides produce,
  so it broke water and faulted the run. Duplicate the work, discard the
  result, never change an input.
- **When inserting code by anchor, bound the search to the target function.**
  Two of the five probe blocks were placed by a whole-file pattern match and
  landed in `D_DrawSpans8`, which shares the same statement shapes. The compile
  caught it; a narrower anchor would not have.

Instrumentation retained: the three `PROFILE486` counters
(`bench486_turbulent_rows/_chunks/_pixels`). Inert in release builds.

