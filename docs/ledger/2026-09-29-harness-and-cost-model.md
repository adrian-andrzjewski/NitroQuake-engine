# The measurement harness and the static 486 cost model (2026-09-29)

Extracted verbatim from `ASM486-HANDOFF.md` lines 2127-2730 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## The bmodel frustum `FIXME` (2026-09-29) — premise measured, ceiling is two orders of magnitude short, do not build

The last sizeable candidate on the admissible list was the pair of in-code
precompute TODOs in `R_DrawSubmodelPolygons` (`r_bsp.c:462` and `:480`,
`/* FIXME: use bounding-box-based frustum clipping info? */`). The loop runs a
per-surface `DotProduct(modelorg, pplane->normal) - pplane->dist` backface test
(`:472`) for every face of every visible bmodel, and the proposal was a
per-`(face, entity)` precompute. It was quoted at **1.5-2.5% of frame**.

**Measured, and both halves of the premise are now known:**

```text
profile-submodel calls 2118 faces 12708 distinct-entities 26 \
  entity-hits 2092 table-overwrites 0
```

- **The reuse premise is TRUE, and unusually good.** 2,092 of 2,118 calls
  re-draw an entity already seen, across only **26 distinct entities** — a
  98.8% hit rate, nothing like E0's 3.4% or E4's zero. Structurally this is
  expected: the loop already visits every face of a submodel exactly once per
  call, so reuse can only come from repeated entity draws, and demo1 redraws
  26 entities 2,118 times. The `(face, entity, miplevel)` key would have hit
  almost every time.
- **The ceiling kills it anyway.** 12,708 face tests in the entire 969-frame
  run is **13.1 per frame**. The backface test is three multiplies, two adds
  and a subtract on data already in cache, so the whole loop is worth on the
  order of **200 cycles/frame** — against a promotion gate of **1,022.8
  cycles/frame**. Even deleting every dot product outright lands near
  **0.01% of frame, roughly 5x below the 0.05% gate.**

**The 1.5-2.5% figure was wrong by about two orders of magnitude**, most
likely by attributing the bmodel path's 13.60% `alias-raster` share to this
loop. Note the loop is a small part of the alias path even in absolute terms:
12,708 faces here against 417,090 alias-vertices. **Do not build this, and do
not re-quote its ceiling.**

The instrumentation is `PROFILE486`-only and inert in release builds (release
re-measured at 59.227374 s median, checksum unchanged). It is kept because it
is the evidence for the ceiling and because `table-overwrites 0` is what makes
`distinct-entities 26` trustworthy; a future reader can delete it with the rest
of the counters without loss.

**This is now the third candidate on the offline-precompute axis to die on a
measured premise** (E0 3.4% hit rate, E4 zero immutable rebuilds, bmodel
frustum 5x under gate). All three quoted their ceiling from a *bucket share* or
a *cost of churn* rather than from the addressable work. The screening rule that
would have caught all three: **price the prize, not the hit rate** — count the
operations the optimisation would remove, divide by frames, and compare to
1,022.8 cycles/frame before asking whether the cache hits.

## E4, the surface-cache eviction churn (2026-09-29) — premise falsified before it was built, 0 of 8,886 rebuilds

E4 was the largest candidate left on the offline-precompute axis at a quoted
**2.61% of frame**: 2,151 of 9,009 surface-cache rebuilds per run are
eviction-caused (1.547 s at 0.719 ms/rebuild), and the claim was that those
re-light surfaces whose lightstyle is permanently `256`
(`d_lightstylevalue[j] = 256` for any zero-length style, `r_light.c:68`) and
whose lit pixels therefore can never change, so the re-light is pure waste.

**That population does not exist in this workload.** A PROFILE486 counter was
added at the miss site in `D_CacheSurface` (`d_surf.c:410`) counting rebuilds
whose four `d_lightstylevalue[surface->styles[k]]` are all `256`:

```text
profile-surface-cache hits 46414 rebuilds 8886 immutable-rebuilds 0 \
  allocations 2710 wraps 3 invalidated-blocks 1893 thrash-frames 0
```

**Zero**, out of 8,886 rebuilds. Every surface that gets re-lit carries at least
one lightstyle that is not statically fullbright, so its lit pixels genuinely
depend on the current style value and the rebuild is necessary work. **Do not
build E4. The 2.61% ceiling was an upper bound on the *cost of eviction*, never
on the *addressable* part of it, and the addressable part is nil.**

Two secondary readings from the same run, at the new 2400 KB default:

- raising the cache 1800 -> 2400 KB cut invalidated blocks 2,151 -> **1,893**
  (12%) and wraps 4 -> 3, but rebuilds only 9,009 -> 8,886 (1.4%). Eviction
  churn is therefore **not** capacity-bound, which is the second reason a
  cache-policy fix could not have recovered 2.61%.
- `immutable_rebuilds` is a permanent PROFILE486-only metric; it costs nothing
  in release builds (median re-measured at 59.227332 s, unchanged). It is kept
  because it is the evidence for this null. Remove it if the tree is ever
  pruned of counters.

Admissible work after this null: `turbulent-spans` (~2.27%) and the bmodel
frustum `FIXME` (1.5-2.5%, keyed on `(face, entity, miplevel)`). E2 remains
below the run spread and should not be attempted.

## Static 486 cost model (2026-09-29) — built; it disqualifies all three blind axes and promotes nothing

`tools\486-cost-model.ps1` prices the three axes this harness cannot see, using
the pinned toolchain's objdump plus the Intel 486 published FP latencies. It is
a **disqualifier and a ranking aid, never a promotion criterion**: the 0.05%
DOSBox-X timedemo delta remains the sole gate, and a cycle figure from this
tool is a published-latency estimate, not a measurement taken here.

```powershell
.\tools\486-cost-model.ps1 `
    -ProfileJson 'out\dos-timedemo-<timestamp>\timedemo-result.json' `
    -Json 'out\486-cost-model.json'
```

**Measured against the promoted build:**

| quantity | value |
|---|---:|
| `.text` | 738,648 B = **91** unified-cache windows (90.2x the 8 KB L1) |
| x87 instructions in `.text` | 23,020 |
| Z-span prologue x87 cost | **74 cy/span** vs **9.4 cy** measured in DOSBox-X |
| spans / pixels per span | 1,494,649 / **30.75** (ledger records 30.7) |
| `z-spans` node calls | **58,051** (matches the ledger anchor exactly) |
| projected prologue share of frame | **3.91%** at 33.445 MHz, 1.95% at 66.9 MHz |

**The three disqualifications, all now quantified rather than asserted:**

1. **x87 latency — disqualified.** 74 cy/span against a measured 9.4 is a
   **7.9x** gap, and 3.91% of frame on a 486 against 0.71% measured here. The
   percentage scales linearly with clock; the ledger's historical **7.8%**
   estimate is consistent with this model at roughly 25 MHz, so the two agree
   in order of magnitude. Under a retained timedemo gate this axis cannot be
   promoted at any clock, which is why the Z-span prologue is a *rejected
   target* rather than a deferred one.
2. **L1 footprint — disqualified.** `.text` spans 91 windows of an 8 KB
   unified cache, and DOSBox-X does not model displacement.
3. **4 KB aliasing — disqualified, precondition confirmed by computation.**
   From `vid_vga.c:299-304`: zbuffer 128,000 B, then `vid_surfcache` at
   +128,000, then `lvid->buffer` at +1,971,200. Both land at page offset
   **1,024**, so they alias. This is now a computed fact, not a hypothesis —
   but the stall itself is unmodelled, so a null result would be uninformative.

**Two corrections this pass produced.**

- **The prologue is twelve x87 instructions, not nine.** `d_draw.s:812-835`
  contains `fildl fildl fmuls fxch fmuls fxch fadds faddp fcoms fnstsw fmuls
  fistpl`. The ledger's "nine" appears to count a latency-carrying subset
  (the two `fxch` register swaps and the `fnstsw` status read carry no
  dependency). Both figures are reported by the tool; the twelve are priced.
- **The linked executable is stripped by the build**, not by accident:
  `build-dos.ps1` links with `-s` (grep it for the line), so `objdump -t` reports *no symbols*.
  Per-function attribution is therefore impossible from the image, and the
  tool splits its work accordingly — exact image totals from the binary,
  per-path x87 accounting from the assembler sources where labels and line
  numbers exist. The object-granularity clustering experiment's lesson
  applies here too: this tool says nothing about *placement*.

**A counting trap worth recording.** objdump prints segment prefixes as
separate tokens and disassembles some data regions linearly, so a naive
"mnemonic begins with `f`" rule counted 336 `fs` prefixes, 68 bare `ff` grp5
opcodes and 3 AMD 3DNow `femms`/`fcmovnu` as x87 — 407 false positives, 1.7% of
the total. The tool carries an explicit exclusion list and **reports any x87
opcode it has no published latency for**, so a table gap is visible rather than
silently priced at the 3-cycle default.

Admissible work is unchanged: payoff in instruction count, memory traffic, or
arithmetic. That is E4 (surface-cache eviction churn), `turbulent-spans`, and
the bmodel frustum `FIXME`.

## `d_mip_t16` as a constant table (2026-09-29) — landed; the promotion half was not attempted

`D_DrawSurfaces` rebuilt three 4-entry float tables on every span flush
(1,052/run) under a `// TODO: could preset a lot of this at mode set time`.
One of the three is not runtime data at all: `d_mip_t16[mip] = 0x10000 *
d_mipscale_values[mip]` is exactly `{0x10000, 0x8000, 0x4000, 0x2000}` for
`d_mipscale_values = {1.0, 0.5, 0.25, 0.125}`, and all four are exactly
representable in single precision. It is now a `static const` table and the
store is gone.

```text
closure before E2:    59.265368 s  16.350189 FPS  checksum 1047377823
with d_mip_t16 const: 59.265007 s  16.350289 FPS  checksum 1047377823
delta: -0.000361 s = 0.0006% faster
```

**This is a cleanup, not a win, and it is kept on that basis.** The predicted
ceiling was ~0.005% and the measurement is ~0.0006%; both are an order of
magnitude below the 0.05% gate and near the 0.000049 s run spread, so no
timedemo beyond this single confirmation run is justified. What it buys is the
deletion of a redundant recomputation of a compile-time constant.

**The planned hoist of `d_mip_xscale` / `d_mip_yscale` into `D_ViewChanged` was
deliberately not done.** `xscaleinv` and `yscaleinv` have exactly one writer each
(`r_main.c:418`, `:421`), both inside `R_ViewChanged`, which calls
`D_ViewChanged()` last (`:482`) — so the ordering looks safe. But `R_ViewChanged`
itself is only reached from `R_SetupFrame` (`r_misc.c:454`, `:478`, `:491`) under
the condition `(r_dowarp != r_dowarpold) || r_viewchanged || lcd_x.value`, and
from `SCR_UpdateScreen` (`screen.c:276`). The current code self-heals because
`D_DrawSurfaces` fills the tables on its first call regardless. Hoisting trades
that unconditional fill for a dependency on a conditional call having happened
before the first `D_CalcGradients`; a missed first frame would leave the tables
zero and silently break texture mapping. The remaining upside is ~0.003% and
unmeasurable, which does not justify introducing a startup-ordering assumption
that the checksum gate would only catch after the fact. Revisit only with a
measurement that could resolve it.

## E3 and E4 disposition (2026-09-29)

Neither was built, for reasons that are now measurements rather than estimates.

- **E3** (per-`(face, miplevel)` constants computed at map load) is **closed** by
  the drawn-face ratio of 0.9585 measured above. A ~3.4% hit rate scales its
  ~0.10-0.14% ceiling down to ~0.004% of frame.
- **E4** (surface-cache span geometry split from lighting) was gated on E1-E3
  landing. E1 was rejected and E3 is closed, so its precondition is not met and
  it was not attempted. Its own stated ceiling was ~0.5%, which remains the
  largest unclaimed item on the offline-precompute list, but it is a cache-policy
  change rather than a precompute and does not belong to this pass.

## Precomputed `izistep` for the Z-span prologue (2026-09-29) — rejected, and the estimate was wrong in the wrong direction

`D_DrawZSpans` recomputed `d_zistepu * 2^31` once per call (58,051/run) via
`flds` / `fmuls Float2ToThe31nd` / `fistpl`, even though `d_zistepu` was already
cached per face by `R_SetSurfaceZGradients` (`r_draw.c:390-425`, a promoted win).
An opt-in `-IzistepImplementation control|precomputed` selector stored the scaled
value into the 8 free pad bytes at `surf_t` offset 56 and had the asm load it.

It was bit-exact by construction — `* 2^31` is a pure exponent bump, and the
C spelling `(int)(x * 0x8000 * 0x10000)` is the reference already in use at
`d_scan.c:459` — and every gate passed: `486 benchmark correctness PASS` with
end checksum `2378409472`, clean DOS smoke, and 969 frames with framebuffer
checksum `1047377823` on all six timedemos.

```text
control:    59.265374 / 59.265325 s   (median 59.265374, 16.350188 FPS)
precomputed: 59.285937 / 59.285888 / 59.285910 s  (median 59.285910, 16.344524 FPS)
delta        0.020536 s = 0.0347% SLOWER
```

The control median is from its two clean samples; its third run was 59.660367 s,
the isolated-outlier pattern already recorded elsewhere in this file. Every clean
control sample beats every candidate sample, and the 0.020536 s delta is roughly
420x the 0.000049 s run spread, so this is a real regression and not noise.
The candidate spread was itself only 0.000049 s.

**Why the estimate failed, which is the part worth keeping.** The prior plan
predicted 0.044-0.054%, sitting right on the 0.05% gate. The direction was wrong:
the change is not merely "saving" x87 work, it *adds* a store. `R_SetSurfaceZGradients`
now writes a fourth field per face, and it runs on both the miss and the cache-hit
path, so the cost is paid 58,051 times per run. What it removes is `flds` + `fmuls`
+ `fistpl`, which DOSBox-X prices at roughly a cycle each (the documented 1.04
cy/x87-op figure). Trading a real memory write for three emulator-cheap
instructions loses. This is **not** one of the axes the harness cannot see: it is
a genuine instruction-count and memory-traffic result, measured correctly, and the
answer is no.

A structural finding did survive and is recorded here because it is true and
cheap: **`LFNegSpan` in `d_draw.s` was dead code.** It was entered only from
`jz LFNegSpan` when `d_zistepu == 0`, where `-0.0 * -2^31` truncates to 0, so it
always fell through to `LZeroStepSpanLoop` regardless. Deleting it let the
candidate drop the `flds` entirely rather than keep a fragile x87-stack
dependency, but the net was still negative. `LFNegSpan` is live again.

The selector, the `izistep` field, `d_izistep`, the asm symbol and the plumbing in
all four runner scripts have been removed. The tree is back to control; the closure
timedemo is 59.265368 s / 16.350189 FPS at 969 frames and checksum `1047377823`.
Do not retry this as written. If anyone revisits removing x87 from the Z-span
prologue, the cost is on the producer side, and it has to come down by removing
the per-face store rather than by adding one.

## Drawn-face ratio (2026-09-29) — measured at 0.9585, which closes the per-face precompute family

The prior plan assumed a world `msurface_t` is drawn at most once per frame, and
cited `gradients 58051 == surfaces work_items 58051` as support. That pair of
counters cannot distinguish the claim from a tautology: both count *draws*.
A per-face cache keyed on `(face, miplevel)` therefore has an unmeasured hit rate,
and the whole E3 experiment was gated on that number.

So the counter was changed to count **distinct** faces per frame, not draws, via a
4096-slot direct-mapped table keyed on the face pointer and tagged with
`r_framecount` (`D_NoteFaceDrawn`, `d_edge.c:46-68`). It is `#ifdef PROFILE486`
only, costs nothing in release, and deliberately does not add a field to
`msurface_t`, which is exactly 64 bytes and must stay so. A collision merges two
faces, so the reported distinct count is a slight undercount and the true hit rate
is a slight overstatement of the repeats — the safe direction.

```text
gradients calls      58051
faces drawn (distinct) 55642
ratio                 0.9585    (repeats 2409, 4.15% of draws)
est. true ratio       ~0.966    (allowing ~426 expected collisions)
```

**The family is closed.** Faces do repeat, but only ~3.4% of the time — these are
bmodel faces, redrawn once per visible leaf. A per-face table could serve at most
that fraction of calls, so the E3 ceiling of ~0.10-0.14% of frame scales down to
**~0.004%**, an order of magnitude below the 0.05% gate. E3 should not be built.
This also retires the "memoization with a last-used compare loses" rule for this
particular family: it was never the comparison that failed, it was the hit rate.

The counter is kept, so the ratio can be re-measured rather than re-argued. It is
instrumentation only and does not appear in release builds.

## Hot-code clustering (2026-09-29) — rejected, and object granularity is the blocker

The measured facts made this look like the strongest remaining idea: `.text` is
738,392 bytes — **90x the 486's 8 KB unified L1** — and the two dominant
self-time buckets, texture spans (22.34%) and alias raster (10.87%), live in
separate objects. An opt-in `-HotCodeClustering control|cluster` selector
reordered the link line to place `d_draw16.obj`, `d_polysa.obj` and
`d_draw.obj` first. No code or data changed, so the checksum could not move —
and it did not: both variants returned `1047377823`.

```text
control  59.265504 s   checksum 1047377823
cluster  59.728678 s   checksum 1047377823   0.7815% SLOWER
```

**Rejected, and the failure is diagnostic.** Disassembly of the clustered
binary shows why. The Aff8 leaf's 16 sites moved from `0x90964` to `0x3524` —
to the very front of `.text` — while the 8-site group stayed at `0x92c15`. The
gap between the two hot halves therefore grew from **8,062 bytes to 586,686
bytes**, 73x worse. Reordering whole objects cannot cluster two functions when
the objects holding them are each far larger than the cache; it only relocates
one of them and displaces everything else.

A real attempt needs function-level placement — a linker `-T` script naming
`D_DrawSpans16` and `D_PolysetDrawSpans8` explicitly, or `.text.*` subsections.
That is a materially larger change than an object reordering, and given the
harness cannot model unified-cache displacement (see "What this harness can and
cannot measure" above) the result would be uninterpretable either way. Not
pursued.

The selector and its output directory have been removed; the tree is back to
`d3a058139248` with the release build re-verified.

## What this harness can and cannot measure (2026-09-29)

The project has reached the point where the binding constraint is the emulator,
not the code. This section states the limit so later passes do not spend
timedemos on ideas the harness cannot see.

**The measurement.** Duplicating the Z-span x87 prologue into dead scratch cost
9.4 cycles for nine serialized x87 operations — about 1.04 cycles per op. A
physical 486DX spends roughly 12 cycles per x87 op and 30-90 on `FISTP` alone.
That is a 30-90x gap.

**No DOSBox-X option closes it.** The `[cpu]` section
(`tools\dosbox-x-486-high.conf:490-537`) sets `core = dynamic`, `fpu = true`,
`cputype = 486`, `cycles = fixed 33445`. DOSBox-X 2026.08.31 exposes 44 CPU
options and none controls x87 latency or fidelity; the `core` values differ in
which opcodes decode, not in per-instruction x87 timing. `fpu = true` decides
whether an FPU exists, not how it is timed — the FPU is present, functionally
correct (checksum `1047377823` is bit-exact), and temporally free.

**The consequence, and it is the thing to remember:**

> A **positive** result in this harness is sound — a measured win is a real
> win, and the checksum gate makes the semantics exact. A **negative** result is
> weak evidence. A measured null proves only that the emulator could not see the
> cost.

So the harness is reliable for finding wins and unreliable for rejecting
486-specific ideas. Every axis where a real 486 pays and DOSBox-X does not:

| axis | real 486DX | this harness | consequence |
|---|---|---|---|
| x87 latency | ~12 cy/op, `FISTP` 30-90 | ~1.04 cy/op | any win priced by FP-op count reads 10-30x small |
| instruction cache | none — 8 KB unified data cache only | n/a | "I-cache" explanations are wrong by construction |
| fetch boundary / write buffer | 16-byte bursts, 4-entry WB | not modelled | the two most 486-specific mechanisms are invisible |
| 4 KB paging aliasing | real stall | not modelled | never tried, and unmeasurable here |

**Two corrections this forced.**

1. `docs/ledger/2026-09-29-alias-and-surface-block-experiments.md`, under "Aff8 16-byte code-alignment experiment", attributes the Aff8 padding regression to *"slightly
   worse I-cache placement."* **The 486 has no instruction cache** — only an
   8 KB unified data cache. What the sentence describes is 16-byte fetch
   boundaries and unified-cache displacement. That is the only I-cache
   reference in the repository, and it has been shaping the recorded reasoning
   about why the alignment experiment failed.
2. ~~The pinned profile SHA-256 is **recorded, not enforced**.
   `tools\timedemo-dos.ps1:439-446` computes it and `:653` writes it into the
   report, but nothing compares it to a constant — `F3948708` appears only in
   prose (`BENCHMARK-COMPARISON.md`, `VIDEO-DOS-VALIDATION.md`,
   `docs\PURE-ASSEMBLER-CANDIDATES.md`). A future change to the DOSBox-X core
   would therefore not be caught; it would silently re-baseline every entry in
   the ledger, because the hash protects the file, not the numbers.~~
   **(Closed 2026-09-30, and the line numbers above had moved even then. The hash
   is enforced: `timedemo-dos.ps1:548-556` compares it to `-ExpectedProfileSha256`
   (constant at `:104`) and throws unless `-AllowGateOverride` is passed. Grep for
   `ExpectedProfileSha256` rather than trusting any anchor in this file — several
   have drifted.)**

**Applying the rule.** Before spending a timedemo on an idea whose payoff comes
from FPU latency, fetch boundaries, write-buffer occupancy, or 4 KB aliasing,
recognise that a null is uninformative. Those ideas can only be settled on
hardware. Ideas whose payoff is instruction count, memory traffic, or
arithmetic are still fully measurable here, and that is where any further
optimization effort belongs.

### Where this leaves the project

> **Amended 2026-10-01.** The first two bullets below were not "closed by
> evidence". `alias raster` was closed by a measurement that was measuring its
> own timer, and it is now 4.0% of frame rather than 13.6% — small, but
> un-decomposed rather than converged. The claim that "every remaining mechanism
> is closed" rested partly on that. The recommendation to stop stands for the
> 486-specific axes, which really are invisible here; it did not cover the
> instruction-count axes, and the corrected profile identifies two of them
> (`world-bsp` 10.2%, `edge-scan` 8.0%) that were never structurally priced.
> See "Alias attribution corrected".

The renderer is converged at the source level. Every remaining mechanism I can
identify is either closed by measurement or closed by the harness's own
limits:

- texture spans, alias raster, the Z-span prologue, the video path, and the
  surface-cache size/layout are all closed by evidence, with the numbers
  recorded above;
- x87 latency, fetch boundaries, write-buffer occupancy, and 4 KB aliasing are
  unmeasurable here and no DOSBox-X option changes that;
- code layout is measurable only at object granularity, which the
  clustering experiment just showed is too coarse to be useful.

**The honest recommendation is to stop optimizing against this harness.** Not
because the renderer cannot be improved, but because the remaining ideas target
costs the measurement cannot see, and the project has no way to tell a real win
from an invisible one.

If the goal is real 486 hardware rather than the DOSBox-X benchmark, the next
step is not more assembly — it is a machine that can see what a 486 actually
pays. A physical 486DX2/DX4, or a cycle-accurate alternative emulator, would
immediately make the write-buffer, aliasing, and code-layout questions
answerable, and would let the alignment and prologue results be re-examined
without the emulator's flat FPU model distorting them.

Until then, the work stands as a complete, parity-gated optimization pass:
59.265 s / 16.35 FPS for `demo1`, roughly 22% faster than original Quake, with
969 frames and framebuffer checksum `1047377823` reproduced on every run.

## Z-span x87 prologue (2026-09-29) — measured, and the idea does not survive

`d_draw.s:812-838` runs nine serialized x87 instructions per span to compute
the initial 1/z, amortized over only 30.7 pixels on average (1,494,650 spans
for 45,953,856 pixels). It was the largest identified win in a bucket that no
logged Z-span experiment touches — all six ledger entries target addressing
(`zspantable`), packing (`shldl`/`rorl`), unrolling, or stack traffic.

**An instruction count suggested ~4.6 s, about 7.8% of frame. Measurement says
0.419 s, about 0.71%. The estimate was 11x too high.**

Measured with a probe that recomputes the identical prologue into the same
scratch slot, discarding the result. Because it reproduces the same value, the
framebuffer is bit-identical — both runs returned checksum `1047377823`, which
is what makes this probe safe to run, unlike the earlier attempt that
overwrote the Z buffer with a constant and produced visibly broken textures.

```text
control  59.265481 s   checksum 1047377823
probe    59.684261 s   checksum 1047377823   (prologue done twice)
delta     0.418780 s = one prologue = 9.4 cycles/span = 0.71% of frame
```

The estimate was wrong because it priced x87 ops at real 486 silicon speeds
(~12 cycles each, with `FISTP` at 30-90). DOSBox-X emulates them far more
cheaply; nine of them cost 9.4 cycles. A real 486DX would show a much larger
number, which is precisely the gap the project's standing caveat about
emulator results not predicting physical hardware applies to — in the opposite
direction from the usual one, where emulation flatters a change.

**The idea is not worth pursuing.** Even a perfect fix caps at 0.71% of frame,
and the bit-exact rewrite is blocked: the prologue computes in *single*
precision, rounding after each of the three float operations, so an integer
replacement would have to reproduce that rounding exactly. A naive integer
version fails the checksum. Reaching even half the ceiling would mean
emulating x87 rounding in integer arithmetic — far more expensive than the
0.419 s being removed.

Recorded so the 7.8% figure is not resurrected. The probe, its
`-ZSpanArithmetic` selector, and its `out\` directory have all been removed; the
tree is back to `6326298b308d` and the release build re-verified at 969 frames and
checksum `1047377823`, 59.265510 s.

**Method note worth keeping:** the safe way to price a hot sequence is to
duplicate it into dead scratch and time the delta. It is bit-exact, needs no
correctness argument, and cannot render anything wrong. The unsafe version —
overwriting live output — produces a faster but meaningless number *and* a
broken binary.

## Aff8 AGI interlock investigation (2026-09-29) — null result, selector removed

The Aff8 pixel leaf was the last untested 486 mechanism from the optimization
brief. It was investigated two ways, both recorded here because the process is
more useful than the outcome.

**1. The per-pixel hypothesis was false.** The claim was that `movb %dh,%ah`
followed by `movb 0x12345678(%eax),%al` creates a per-pixel interlock. The
assembled leaf is:

```text
  cmpw  (%ecx),%bp                 base=%ecx
  jl    Lp1
  movzbl (%esi),%eax              base=%esi, writes %eax
  movb  %dh,%ah                   writes %eax, NO memory operand
  movw  %bp,(%ecx)                base=%ecx
  movb  0x12345678(%eax),%al      base=%eax
  movb  %al,(%edi)                base=%edi
```

An interlock requires instruction N to write a register that instruction N+1
uses as a memory base or index. Checking each adjacent pair: `movb %dh,%ah`
writes `%eax` but has **no** memory operand, so it cannot be the N in a hazard,
and the `%eax` base use two instructions later is already separated by the Z
store. The `movzbl (%esi),%eax` → `movb %dh,%ah` pair looks like a hazard, but
the second instruction is register-to-register with no address generation.
`ALIAS_SPAN_ADVANCE` ends by writing `%esi` and the following
`cmpw (%ecx),%bp` uses `%ecx`, leaving two instructions of separation. The
original id Software schedule is already correct here.

**2. The one real interlock was measured, and is worth nothing.** Exactly one
genuine AGI remains: `addl $16,%ecx` immediately precedes `cmpw (%ecx),%bp` at
the two `LDrawLoop` group back-edges (`d_polysa.s:988` and `:1124`). Rather than
arguing from the disassembly, an opt-in `-Aff8AgiPadding control|pad` selector
was added, emitting one NOP at each back-edge, and the padding was confirmed in
the linked binary (control runs `add $0x10,%ecx` straight into
`cmpw (%ecx),%bp` at `0x90b14`; `pad` inserts `0x90b17: nop` between them).

The candidate passed every parity gate — `486 benchmark correctness PASS` with
end checksum `2378409472` (`out\dos-bench-20260929-102523`), a clean DOS smoke
test, and six timedemo runs at 969 frames with framebuffer checksum
`1047377823`. Three alternating pinned `demo1` pairs:

```text
control: 59.265427 / 59.265498 / 59.265442 s; median 59.265498 s, 16.350153 FPS
pad:     59.265453 / 59.265466 / 59.265480 s; median 59.265466 s, 16.350159 FPS
```

The delta is **-0.000032 s (-0.000054%)**, roughly 1,000x smaller than the
0.05% promotion gate and inside the run-to-run spread (control 0.000071 s, pad
0.000024 s). A clean null, not a regression: the NOP costs nothing in this
workload and saves nothing either.

**The selector and its `ASM486_AFF8_AGI_PAD` define have been removed from the
tree.** The measurement stands as the record; the code does not, because there
is nothing left to keep. Artifacts remain in `out\dos-timedemo-20260929-103519`
through `out\dos-timedemo-20260929-104051`.

Two conclusions. The Aff8 leaf is finished: the alignment experiment lost 0.806%
by growing this loop, and this padding is measurably free but worthless, so both
directions are closed. And the reasoning error in step 1 is the part worth
keeping — the interlock is easy to *see* in a disassembly and easy to believe,
and it was wrong. Verify adjacency **and operand types** before spending a
timedemo A/B on any 486 interlock claim.

## Alias-raster C-glue instrumentation (2026-09-29) — **SUPERSEDED 2026-10-01, the numbers below are instrumentation-limited**

> **The table in this section does not support the conclusion drawn from it, and
> the conclusion is withdrawn.** The four per-call C regions were measured at
> 253-304 cycles/call, but each scope's measured window physically contains its
> own timer read, and one read costs ~193 cycles. Between **62% and 76%** of
> every figure in the table is the clock, not the code. Re-measured with the
> scope amortized to one per triangle, the C glue is **1.83 s, not the ~5.97 s
> these numbers implied — a 3.1x overstatement.** See "Alias attribution
> corrected" below. The text is kept as written on 2026-09-29 so the reasoning
> error stays visible; do not cite the table as evidence of convergence.

The unattributed `alias-raster` self time is split into `alias-edge-setup`,
`alias-span-package`, and `alias-step-math`, wrapping the cursor-init blocks,
the single-row span-package emits, and the two duplicated base/extra step
blocks in `src\renderer\d_polyse.c`. From
`out\dos-timedemo-20260929-100501\timedemo-result.json` (frame total
84.627456 s, attribution only), in total cycles per call:

```text
node                       impl   calls    cycles/call
alias-draw-spans            ASM  153853       715.6
alias-scan-left-edge        ASM  109941       544.9
alias-calcgradients         ASM  124769       381.8
alias-step-math              C   109941       303.8
alias-linescan-setup         C   263794       283.1
alias-edge-setup             C   183042       267.9
alias-span-package           C   168786       252.9
```

**The remaining C is uniformly cheap.** The three glue regions are
36.8% / 32.5% / 30.7% of the measured glue, 253-304 cycles per call, and none
is an outlier. There is no single hot C block left to port; the C is thin,
evenly spread setup code interleaved with three already-optimized ASM routines.
Combined with the four pre-existing ASM children, this is the evidence that the
alias raster path is converged at the source level.

> **Withdrawn 2026-10-01.** The uniformity observation may well be true, but it
> was not established by this table: every per-call value here is at or below
> the instrumentation that produced it. "No outlier" is what a clock-dominated
> measurement looks like regardless of the code. The *conclusion* (do not port
> this C) still happens to be the right call, and for a better reason — see
> "Alias attribution corrected" — but it is not supported by this evidence.

**Methodology note, because it changes how these numbers may be used.** Each
added ENTER/LEAVE pair costs two `Sys_FloatTime` reads, and this level added
16 reads per rasterized triangle: 923,482 extra reads and 6.98 s across the
frame. That is **~253 cycles per timer read**, which is the same order as the
regions being measured. Consequences:

- Absolute seconds for the three new nodes are inflated by their own
  instrumentation and must not be quoted as real work.
- Per-call cycles are also inflated, but by a near-constant addend, so the
  *ranking* and the *relative* split within the glue are sound. That is what
  the table above is for. **(2026-10-01: this second bullet is also withdrawn.
  When the signal is smaller than the addend, the ranking is an artifact of call
  counts, not of cost. The measured per-call figures are 253-304 cycles against
  a ~193-cycle read, leaving 25-38% signal, so the split is not sound.)**
- The four pre-existing nodes are directly comparable across runs: they moved
  by at most 11 ms between the previous level and this one.

