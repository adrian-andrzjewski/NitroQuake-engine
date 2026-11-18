# The `surf8` flat axis and its promotion (2026-10-02)

Extracted verbatim from `ASM486-HANDOFF.md` lines 1385-1736 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## `surf8` flat axis: three measured wins bundled and **PROMOTED, 0.0620%** (2026-10-02)

The first promotion since the profiler was corrected. Three independently
priced, individually sub-gate changes were bundled, because **the gate is on the
total delta, not on any one change** — three changes worth 0.035%, 0.014% and
0.013% cannot be promoted one at a time and are worth 0.062% together.

| component | what it removes | instructions/run | predicted |
|---|---|---:|---:|
| `SurfaceBlockMip0Rows=unroll16` | the mip-0 row-loop branch, 16 rows per iteration instead of 4 | — | 0.0132% (measured on its own today) |
| `SurfaceBlockMip1IndexHoist=hoist` | 6 of the 8 per-texel `%dh` byte moves in the mip-1 flat row | 712,176 | 0.0353% (measured on its own) |
| ...and its fully-flat body | a second mip-1 flat body for blocks with all four corners equal: the index bytes are formed once per **block** instead of once per row, and the eight no-op `addl %ebp,%edx` steps go | 11,327 × 22 = 249,194 | 0.0126% |
| **total** | | | **0.0611%** |

Three alternating pairs, control first, both from one tree, release defaults
against `-SurfaceBlockMip0Rows unroll16 -SurfaceBlockMip1IndexHoist hoist`:

```text
control: 59.656695 / 59.197208 / 59.197235 s, median 59.197235
bundle:  59.160588 / 59.160522 / 59.160546 s, median 59.160546
delta   -0.036689 s = 0.06198% faster;  969 frames and checksum 1047377823 on all six
```

The first control run is the isolated-outlier pattern recorded elsewhere in this
file; the other two controls spread 0.000027 s, so the delta is 1,359x the clean
spread, and every bundle run beat every control run including the outlier.
`bench486` correctness PASS with end checksum `2378409472`, DOS smoke clean.

**Predicted 0.036716 s from the instruction model against 0.036689 s measured —
0.07% error.** The prediction summed the two previously measured components at
their measured rates and the new one at the 1.0 cycle rate, so
`docs/OPTIMIZATION-PLAN.md` Decision 3 now has three agreeing data points.

**Promoted default re-measures at 59.160558 s median** (59.160558 / 59.160577 /
59.160502), 16.379156 FPS, checksum `1047377823` on all three, with `bench486`
PASS and smoke clean. **New baseline 59.160558 s / 16.379156 FPS**, from
59.197264 s / 16.369000.

**Three traps, each of which cost a build-and-run cycle. All three are
generalisable, and two of them are the reason this entry is long.**

1. *The fully-flat test must come **before** `xorl %ecx,%ecx`.* It was written
   after, next to the call it selects, so `cmpl $0,%ecx` tested a register that
   had just been zeroed, was **always true**, and every horizontal-flat block
   took the fully-flat body. That renders **checksum `3165952421`** — the same
   value, and the same class of error, as hoisting the index bytes to block
   granularity. `lightrightstep` is the value the test needs, so the test belongs
   with the other two that read the pre-clobber register state.
2. *gas does not substitute macro parameters through a nested expansion.* The
   first attempt factored the eight texels into a shared `SURF8_MIP1_FLAT_TEXELS`
   macro called from two wrappers; gas emitted the literal label
   `.LLBPatchm1fsuffix_0` eight times and the assembler rejected it as already
   defined. Two independent single-level macros with disjoint label suffixes
   (lower case for the horizontal-flat body, upper case for fully-flat) is the
   working shape. **Share assembly by copying it; gas macros are not C macros.**
3. *Do not "fix" the `unroll16` patch ladder.* Counting `.long` lines in the
   preprocessed source reads 296 for the `unroll16` configuration against a
   ladder of 408, which looks exactly like a 112-entry overflow and was changed
   to 216 — **and 216 faults.** The ladder was right and the counting method was
   wrong: it agrees with the committed ladder for `unroll4` (216) and `unroll8`
   (280) and disagrees only for `unroll16`. **Count the `0x12345678` immediates
   in the assembled object instead** — 216 / 280 / 408 — which is the number
   `R_Surf8Patch` actually walks. That is also the check that validated the
   fully-flat body's own `+64`, at 472 immediates against 328+16+64+64.

**Verification before any timedemo, both of which earned their keep.** `control`
was confirmed to reproduce the previous release path **instruction for
instruction** — 1,273 instructions, zero differences, 216 colormap immediates —
by assembling both revisions with the real toolchain and diffing the objects,
not by preprocessing (which reports the new macro's definition text as 32
"differences"). And the ladder was checked against the object before building.

**One candidate was built and abandoned in the same pass.** The mip-2
horizontal-flat block (worth 0.0064%, five instructions per row over 3,930
blocks) was written, verified to add exactly four colormap immediates to the
object, and then removed: it rendered checksum `3278041384` and the cause was not
found. It is the same shape as mip-0's and mip-1's flat rows, which are both
promoted, so the bug is in the mip-2 block's own setup rather than in the idea —
but an unresolved regression is not a candidate, and 0.0064% does not justify
shipping one. `R_DrawSurfaceBlock8_mip2` still uses its general loop.

## The Z-span integer probe, measured and retired (2026-10-02) — the harness charges 1.0 cycles per instruction, and the x87 axis stays inadmissible

An uncommitted `-ZSpanIntProbe` switch was in the tree at the start of this
pass: 22 dead integer operations per Z-span in `d_draw.s`, wired into
`build-dos.ps1` and `timedemo-dos.ps1`, never actually run. It prices a bit-exact
integer replacement of the 1/z prologue. Three alternating pairs, control first,
both variants from one tree, no `-SkipBuild` (the switch is in the profile suffix
and the build fingerprint, so each variant rebuilds itself and a probe run cannot
measure a control binary):

```text
control: 59.197254 / 59.197244 / 59.197260 s, median 59.197254   zspan-int-probe 0
probe:   60.208521 / 60.208489 / 60.208529 s, median 60.208521   zspan-int-probe 1415815
delta    1.011267 s = 1.7086% SLOWER;  969 frames and checksum 1047377823 on all six
```

**The number worth keeping is the divisor, not the delta.** The probe body is 24
instructions and ran 1,415,815 times — 33,979,560 instructions for 1.011267 s, at
33.445 MHz:

```text
1.011267 s / 33,979,560 instructions = 2.9765e-8 s  =  0.9955 cycles per instruction
```

**DOSBox-X's dynamic core prices straight-line integer work at essentially exactly
one cycle per instruction**, regardless of the operation: that chain is seven
`imull r,r` (three cycles each on a 486DX), seven `shrl`, seven `addl` with a
memory operand, two loads and one `incl`, and it still averages 0.9955. Set that
against the Z-span prologue's own measured 9.4 cycles for nine serialized x87
operations (`:819`) — 1.04 cycles per x87 op. **An integer replacement of the
prologue therefore has a break-even of fewer than 9.4 instructions**, and a
bit-exact reciprocal needs more than that: the prologue rounds to single precision
after each of three float operations, so an integer version has to reproduce that
rounding. The axis is closed by measurement. Do not resurrect it.

This also gives the project a calibration constant it did not have, and it is the
same currency every later entry prices in: **~1.0 cycle per removed instruction**,
against the 0.66 that the promoted mip-1 flat path implies for its own mix (13
instructions per row including two global loads and a store, 1,543,048 instructions
for 0.030368 s). Quote the rate that matches the instruction mix under
consideration; 1.0 is the conservative one.

The probe, its switch and its plumbing have been **removed from all four files**,
and the tree is back to a clean two-state-plus-instrumentation configuration.
Release re-measured on the final tree at **59.197237 s** median (59.197237 /
59.197223 / 59.197255), checksum `1047377823` on all three, against the promoted
59.197264 s — a 0.00005% difference, i.e. noise. New baseline unchanged:
**59.197264 s / 16.369000 FPS**.

**Two tooling traps this probe walked into, both worth not walking into again.**

1. *A dead-scratch probe must report its execution count, not its scratch value.*
   The first revision did `addl %eax,bench486_zspan_probe`, which reports the sum
   of the accumulated scratch and read `191,564,989` — a number with no
   denominator. There is no compiler in a `.s` file that could eliminate the dead
   chain, so a plain `incl` is both sufficient and the only reportable quantity.
   The comment in that block also claimed 32 operations where there are 24.
2. *`Bench486Printf` is the wrong helper inside `Bench486WriteTimedemoCounters`.*
   It writes to `bench486_report_handle` (`bench486.txt`), which a timedemo run
   never opens; the function's argument is `report_handle`, the `timedemo.txt`
   handle opened at `cl_demo.c:380`. The probe count reached the console and not
   the report, and was invisible to the run JSON. Anything reported from that
   function must go through `report_handle`.

## The `surf8` horizontal-flat axis, screened (2026-10-02) — four candidates, two closed by price

The mip-1 promotion was the mip-0 specialisation applied one level down. The
obvious continuation is to apply it to the remaining levels, and then to tighten
the mip-1 path itself. Both are priced here from counters already in the tree
(`r_surf.c:845-882`) and the calibration above. **No code was built**; this is the
screening rule at `docs/OPTIMIZATION-PLAN.md` Decision 2 applied before building.

The structural asymmetry that motivated candidates C and D: **mip-0's flat row
already hoists its colormap-index bytes and uses byte stores**
(`surf8.s:457-458` puts `movb %dh,%bh` / `movb %dh,%ch` once per row, ahead of the
16 texels), while **mip-1's flat row does neither** — `SURF8_MIP1_FLAT_ROW`
(`surf8.s:822-860`) is the general row with the light updates deleted, so it still
issues 4 + 4 of those byte moves per eight-texel row and packs through `%eax` and
`rorl $16`. Both were written after the fact; only one of them was finished.

| candidate | mechanism | removed instr/run | price at 1.0 cy | vs the 0.05% gate |
|---|---|---:|---:|---:|
| A | mip-2 horizontal-flat block, 4×4 | 3,930 × 4 rows × 12 = 188,640 | 0.00564 s = **0.0095%** | 5.2× under |
| B | mip-3 horizontal-flat block, 2×2 | 591 × 2 × 10 = 11,820 | 0.00035 s = **0.0006%** | 83× under |
| C | hoist the two `%dh` byte moves out of `SURF8_MIP1_FLAT_ROW`, 31 → 25 instructions per row | 118,696 × 6 = 712,176 | 0.02129 s = **0.0360%** | **built and measured below** |
| D | fully-flat blocks hoist `%dh` once per block instead of once per row (`fully_flat_per_mip[1] = 11,327`) | 11,327 × 14 = 158,578 | 0.00474 s = **0.0080%** | 6.2× under |

**A and B close. C was built and measured: 0.0353%, real, reproducible, and
below the gate, so it is rejected — see the entry below. D closes at 6.2× under.**

One correction this screening produced, which matters more than any of the four:
the first draft priced C and D at 0.66 cycles per instruction and concluded
0.029% — a refusal. **The 0.66 is the rate implied by the promoted mip-1 mix** (13
instructions per row including two global loads and a global store). C removes
**register-only partial moves**, which is much closer to the probe's straight-line
mix, and the probe measured that at 0.9955. At the measured rate C is 0.036%, and
building it confirmed the model to 2%. **Price a candidate at the rate that
matches its own instruction mix, or the screening is wrong by 50%** — and at
0.029% the decision would have been to not build something that turned out to be
a clean, bit-exact, reproducible win.

## mip-1 flat-row index hoist (2026-10-02) — **0.0353% alone; promoted at 0.0620% as part of a bundle**

> **Superseded by the entry above.** This change was measured on its own first,
> at 0.0353% — real, bit-exact, reproducible, and **below the 0.05% gate, so on
> its own it is not promotable.** It was later bundled with `unroll16` and a
> fully-flat variant of the same path, and the bundle cleared the gate at
> **0.0620%** and is now the release default. The measurements below stand; the
> conclusion "rejected" applies only to the isolated change.

Candidate C from the entry above: `SURF8_MIP1_FLAT_ROW` re-forms the two
colormap index registers with four `movb %dh,%bh` / `movb %dh,%ch` pairs per
eight-texel row, and `%dh` is invariant across the row, so two instructions at
the top of the row replace eight. mip-0's flat row has had this shape since it
was written (`:457-458`); mip-1's was only ever the general row with the light
updates deleted.

An opt-in `-SurfaceBlockMip1IndexHoist control|hoist` selector was added to all
four runners for a matched A/B, with `control` reproducing the previous body
**byte-for-byte** — verified by preprocessing both revisions with the real
toolchain and diffing: 1,066 instruction lines, zero differences. Do not skip
that check on an ASM selector; see the two bugs below.

Three alternating pairs, control first, both from one tree:

```text
control: 59.197249 / 59.197235 / 59.197244 s, median 59.197244, spread 0.000014
hoist:   59.176362 / 59.176285 / 59.176354 s, median 59.176354, spread 0.000077
delta   -0.020890 s = 0.03529% faster;  969 frames and checksum 1047377823 on all six
```

Every candidate run beat every control run and the delta is 271x the control
spread, so the effect is real and not noise. **It is below the 0.05% gate on its
own, so it was not promotable on its own.** The selector was withdrawn, the
release path restored to byte-identical with `10374adcea77`, and the change re-applied
later as one component of a bundle that does clear the gate — see the entry at
the top of this section. The selector is back, and `-SurfaceBlockMip1IndexHoist
control` now reproduces exactly the body measured here.

**The calibration got a second, independent confirmation.** 712,176 instructions
for 0.020890 s is 2.9335e-8 s each, or **0.981 cycles per instruction** — against
the 0.9955 the Z-span probe measured on a completely different mix (seven
`imull`, seven `shrl`, seven `addl` with a memory operand). Two unrelated
instruction mixes, 1.5% apart. **1.0 cycle per removed instruction is a sound
screening rate for this harness**, which is the number most future screening
will need.

**Two bugs, both worth more than the win.**

1. *The hoist has to be per **row**, not per unrolled block.* The first version
   put `movb %dh,%bh; movb %dh,%ch` at the top of `LSurf8Mip1HorizontalFlatRow`,
   outside the eight unrolled `SURF8_MIP1_FLAT_ROW` invocations. That rendered
   **checksum `3165952421`**, deterministically and reproducibly. The cause is
   that each row's trailing `addl %ebp,%edx` advances the light to the next
   scanline: `%dh` is invariant *within* a row and varies *between* rows, so
   rows b..h were all indexing the colormap with row a's light byte. The
   instruction-level argument said the transform was equivalent and the
   instruction diff confirmed it removed only the 62 intended instructions — the
   mistake was one level of granularity up, in a place the diff could not see.
2. *`#error` is inert under `-x assembler-with-cpp`.* A sentinel of the form
   `#ifdef X` / `#error` / `#endif` was used to check that a selector's `-D` flag
   reached the preprocessor, and it reported "not reached" for a define that was
   demonstrably present. Use an `#ifdef`-guarded **literal** as the sentinel
   instead; that works.

**The premise was measured, not assumed.** `bench486_surf8_flat_dh_moved` reads
**0 of 118,712** flat rows, confirming `%dh` really does hold still across a
row's eight texels. Note that the counter must sample at the top and bottom of
**each row**: sampling once per unrolled block makes every row with a non-zero
vertical step look like a violation, and reported 12,819 false positives on the
first attempt. The counters are kept — they are free, and they are the evidence
for this entry and the guard against anyone retrying the block-granularity form.

Two readings from the same profile data that are worth not misreading again:

- **`surface-cache` has no prize in `D_CacheSurface`.** The report shows 472
  cycles per cache *hit* (`hit_seconds` 0.656079 s over 46,483 hits), which looks
  like a 0.86%-of-frame lookup cost. It is the profiler. `miss_check_seconds`
  measures 574 cycles for the *identical* code prefix, and 574 is three times the
  measured 193.3-cycle `Sys_FloatTime` read. The hit path simply takes fewer reads
  than the miss path. The lookup is `D_CacheSurfaceHit_asm486` and costs nothing.
- **`D_DrawSpans8` is dead in the timedemo.** `d_subdiv16` defaults to `"1"`
  (`d_init.c:27`) and nothing in the C tree sets it to 0, so `d_drawspans =
  D_DrawSpans16` at `d_init.c:164`. The proof is not the cvar: it is that
  `bench486_texture_full_tzero` reads 1,025,646 and that symbol is `.extern`'d
  only in `d_draw16.s`. `d_draw.s`'s `D_DrawSpans8` and its `Entry2_8..Entry8_8`
  table are unreachable in this workload — roughly 30 KB of `.text` that the cost
  model would count as cache displacement. That is a **blind axis**, so deleting
  it is inadmissible as a performance claim; it is code hygiene, and a separate
  change from anything in this pass.

## The unit-stride span premise is zero (2026-10-02) — `texture-spans` is closed, and the arithmetic says why every earlier attempt failed

`texture-spans` is the largest admissible pool in the renderer at **24.0% of
the profiled frame** (18.979 s of 79.169 s, 1,454,455 spans, 43,956,265 pixels)
and the only one never premise-measured. The hypothesis was the one structural
specialisation the inner loop still admits. Three counters were added to `d_draw16.s` — plain
increments, no timer reads, behind the existing `PROFILE486` guard and the
established `bench486_profile_frame_active` test (`:445`, `:472-473`, `:504`) —
and one instrumented run decided it.

The segment loop is 11 instructions per two pixels under the promoted word-store
build (`LSpan16ControlStoresA`, `d_draw16.s:674`): two texel loads, a store, and
per texel `addl tstep,%edx` / `sbbl %ecx,%ecx` / `addl %ebp,%ebx` /
`adcl advancetable+4(,%ecx,4),%esi`. A segment whose t step has no whole texel,
whose s step is exactly one texel, and whose s step has **no fractional part**,
would advance the source by one byte per sample with no carry, collapsing that
four-instruction pair into `addl $1,%esi`. The decision rule was fixed before the
run: at 1.0 cycle per instruction the gate is 1,022.8 × 969 ≈ 1.0 M instructions
per run, so at 1.5 instructions saved per pixel the candidate needed **400,000
pixels** to be worth building.

```text
span-strides segments 2059015 unit-stride-segments 0 unit-stride-pixels 0
full-tzero 1025646  full-sone 194183  full-sfrac-zero 2
```

**Zero.** Not small — zero. Whenever `(sstep>>16) == 1` the fractional part of
`sstep` is non-zero, so the s-fraction accumulator is live on every single one of
the 194,183 candidate segments and the carry chain cannot be removed. That is
structural, not incidental: the s fraction is what makes the texture wrap correctly
at a sub-texel rate, so an exactly-unit-stride span does not occur in this
workload. The premise is falsified before any code was written, which is the E4
and bmodel-`FIXME` pattern — and it cost one profile run rather than a timedemo.

**The arithmetic now explains all six earlier texture-span rejections, which is
the more useful half of this entry.** At 1.0 cycle per instruction the inner loop
accounts for 2,059,015 segments × 88 instructions = 181.2M of the 634.7M cycles
in the bucket. That leaves **220 cycles of per-segment setup for every sixteen
pixels** (308 cycles per segment in total), against 5.5 instructions per pixel of
loop — 14.4 cycles per texture pixel for the whole bucket. So:

- **The time is in the setup, not the loop.** The setup is the two `fistpl`, the
  four clamps and the `advancetable` build, and the `fistpl` half is the **blind
  axis**.
- The `norowcross` experiment at `:1821` is the direct confirmation, and its
  accounting is worth carrying forward. It was exercised on **209,338 segments**,
  removed 4 instructions per two pixels from them — 6,698,816 instructions, 36% of
  the loop on 7.6% of the pixels, worth 0.200293 s at the calibration above — and
  measured **0.580537% slower**, 0.344887 s. The candidate's per-segment
  eligibility test (`:375-386`, six instructions) adds 1,256,028 instructions.
  Net: **0.545180 s, 18.2 M cycles, added**, against 6.70 M instructions removed.
  10.3 M cycles of that are in the loop bodies themselves, not the test: the
  non-indexed `adcl advancetable+4,%esi` of the row-cross-free body costs more
  than the control body's indexed `adcl advancetable+4(,%ecx,4),%esi`, which an
  instruction count alone does not predict. **Removing four instructions per two
  pixels from 7.6% of the segments cost eighteen million cycles.**

**So the admissible integer work in `texture-spans` is not in the loop, and the
part that is in the setup is dominated by two x87 stores per segment that this
harness cannot price honestly.** ~~`texture-spans` is closed on the admissible axis
by measurement, not by exhaustion of ideas.~~ A candidate here would have to remove
per-*segment* integer work, which is a narrower description than this file has
given the bucket in any previous entry - and note that the one structural loop
specialisation anyone had proposed is now measured at zero population.

> **The second half of that sentence is now measured FALSE, and the closure does not
> stand.** A dead-scratch probe at the head of the per-segment setup measured the
> setup's integer part at **2.37% of frame, 47x the gate, containing zero x87** — see
> "the span16 per-segment setup is 2.37% of frame", under "The span16 per-segment setup is 2.37% of frame" in ``2026-10-02-edge-scan-and-texture-spans.md``. The 125
> x87 instructions in `d_draw16.s` sit in the entry divide, the `LNotLastSegment`
> advance and the tail path, **not in the setup**, so the setup was never the blind
> axis it was closed as being. `texture-spans` is **re-opened**, and four candidate
> reductions of that pool are recorded there with why each fails. The narrower
> description above — remove per-*segment* integer work — was right; the closure built
> on it was not.

The counters are kept. They are free in release, they are the denominator any
future segment-level idea needs, and `unit-stride-pixels` is a permanent guard
against re-proposing the loop specialisation.

