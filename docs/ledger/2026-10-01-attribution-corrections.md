# Attribution corrections (2026-10-01)

Extracted verbatim from `ASM486-HANDOFF.md` lines 2731-3077 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## Alias attribution corrected (2026-10-01) — the profiler was measuring itself; C glue is 3.1x cheaper than recorded

The self-time ranking this project has been steering by is distorted by the
profiler, and the distortion is large enough to have produced a false
convergence verdict. This entry records the correction, the tool that makes it
automatic, and the amended cost distribution.

**The mechanism.** `Bench486ProfileEnter` reads `Sys_FloatTime` *before*
recording the scope start, and `Bench486ProfileLeave` reads it again at the
top. So a scope's measured self window physically contains one `Sys_FloatTime`
call of its own, plus one for every child scope it enters. The profiler now
calibrates the real cost of a read at startup (`Bench486ProfileCalibrateTimer`,
256 back-to-back reads) and reports it in `profile.jsn` as
`instrumentation.read_seconds`, and emits a per-node `instr_reads` count. The
measured cost is **193.3 cycles per read** on the pinned profile — close to,
and slightly below, the 253 cycles independently estimated at `:952`.

**What that does to the recorded table.** The four C-glue regions, re-priced
against their own instrumentation:

```text
node                    calls    raw cyc/call -> signal cyc/call   signal
alias-span-package    168,782           252.9  ->          59.8      23.6%
alias-edge-setup      183,040           268.0  ->          74.8      27.9%
alias-linescan-setup  263,792           283.2  ->          90.0      31.8%
alias-step-math       109,941           303.8  ->         110.6      36.4%
```

**Between 62% and 76% of every number in that table was the clock.** The raw
figures reproduce the 2026-09-29 values exactly, which confirms the correction is
calibrated rather than fitted. Summed, the four regions cost
`(168782*252.9 + 183040*268.0 + 263792*283.2 + 109941*303.8)` = **5.97 s** on
the raw readings.

**Measured properly, they cost 1.83 s** — a **3.1x overstatement**.

**The fix, and why it was the right one anyway.** The four per-call C scopes are
gone. `D_RasterizeAliasPolySmooth` now opens **one** `alias-glue` scope per
triangle, and the three ASM helpers keep their own scopes, so `alias-glue`'s
self time is the C and nothing else. Timer reads fell **2,781,830 ->
1,580,280 (-43%)** and the profiled frame from 84.59 s to 75.68 s, with
checksum `1047377823` unchanged on every run. The ledger's own advice at `:946-948`
("amortize: time a whole span or a whole triangle rather than each sub-block")
was right and had simply not been carried out.

**The amended distribution** (corrected self time, `out\dos-timedemo-20261001-154726`):

```text
node                corrected   % of profiled frame   signal
texture-spans         18.587 s            24.6%         98.3%
world-bsp              7.724 s            10.2%         99.9%
surface-cache          6.832 s             9.0%         95.5%
edge-scan              6.043 s             8.0%         99.8%
z-spans                5.968 s             7.9%         94.7%
alias-raster           2.999 s             4.0%         79.9%
surfaces               2.805 s             3.7%         67.8%
alias-draw-spans       2.408 s             3.2%         73.0%
turbulent-spans        1.911 s             2.5%         99.2%
alias-glue (the C)     1.827 s             2.4%         38.1%
alias-transform        1.305 s             1.7%         97.6%
brush-entities         1.228 s             1.6%         99.5%
```

`alias-raster` is no longer 13.6% of frame; it is 4.0%, and the C glue inside it
is 2.4%. **The alias raster path is still not worth porting** — the C is thin —
but that is now a conclusion from a measurement that can see it, not from one
that could not. Do not cite the old table again.

**Two corrections to the project's standing numbers.**

1. **`frameFpsStats` was silently costing 0.020% of frame.** The recorded
   baseline 59.227329 s was measured with it **off**, but the runner defaulted
   it **on**, so a default `timedemo-dos.ps1` invocation produced 59.239011 s —
   **0.0117 s, which is 39% of the entire 0.05% promotion gate**, before any
   code change. The flag is now opt-in (`-FpsStats`), a run with it enabled
   prints a warning that the result is a diagnostic and not a promotion
   measurement, and the resolved value is written to the report JSON. With it
   off, the tree reproduces the baseline at **59.227628 s median**
   (59.227596 / 59.227628 / 59.227631), a 0.0005% difference.
2. **`tools\profile-report.ps1` now refuses to mislead.** It prints corrected
   self time, the per-read floor, a per-call figure with the signal fraction, and
   an explicit `LOW SIGNAL` list naming the regions whose measured window is
   mostly clock, with the instruction not to port or close them on that
   evidence. Any future pass that adds a per-call scope will see its own floor
   immediately.

**What this does not change.** The promotion gate, the parity gates, the
inadmissibility of the x87/fetch/write-buffer/aliasing axes, and the closure of
E0, E4, the bmodel `FIXME`, and `Turbulent8` all stand. The two buckets this
re-opens as unmeasured rather than closed are `world-bsp` (10.2%) and
`edge-scan` (8.0%) — both high signal, both never structurally decomposed.
They are resolved immediately below.

## `world-bsp` decomposed (2026-10-01) — it was never the BSP walk; 85% of it is per-face edge setup

`world-bsp` sat at 10.2% of frame as a single opaque bucket covering
`R_RecursiveWorldNode`, the ~800-line `R_RenderFace`, `R_ClipEdge` and
`R_EmitCachedEdge`, with no split. Four PROFILE486 counters were added first
(plain increments, no timer reads) to size the callees before committing to a
scope, because sizing the scope by guesswork is how the alias table went wrong.

```text
renderface-calls    215,720   (222.6 per frame)
renderface-emitted  104,642   (107.9 per frame; 48.5% of calls emit a surface)
clipedge-calls            0   <-- the C R_ClipEdge is not the one that runs
emitcached-calls   121,467   (125.3 per frame; 56% of calls hit the edge cache)
```

`clipedge-calls 0` is itself a result: `R_ClipEdge` is `r_drawa.s` assembly in
every promoted build, so the C reference in `r_draw.c` is dead code on this
path. The 486,253 calls per run that do **not** hit `R_EmitCachedEdge` go
through the assembly clipper.

222 calls/frame is low enough to scope. One `renderface` scope around the three
`R_RenderFace` call sites in `r_bsp.c` splits the bucket cleanly
(`out\dos-timedemo-20261001-171323`, checksum `1047377823`):

```text
region        corrected   % of frame   signal   per call
renderface      6.549 s       8.29%     84.0%   1015 cyc/call
world-bsp       2.157 s       2.73%     63.9%   (the walk, after subtraction)
```

**The BSP traversal is not the cost.** It is 2.7% of frame, and `R_RenderFace`
is 8.3% — **85% of what was filed as "world BSP" is per-face edge setup.** The
profile has been steering by "world-bsp 9-11%" for several passes, and that
number was really the face-setup bucket wearing the wrong label.

**Price, and the admissibility split.** `renderface` is 226,000 cycles/frame,
**221x the 1,022-cycle gate**, so this is the largest admissible-axis pool found
so far. But most of it is the assembly `R_ClipEdge`, and its 12 serialized x87
instructions per clip plane are the **blind axis** — a change there pays in x87
latency, which DOSBox-X cannot register, so it is inadmissible however large
the prize. Only the instruction-count part of `R_RenderFace` — the unrolled
per-edge dispatch scaffolding, the clip-plane link setup, and the cache
validation in front of `R_EmitCachedEdge` — is admissible, and it has never
been separated from the clipper. That separation is the next task, and it needs
a probe rather than a timer, for the reason in the next section.

## `renderface` priced by premise (2026-10-01) — large pool, but the x87 in it is essential work; no probe built

The obvious next step after the split above was a dead-scratch probe to price
`R_RenderFace`'s C scaffolding against the assembly clipper. Before building
it, the population was measured with plain counters (no timer reads), which is
what the mip-1 result taught to do first.

```text
renderface-calls    215,720   (222.6 per frame, 4.99 edges per call)
renderface-emitted  104,640   (48.5% of calls emit a surface)
edge setups       1,077,059
  of which cache-hit 121,466  (11.3%) -> R_EmitCachedEdge, no clipping at all
  of which clipped    955,593  (88.7%) -> the assembly R_ClipEdge
clip planes          637,693   (2.96 per face, but only 0.667 per clipper call)
early returns              0   (no surface_p / edge_p exhaustion at all)
```

**This reframes the bucket, and it is why the probe was not built.**

The 88.7% figure looks alarming, but it is the wrong number to fear. The
clipper's *plane-dot* loop — the obviously inadmissible part, ~20 x87
instructions per plane — runs **637,693** times in total, not 955,593, because
two thirds of clipper calls arrive with `pclip == NULL` and fall straight
through to `Lemit`. 637,693 x 20 is 12.8 M x87 instructions, about 13 M
cycles: **~6% of `renderface`'s 219 M cycles.**

So the bucket is not mostly "clipping x87 that could go away". It is mostly the
per-edge **emit** path — `fldcw`, `LTransformAndProject` (project, 1/z divide,
scale), edge store and stack clear — at 955,593 edges. That is essential edge
work, not an optimisation target, and it is inadmissible in any case.

What remains admissible is the C scaffolding around it, plausibly 30-40% of the
bucket, i.e. 70,000-90,000 cycles/frame, still 70-90x the gate. **A price was
not obtained and none is claimed.** The obstacle is not measurement: it is that
no candidate transformation exists to price. The mip-1 win came from a *known*
specialisation applied one level down, and the premise counters said where to
apply it. Here there is no equivalent — the ledger already records the hoist
and unroll attempts in `R_RenderFace`, and most were reverted.

**Decision: `renderface` is closed as "large, correctly attributed, and without
an admissible hypothesis". Do not build the probe.** Instrumenting 800 lines of
unrolled C across ~24 edge sites to price a pool with no candidate is exactly
the "another C-to-ASM port without a new source-level hypothesis" that
`:2985-2992` warns against. If a hypothesis for the clip-plane link chain or
the cache-validation sequence appears later, the counters above are already in
the tree to test its premise for free.

> **Superseded 2026-10-02 — the probe was built and the pool is now priced. The closure
> still stands, but it rests on a measurement rather than on "no hypothesis".** Two C
> dead-scratch probes over the prologue and the per-edge cache validation give **~15.8x
> the gate** of priced C scaffolding, against the 70-90x estimated above — **the estimate
> was high by 4-5x**. Read ``2026-10-02-edge-scan-and-texture-spans.md``, under "`renderface` priced (2026-10-02)". Two
> findings from it are worth more than the closure: the redundant `edge_p - r_edges` was
> already CSE'd by `-O3` (the whole prize is one `sub`, 0.9x, and reading `objdump -dr`
> found that before any build), and **the 1.0 cycle rate is a dependency property, not a
> constant** — nine assembly loops measure 0.974-0.996, one straight-line C mix 0.5439,
> one serialised C mix 1.1917. Do not re-open `renderface`.

## `edge-scan` cannot be decomposed (2026-10-01) — the arithmetic forbids it, do not retry

`edge-scan` is 7.65% of frame and was the other undecomposed bucket. The
counters give 73 inserts, 72 removes, 151 steps and 152 span generations per
frame, so the whole bucket is 448 operations:

```text
edge-scan corrected budget   208,581 cycles/frame
operations per frame                448
cost per operation                  466 cycles
timer floor per scope               387 cycles   (2 reads x 193.3)
best achievable signal              17.0%
```

**Any per-call scope over these routines would report at most 17% signal.** At
466 cycles of real work per operation against a 387-cycle floor, a decomposition
would be measuring `Sys_FloatTime`, which is precisely the error that produced
the withdrawn alias table. Adding one anyway would also cost 868k reads and put
the build back above its previous 2.78M.

**So `edge-scan` is closed as unresolvable by this instrument, not as converged.**
Its components (`R_InsertNewEdges`, `R_RemoveEdges`, `R_StepActiveU`,
`R_GenerateSpans` in `r_edgea.s`) are hand-tuned assembly with roughly twenty
logged micro-experiments already rejected, so there is no strong reason to
expect an unmeasured win. The honest statement is that a real win there would
need the dead-scratch probe or real hardware, not another scope. **Do not add a
scope to `edge-scan`; the floor arithmetic above is the reason, and it will not
improve with more runs.**

> **Superseded 2026-10-02 by the `edge-scan` dead-scratch decomposition at the top
> of this file. The scope prohibition STANDS and the arithmetic above is still
> correct — but it was read as licensing a permanent closure, and that reading
> was wrong.** The floor binds a *timer scope*, and a dead-scratch probe is not
> one: it has no measurement overhead, because it adds work and is read off the
> whole-run timedemo delta against a 0.000049 s spread. Six probes then gave the
> decomposition this entry says was unavailable, and it re-opened the bucket at
> 88.8x the gate measured plus **115.1x now bounded and named**. Two of its own
> predictions were wrong: the four micro-optimised loops are 52x the gate, not
> most of it, and the conclusion "no strong reason to expect an unmeasured win"
> was reasoned rather than measured. **The remedy named in the last paragraph was
> correct and simply was not run — that is the actual failure here.** Do not
> repeat it: an entry that says what would be needed is not a closure.

## mip-1 horizontal-flat surface blocks (2026-10-01) — **PROMOTED, 0.0513%**

The first admissible win since the profiler was corrected, and the first
candidate to clear the gate on a *measured* premise rather than an extrapolated
one. It is the mip-0 specialisation applied one mip level down.

**Premise, measured before anything was built.** The flat-block counters were
split by mip level (they had only been summed, which is what hid the
opportunity). mip-1 has more blocks than mip-0, and a higher flat fraction:

```text
mip     blocks  horizontal-flat   share
0      93,602           7,158      7.65%
1     142,258          14,837     10.43%
2      44,445           3,930      8.84%
3       7,364             591      8.03%
```

**The price, and why modelling was not enough.** Calibrating against the
measured mip-0 promotion (78.725 ms net) gave 0.839 cycles per removed
`addl %ebp,%edx`, which put mip-1 at **1,015 cycles/frame against the
1,022-cycle gate — 0.99x.** The entire verdict hinged on one assumption: that
the four-instruction eligibility test would cost 4 cycles on the 127,421
non-flat mip-1 blocks.

**That assumption was wrong, and only a measurement could say so.** A temporary
probe duplicated the mip-0 flat test (both outcomes falling through, so it is
bit-exact) behind a `-FlatTestProbe` switch that was part of the build
fingerprint and the profile suffix, so a probe run could never measure a control
binary. Three alternating pairs:

```text
control   59.228381 / 59.228440 / 59.228389 s
probe     59.228407 / 59.228396 / 59.228387 s
delta    -0.000033 s  = -1.1 cycles/frame
```

**The eligibility test is free** — the branch is perfectly predicted and the
four instructions overlap with surrounding work. So the mip-1 prize is the
gross figure, **1,542 cycles/frame = 1.51x the gate**, not the net figure the
model produced. The probe, its switch and its plumbing were then removed
completely; the tree is back to a clean two-state selector.

**This is the general lesson worth keeping.** A model calibrated on real data
still got the sign of the answer wrong, by 0.01x, because one of its two
parameters was an assumption rather than a measurement. The 0.99x looked like a
refusal to build; it was actually an invitation to measure the one number that
decided it.

**Implementation.** `surf8.s` gains `LSurf8Mip1HorizontalFlat`, the general
`SURF8_MIP1_ROW` with every per-texel light update removed. Source byte order,
the `%eax` packing, both `rorl $16` word swaps and both colormap lookups per
texel are byte-for-byte the general path, so the output is identical; only the
light updates go, replaced by one `addl %ebp,%edx` per row. 64 new colormap
patch sites, so `R_Surf8Patch`'s `%ecx` ladder gains `addl $64,%ecx` — the
documented footgun, verified by preprocessing the table with the real toolchain
and counting (216 entries against a computed 216) before building.

**Two bugs worth recording, because both produced a hard fault rather than wrong
pixels, and neither was findable by reading the code.**

1. The eligibility test has to sit **before** the `subl %ecx,%ecx` /
   `subl %ebx,%ebx` that clear those registers for loop addressing. mip-0 has no
   such zeroing, so copying mip-0's *position* verbatim on mip-1 put the test
   after them, where it compared 0 to 0, always passed, and set the per-row step
   to 0.
2. The eight rows are unrolled inside the subroutine, so the loop counter is the
   number of **row bodies** (1), not the block height (8). Copying mip-0's
   `pushl $16` shape and unrolling eight rows gave 8x8 = 64 rows, which ran off
   the end of the surface cache. Quake faulted with no output at all, which is
   how a surface-cache overrun presents.

**Result.** Three alternating pairs, control first, both from the same tree:

| build | runs (s) | median | frames / checksum |
|---|---|---:|---|
| `SurfaceBlockMip1HorizontalFlat=control` | 59.227632 / 59.227598 / 59.227546 | 59.227632 | 969 / `1047377823` |
| `SurfaceBlockMip1HorizontalFlat=fast` | 59.197250 / 59.197203 / 59.197264 | **59.197264** | 969 / `1047377823` |

**0.030368 s, 0.0513% faster** — above the 0.05% gate, and about 353x the
0.000086 s control spread. Every candidate run beat every control run. The
candidate passed the DOS smoke test and the full `bench486` correctness suite
(`486 benchmark correctness PASS`, end checksum `2378409472`).

**Promoted to the default** in `build-dos.ps1`, `bench-dos.ps1`,
`timedemo-dos.ps1` and `smoke-dos.ps1`; `control` remains selectable for A/B.
The promoted default re-measures at **59.197264 s** median
(59.197260 / 59.197266 / 59.197264), checksum `1047377823` on all three, with
`bench486` PASS and smoke clean.

**New baseline: 59.197264 s / 16.369000 FPS**, from 59.227329 s / 16.360690.

Because this win is a straight removal of arithmetic, it is squarely on the
admissible side of the gate. Note the two facts that made it possible and that
were both unavailable before 2026-10-01: the per-mip flat counts, which the
summed counter hid, and a profile whose self-times can be trusted.

- Do not add a fourth level of per-call instrumentation here. The measurement
  cost now rivals the signal, and no further decision hinges on it. If more
  resolution is ever needed, amortize: time a whole span or a whole triangle
  rather than each sub-block.

Release parity is unchanged at 969 frames and checksum `1047377823`, confirmed
after this level. Workload counters held: `alias-models` 5470,
`alias-vertices` 417090, `line-setups` 263794, `max-depth` 8,
`stack-overflows` 0, `bad-leaves` 0.

