# Microbenchmark results behind the promoted defaults

Moved verbatim out of `BUILD-DOS.md`, section `## 486 microbenchmark build`, which
mixed result write-ups into the operational build reference. Each section is
now top-level here, so its heading lost one `#`; the prose is unchanged.
Ledger index: [`../INDEX.md`](../INDEX.md).

## Memory helper experiment result

A matched run on 2026-09-10 used DOSBox-X 2026.08.31, `cputype=486`, fixed
33445 cycles, the baseline `-O2 -march=i486` build, and the staged `id1`
payload.  All C and ASM checksums matched and the report ended with
`486 benchmark correctness PASS`.

The median results show that the assembly is promising but not yet an engine
integration decision:

| Case | ASM median versus C |
| --- | ---: |
| `memcpy`, aligned, 256 bytes | 12.273% faster |
| `memcpy`, aligned, 1024 bytes | 4.569% faster |
| `memcpy`, both pointers offset by one, 255 bytes | 8.198% faster |
| `memcpy`, source offset one/destination offset two, 255 bytes | 64.400% faster |
| `memset`, aligned, 256 bytes | 15.951% faster |
| `memset`, aligned, 1024 bytes | 6.104% faster |
| `memset`, destination offset by one, 255 bytes | 15.810% faster |

The first implementation used a hand-written byte loop for the
mismatched-alignment copy and was 94.743% slower.  Replacing that fallback
with 486-compatible `rep movsb` removed the regression.  The remaining gain
comes from keeping alignment/count handling in one assembly routine and using
`rep movsl`/`rep stosl` for dword-sized work; this is microbenchmark evidence,
not proof that every Quake call site benefits.

The normal build keeps these functions out of the real execution path.  The
following opt-in runtime variant uses the same routines only after identifying
call-site alignment and size distributions, then checking exact framebuffer
results with a matched multi-run `demo1` timedemo.

The runtime switch above is the controlled integration candidate.  It keeps
the original C implementations as the reference and changes only the helper
dispatch in the `asm` build.  Do not use `bench-dos.ps1` with the ASM runtime
variant for C-versus-ASM timing: in that build the public C entry points are
intentionally routed to ASM.  Use the C benchmark build for the focused
correctness/microbenchmark matrix, then use matched timedemos for the runtime
comparison:

~~~powershell
.\tools\timedemo-dos.ps1 -MemoryImplementation c -Runs 3
.\tools\timedemo-dos.ps1 -MemoryImplementation asm -Runs 3
~~~

The timedemo result records `memoryImplementation` and the build manifest
records the same choice, so the two executables can be audited without relying
on filenames alone.

## Runtime memory-helper result

The controlled runtime comparison used the same baseline `-O2 -march=i486`
build, DOSBox-X 2026.08.31, `cputype=486`, fixed 33445 cycles, `demo1`, and
the same staged `id1` data.  Three runs per variant produced 969 frames and
the exact final framebuffer checksum `4154140932` on every run.

| Variant | Timedemo seconds, three runs | Mean FPS | Median FPS |
| --- | --- | ---: | ---: |
| C reference | 69.174217 / 69.174208 / 69.174256 | 14.008107 | 14.008109 |
| ASM runtime | 69.159824 / 69.159891 / 69.159892 | 14.011016 | 14.011011 |

The ASM path is repeatably **0.0208% faster** in this DOSBox-X run, or about
14.4 ms over the 69.17-second timedemo.  The gain is real but too small to
justify changing the default build; `c` remains the shipped/reference
selection and `asm` remains available for target-specific testing.  The
profiled workload made 1,019 `memset` calls over 24,738 bytes and 35,945
`memcpy` calls over 4,277,631 bytes.  98.4% of `memset` calls were destination
aligned and 97.3% of `memcpy` calls had matching source/destination alignment.
This explains why the microbenchmark wins do not become a large engine win:
the helpers touch relatively little data compared with the renderer's major
hotspots.

The focused matrix was rerun against the current C reference and ASM routines
with five alternating samples per case; it ended with
`486 benchmark correctness PASS`.  The ASM path uses alignment-aware setup and
`rep movsl`/`rep stosl`, with `rep movsb` for mismatched-copy alignment.  The
full timedemo confirms functional equivalence, but the measured end-to-end
advantage is diagnostic rather than a reason to make ASM the default.

## Texture-axis cache probe result

The next isolated experiment kept the `D_GetTextureAxes` hash, miss path, and
vector transforms in C, and replaced only the three-key cache hit/miss condition
with a hand-written 486 helper.  The C helper and ASM helper were checked against
hit, each individual key mismatch, and a null entry before timing.

The focused benchmark used five alternating samples of 500,000 calls per case:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Cache hit | 0.358844 s | 0.358850 s | -0.002% |
| Early `texinfo` miss | 0.269138 s | 0.269138 s | 0.000% |

The run ended with `486 benchmark correctness PASS`.  A one-run full `demo1`
timedemo using the ASM probe completed all 969 frames at 14.001678 FPS with the
same framebuffer checksum `4154140932` as the C/reference runs.  Because the
focused result shows no measurable advantage, the original C condition remains
the default and the ASM probe remains an opt-in learning aid rather than an
integration candidate.

## Surface-cache predicate result

The surface-cache experiment replaced only the cache-validity predicate in
`D_CacheSurface`.  The ASM helper compares the cache pointer, dlight state,
surface/frame invalidation key, texture pointer, and four light adjustments;
allocation and `R_DrawSurface` remain untouched.  The original C predicate is
still the default path.

The focused benchmark used five alternating samples of 500,000 calls per case:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Cache hit | 0.598076 s | 0.568170 s | 5.000% |
| Texture miss | 0.388750 s | 0.373800 s | 3.846% |
| Early dlight rejection | 0.299037 s | 0.284088 s | 4.999% |

The matrix ended with `486 benchmark correctness PASS`.  Disassembly showed
why the isolated helper wins: the standalone C probe reloads the light-adjustment
pointer for its last comparison, while the ASM probe keeps it live.  That result
does not describe the real C path, where GCC already inlines the predicate and
allocates registers across the surrounding function.

Matched three-run `demo1` timedemos therefore rejected integration:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.174276 / 69.174257 / 69.174263 | 14.008100 |
| ASM predicate | 69.194989 / 69.194988 / 69.194975 | 14.003905 |

All runs completed 969 frames with framebuffer checksum `4154140932`.  The ASM
call boundary costs about 0.030% end-to-end, or 20.7 ms per timedemo, so C
remains the default and the surface-cache ASM path remains an opt-in experiment.

## Mip-level selector result

The mip-level experiment replaced the compact `D_MipLevelForScale` function with
a 486 x87 implementation.  The C and ASM selectors were checked at every
threshold, between thresholds, below the final threshold, and with a raised
`d_minmip` clamp.  Because the standalone benchmark command runs before a map
view initializes `d_scalemip`, the harness temporarily installs the known
baseline thresholds `1.0`, `0.4`, and `0.2`, then restores the renderer globals.

The focused benchmark used five alternating samples of 500,000 calls per case:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Level 0 | 0.284087 s | 0.299038 s | -5.263% |
| Level 1 | 0.358844 s | 0.358850 s | -0.002% |
| Level 2 | 0.418657 s | 0.418657 s | 0.000% |
| Level 3 | 0.418657 s | 0.388750 s | 7.143% |
| `d_minmip` clamp | 0.343894 s | 0.373801 s | -8.697% |

The corrected matrix ended with `486 benchmark correctness PASS`.  Disassembly
showed that keeping the scale on the x87 stack removes the initial ASM reload
penalty, but the resulting branch paths still trade wins and losses by mip
level.  The real C function already uses one x87 value across its comparisons.

Matched three-run `demo1` timedemos rejected integration:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.174320 / 69.174332 / 69.174286 | 14.008088 |
| ASM selector | 69.180708 / 69.180710 / 69.180694 | 14.006795 |

All runs completed 969 frames with framebuffer checksum `4154140932`.  The ASM
selector is about 0.0092% slower, or 6.4 ms per timedemo, so C remains the
default and the x87 implementation remains a reversible learning experiment.
The next candidate should be measured only after identifying a path where the
compiler cannot already retain the relevant state across the full function.

## Turbulent-span inner-loop result

The active turbulent sampler is a compact, sequential 486 loop: the sine
table, fixed-point coordinates, destination, and span count stay in registers;
the texture address is derived with shifts and indexed loads.  The preserved C
reference was benchmarked against the existing assembly at 4, 8, 16, and
64-pixel spans using five alternating samples of 50,000 calls per case.  All
four cases produced identical checksums and destination advancement.

| Span length | C median | Existing ASM median | ASM versus C |
| ---: | ---: | ---: | ---: |
| 4 | 0.231757 s | 0.183910 s | 20.645% |
| 8 | 0.435101 s | 0.327449 s | 24.742% |
| 16 | 0.841793 s | 0.614521 s | 26.999% |
| 64 | 3.281913 s | 2.336964 s | 28.793% |

The focused report is `out\dos-bench-20260910-163948\bench-result.json`.
This confirms the value of the existing hand-written loop, but it does not
justify a new rewrite by itself because the target already runs that ASM path.

The follow-up `stosb` variant removes the explicit destination increment and
uses `STOSB` for the sequential store.  Its corresponding focused ASM medians
were 0.183910, 0.327449, 0.614521, and 2.336965 seconds.  At the report
precision that is 0.000% versus the existing ASM in every case; the 64-pixel
case is fractionally slower in this isolated harness.  The matched end-to-end
result nevertheless favored `stosb`: current ASM measured 69.178593 seconds
versus 69.118956 seconds for `stosb` across three runs, or 0.086207% faster
(0.086284% by median FPS).  All six runs completed 969 frames with framebuffer
checksum `4154140932`.  This is
consistent with the shorter sequential-store instruction sequence in the real
renderer loop; the isolated harness is dominated by equal state-reset and
function-call overhead.  `stosb` is now the target default, while
`-TurbulentImplementation asm` remains the reversible control.  The variant
report is `out\dos-bench-20260910-161309\bench-result.json`.

The matched timedemo results are
`out\dos-timedemo-20260910-164048\timedemo-result.json` and
`out\dos-timedemo-20260910-164524\timedemo-result.json`.

## Alias-project projection result

The alias projection experiment targets the clipped-model path that remains in
C after the larger unclipped transform is already in assembly.  The C compiler
emits three separate x87 control-word save/set/restore sequences around the
truncating `fistp` stores.  The ASM version preserves the same divide,
multiplication order, truncation mode, and output layout, but performs one
control-word transition for all three stores.

The focused benchmark used five alternating samples of 100,000 calls for three
representative projected points.  All output structures and checksums matched:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Far | 0.122609 s | 0.113638 s | 7.317% |
| Near | 0.122608 s | 0.113638 s | 7.316% |
| Viewmodel | 0.122609 s | 0.113638 s | 7.317% |

The focused reports are `out\dos-bench-20260910-170809\bench-result.json` and
`out\dos-bench-20260910-170826\bench-result.json`; both ended with
`486 benchmark correctness PASS`.

Matched three-run `demo1` timedemos completed all 969 frames with framebuffer
checksum `4154140932` on every run:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.118988 / 69.118947 / 69.119012 | 14.019302 |
| ASM projection | 69.106757 / 69.106747 / 69.106757 | 14.021783 |

ASM is 12.231 ms faster per timedemo, or 0.017696%.  The focused gain is
larger because it isolates the helper; the whole-engine result is the authority.
The ASM implementation is now the target default, while
`-AliasProjectImplementation c` remains the reversible reference/control.
The matched timedemo results are `out\dos-timedemo-20260910-170850\timedemo-result.json`
and `out\dos-timedemo-20260910-171246\timedemo-result.json`.

## Texture-animation frame-selection result

This experiment kept alternate-animation selection, the no-animation fast
path, relative-time calculation, and error handling in C.  It replaced only
the loop that follows `anim_next` until `anim_min <= relative < anim_max`.
The ASM loop keeps the current texture pointer, relative phase, and traversal
count in registers and uses the 486's simple integer compare/branch path.

The focused benchmark used five alternating samples of 500,000 calls per
case.  Correctness checked every relative phase from every starting node in
2-, 4-, and 8-frame synthetic cycles:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| 2-frame first | 0.373801 s | 0.254188 s | 31.999% |
| 4-frame middle | 0.672833 s | 0.583126 s | 13.333% |
| 8-frame tail | 1.420422 s | 1.405472 s | 1.052% |
| 8-frame wrap | 0.493414 s | 0.388750 s | 21.212% |

Both runs ended with `486 benchmark correctness PASS`.  The focused reports
are `out\dos-bench-20260910-173504\bench-result.json` and
`out\dos-bench-20260910-173545\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.106714 / 69.106726 / 69.106788 | 14.021790 |
| ASM frame loop | 69.100226 / 69.100204 / 69.100272 | 14.023109 |

ASM is 6.500 ms faster per timedemo, or 0.009406%.  The improvement is small
but repeatable on the pinned profile, so ASM is now the controlled default;
`-TextureAnimationImplementation c` remains the explicit reference/control
build.  The timedemo results are `out\dos-timedemo-20260910-173632\timedemo-result.json`
and `out\dos-timedemo-20260910-174027\timedemo-result.json`.

## Lightmap normalization result

This experiment extracted only the final `R_BuildLightMap` loop that inverts,
shifts, and clamps the accumulated light values.  The C reference preserves
the original arithmetic and clamp order.  On the DJGPP 486 build, its loop
stores the intermediate value before the clamp and stores again afterward;
the hand-written ASM keeps the lightmap pointer and count in registers and
stores only the final value once per element.

The focused benchmark used five alternating samples of 25,000 normalizations
per case.  It covered a normal 16-element lightmap, a fully clamped
64-element lightmap, and a mixed 324-element maximum-size lightmap.  All
checksums matched and both runs ended with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| 16-element normal | 0.134575 s | 0.121861 s | 9.447% |
| 64-element clamped | 0.493414 s | 0.444819 s | 9.849% |
| 324-element mixed | 2.437136 s | 2.194174 s | 9.969% |

The focused reports are `out\dos-bench-20260910-180627\bench-result.json`
and `out\dos-bench-20260910-180708\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference | 69.100305 / 69.100324 / 69.100226 | 14.023093 |
| ASM normalization loop | 69.081314 / 69.081262 / 69.081366 | 14.026948 |

ASM is 19.0 ms faster per timedemo, or 0.0275%.  The improvement is small but
repeatable on the pinned profile and the exact framebuffer checksum matches,
so ASM is now the controlled default; `-LightMapNormalizeImplementation c`
remains the explicit reference/control build.  The timedemo results are
`out\dos-timedemo-20260910-180756\timedemo-result.json` and
`out\dos-timedemo-20260910-181150\timedemo-result.json`.

## BSP plane-dot result

This experiment isolated the `R_RecursiveWorldNode` calculation that chooses
the front child from an axis-aligned or generic plane.  The original C path
remains inline in the production function; the ASM build calls a small helper
that uses direct x87 loads/subtracts for X/Y/Z planes and the C multiply/add
order for generic planes.

The focused benchmark used five alternating samples of 500,000 calls per
case.  All four cases produced identical C/ASM results and both runs ended
with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Axis X | 0.284088 s | 0.224281 s | 21.052% |
| Axis Y | 0.224282 s | 0.254188 s | -13.334% |
| Axis Z | 0.254188 s | 0.284087 s | -11.763% |
| Generic | 0.403701 s | 0.388750 s | 3.703% |

The focused reports are `out\dos-bench-20260910-183819\bench-result.json`
and `out\dos-bench-20260910-183844\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C inline switch | 69.081304 / 69.081398 / 69.081343 | 14.026942 |
| ASM helper call | 69.106675 / 69.106670 / 69.106686 | 14.021800 |

The ASM helper is 25.3 ms slower per timedemo, or 0.0367%.  The isolated
results do not overcome the call boundary and branch-layout cost in the real
recursive walk, so C remains the default and `-BspPlaneDotImplementation asm`
remains an opt-in 486 learning aid.

The timedemo results are `out\dos-timedemo-20260910-183914\timedemo-result.json`
and `out\dos-timedemo-20260910-184313\timedemo-result.json`.

## BSP frustum-clipping result

This experiment isolates the four-plane frustum clip block in
`R_RecursiveWorldNode`. The i486 default selects the assembly helper; the C
loop remains available as the parity reference. The 2026-09-10 measurements
below describe the original generic-loop implementation and are retained as a
historical baseline.

The focused benchmark used five alternating samples of 200,000 calls per
case.  All five cases produced identical C/ASM results and both runs ended
with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| No active planes | 0.352864 s | 0.155505 s | 55.931% |
| All visible | 1.381551 s | 1.393505 s | -0.865% |
| Partial clip | 1.285852 s | 1.345659 s | -4.651% |
| Early reject | 0.352870 s | 0.316984 s | 10.170% |
| Single plane | 0.586115 s | 0.610036 s | -4.081% |

The focused reports are `out\dos-bench-20260910-194325\bench-result.json`
and `out\dos-bench-20260910-194526\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33445 cycles, the baseline `-O2 -march=i486` build, and the same staged
`id1` data.  Every run completed 969 frames with framebuffer checksum
`4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C inline clip loop | 69.081318 / 69.081351 / 69.081286 | 14.026947 |
| ASM helper | 69.271228 / 69.271287 / 69.271216 | 13.988492 |

The original generic-loop helper was 189.9 ms slower per timedemo, or 0.2749%.
That result predates the current i486 assembly default and the unrolled helper
measured below.

The timedemo results are
`out\dos-timedemo-20260910-194827\timedemo-result.json` and
`out\dos-timedemo-20260910-195220\timedemo-result.json`.

### 2026-10-16 unrolled assembly follow-up

The generic four-plane loop was replaced with an unrolled i486 x87 schedule
based on the C oracle's optimized order. It loads each plane's normal once,
reuses the values for reject and accept points, and returns the same reject
sentinel or reduced clip mask. The C implementation remains intact under the
benchmark build for direct parity checks.

`rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -BspClipOnly -NoBootstrap`
passed the complete strict i486 gate and all five 200,000-call cases. Every C
and ASM checksum matched. The displayed medians and differences were:

| Case | Checksum | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: | ---: |
| No active planes | 1751791936 | 0.149525 s | 0.149525 s | 0.000% |
| All visible | 1751791936 | 1.106433 s | 1.106433 s | 0.000% |
| Partial clip | 2258867200 | 1.082513 s | 1.082513 s | 0.000% |
| Early reject | 0 | 0.281098 s | 0.281098 s | 0.000% |
| Single plane | 3503583872 | 0.382771 s | 0.382771 s | 0.000% |

The strict build audited 240,841 project instructions and 279,138 linked
executable instructions with zero above-i486, unknown, or exempt instructions;
the startup and DPMI provider audits also passed with zero exemptions. Equal
displayed timings show parity within the emulator timer's resolution, not a
measured speedup on physical 486 hardware. The report is
`out\dos-bench-20261016-054236\bench-result.json`; whole-frame capture parity
after this follow-up remains unverified.

## Alias bounding-box projection result

This experiment isolated the projection and four-way XY clip loop in
`R_AliasCheckBBox`.  The original C loop remains in the source as the
reference implementation; the ASM build selects a small helper that keeps
the two vertex pointers, loop state, and clip masks in registers.  It uses
the x87 reciprocal once per eligible vertex and reuses it for the X and Y
projections.

The focused benchmark used five alternating samples of 200,000 calls per
case.  All four cases produced identical C/ASM results and ended with
`486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Inside, 8 vertices | 2.476012 s | 2.015502 s | 18.599% |
| Mixed XY clipping, 8 vertices | 2.523859 s | 2.063348 s | 18.246% |
| Z-clipped, 16 vertices | 3.002316 s | 2.398260 s | 20.120% |
| All-left clipping, 8 vertices | 2.476012 s | 2.063341 s | 16.667% |

The focused report is `out\dos-bench-20260910-202504\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31,
`cputype=486`, fixed 33445 cycles, the baseline `-O2 -march=i486` build, and
the same staged `id1` data.  Every run completed 969 frames with framebuffer
checksum `4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference loop | 69.081275 / 69.081372 / 69.081242 | 14.026956 |
| ASM helper | 69.063016 / 69.062994 / 69.063055 | 14.030664 |

The ASM helper is 18.259 ms faster per timedemo, or 0.0264%.  A matching
instrumented one-run profile also preserved the checksum (instrumentation
changes timing): C took 76.930752 s and ASM took 76.912577 s.  The profile
workload contained 5,470 alias-model work items and 43,956,198 texture pixels,
which explains why a strong 16.7--20.1% isolated loop result becomes a small
end-to-end gain.  The repeatable release win is sufficient for the ASM path to
be the default, while the C path remains a build-time control for regression
testing.

The timedemo results are
`out\dos-timedemo-20260910-202746\timedemo-result.json` and
`out\dos-timedemo-20260910-203140\timedemo-result.json`.

## Clipped alias vertex transform result

This experiment isolated `R_AliasTransformFinalVert`, the C-only transform and
lighting helper used for clipped alias-model vertices.  The C body remains
intact as the reference implementation.  The ASM helper expands the three
packed vertex coordinates once, keeps the three matrix dot products on the
x87 stack, and combines the lighting dot product before returning the same
fields.

The focused benchmark used five alternating samples of 200,000 calls per
light case.  The C and ASM helpers matched byte-for-byte, including untouched
sentinel fields, and the run ended with `486 benchmark correctness PASS`:

| Case | C median | ASM median | ASM versus C |
| --- | ---: | ---: | ---: |
| Ambient light | 0.627982 s | 0.502383 s | 20.000% |
| Shaded light | 0.687788 s | 0.514343 s | 25.218% |
| Clamped light | 0.693769 s | 0.520329 s | 25.000% |

The focused reports are
`out\dos-bench-20260910-210423\bench-result.json` and
`out\dos-bench-20260910-211039\bench-result.json`.

Matched three-run `demo1` timedemos used DOSBox-X 2026.08.31,
`cputype=486`, fixed 33445 cycles, the baseline `-O2 -march=i486` build, and
the same staged `id1` data.  Every run completed 969 frames with framebuffer
checksum `4154140932`:

| Variant | Timedemo seconds, three runs | Median FPS |
| --- | --- | ---: |
| C reference helper | 69.063022 / 69.062948 / 69.062989 | 14.030670 |
| ASM helper | 68.958781 / 68.958804 / 68.958785 | 14.051872 |

The ASM helper is 104.204 ms faster per timedemo, or 0.150883%.  The gain is
consistent across the three runs and comes from removing repeated byte
loads and C-generated temporary traffic while using the same x87 arithmetic;
the function call boundary is shared by both variants.  This is a measured
end-to-end win, so the ASM path is now the default, while
`-AliasTransformFinalImplementation c` remains available for regression and
matched A/B runs.

The timedemo results are
`out\dos-timedemo-20260910-211835\timedemo-result.json` and
`out\dos-timedemo-20260910-211109\timedemo-result.json`.

## Rejected negative-gradient Z-span unroll

A 486-specific experiment mirrored the positive-gradient eight-pixel
`SHLD`/`ROR` packing schedule in the negative-gradient `D_DrawZSpans` loop.
The current seeded recheck is the authoritative result for this selector; the
older measurements below remain historical and are not mixed into acceptance.
All three optimized and control timedemos completed 969 frames and retained
the canonical seeded framebuffer checksum `1047377823`. The optimized runs
measured `59.419754`, `59.419747`, and `59.419764` seconds; the four-pixel
control measured `59.419770`, `59.419740`, and `59.419744` seconds.
The optimized median was marginally slower, so the experiment was reverted and
the existing four-pixel negative-gradient path remains the release default.

Texture-span `viewspantable` dest addressing reached **14.250078 FPS**
(`67.999624` seconds median; `out\dos-timedemo-20260911-063418`).
Extending `viewspantable` to polyset, sprites, and particles reached
**14.251887 FPS** (`67.990997` seconds median;
`out\dos-timedemo-20260911-064221`).
Sprite/particle `zspantable` Z addressing reached **14.252866 FPS**
(`67.986326` seconds median; `out\dos-timedemo-20260911-065037`).
A 1200 KB surface cache reached **14.373452 FPS**
(`67.415956` seconds median; `out\dos-timedemo-20260911-133815`).
A 1800 KB surface cache reached **14.409100 FPS**
(`67.249168` seconds median; `out\dos-timedemo-20260911-134300`).
`Turbulent8` `viewspantable` dest rows reached **14.409378 FPS**
(`67.247873` seconds median; `out\dos-timedemo-20260911-143822`).
The static `D_CacheSurface` hit path reached **14.413306 FPS**
(`67.229543` seconds median; `out\dos-timedemo-20260911-152128`).
The `D_PolysetDrawFinalVerts` clip-rect hoist reached **14.415652 FPS**
(`67.218606` seconds median; `out\dos-timedemo-20260911-152839`).
Skipping unused extra light styles on cache hits reached **14.419549 FPS**
(`67.200437` seconds median; `out\dos-timedemo-20260911-154031`).
`D_RasterizeAliasPolySmooth` dest/Z row tables reached **14.422704 FPS**
(`67.185736` seconds median; `out\dos-timedemo-20260911-161154`).
`R_RenderFace` surfedges hoist plus clip unroll reached **14.441731 FPS**
(`67.097222` seconds median; `out\dos-timedemo-20260911-173034`).
Clipped-bmodel `surfedges` hoist reached **14.441920 FPS**
(`67.096341` seconds median; `out\dos-timedemo-20260911-174206`).
`R_DrawSurface` 8-bit setup reached **14.442450 FPS**
(`67.093880` seconds median; `out\dos-timedemo-20260911-174904`).
Mipscale step tables in `D_CalcGradients` reached **14.442880 FPS**
(`67.091882` seconds median; `out\dos-timedemo-20260911-182120`).
Skipping the unused `D_CacheSurface` `surfscale` FDIV reached
**14.444235 FPS** (`67.085585` seconds median;
`out\dos-timedemo-20260911-191612`).
A 15-way last-segment divisor switch matched the checksum but was
27.6 ms slower (`out\dos-timedemo-20260911-150819`).
1900 KB, 2000 KB, 2100 KB, and 2400 KB all produced checksum
`2955717646` and were reverted.  A branched POT skinwidth shift in
`D_PolysetCalcGradients` matched the checksum but was 11.7 ms slower
(`out\dos-timedemo-20260911-140630`).
Hoisting `aliasvrect` locals in `R_AliasPreparePoints` matched the
checksum but was 15.7 ms slower (`out\dos-timedemo-20260911-153350`).
Unclipped alias `movzbl` expansion was noise
(`out\dos-timedemo-20260911-155009`).  Fused frustum `minmaxs`
multiplies hitched on run 3 (`out\dos-timedemo-20260911-155650`).
Stacking `acolormap` in `D_PolysetDrawFinalVerts` was 0.18 ms slower
(`out\dos-timedemo-20260911-160304`).
A last-used `D_CalcGradients` step-origin cache was 34.3 ms slower
(`out\dos-timedemo-20260911-161755`).
Unrolling `R_RenderBmodelFace` clip planes was noise
(`out\dos-timedemo-20260911-173554`).
Folding `R_DrawSurface` soffset wrap into the column POT test hitched
(`out\dos-timedemo-20260911-175849`).
Hoisting `currententity->model` in `R_RenderFace` was noise
(`out\dos-timedemo-20260911-180409`).
Skipping `R_AnimateLight` IDIV for `len==1` was 2.1 ms slower
(`out\dos-timedemo-20260911-180922`).
Hoisting `r_pcurrentvertbase` in `R_RenderFace` was 32.0 ms slower
(`out\dos-timedemo-20260911-182623`).
Precomputing mip-scaled `transformed_modelorg` was 4.2 ms slower
(`out\dos-timedemo-20260911-183436`).
Skipping no-op bmodel Restore/Set CALLs in `D_DrawSurfaces` was
1.4 ms slower (`out\dos-timedemo-20260911-184541`).
A per-surface compare/direct `D_DrawSpans16` call was 9.3 ms slower
(`out\dos-timedemo-20260911-185331`).
Hoisting `r_drawpolys` out of `R_RecursiveWorldNode` surface loops
hitched to 1.89 FPS (`out\dos-timedemo-20260911-185857`).
`skintable` start addressing in `D_RasterizeAliasPolySmooth` was
178.6 ms slower (`out\dos-timedemo-20260911-190512`).
Skipping live `blocksize` in `R_DrawSurface` produced checksum
`2281919689` (`out\dos-timedemo-20260911-192431`).
Hoisting `r_drawsurf.surfmip` in `R_DrawSurface` was noise
(`out\dos-timedemo-20260911-193158`).
`-OptimizationProfile baseline` still builds `-O2` into `out\dos-baseline`.
An older 14.122 vs 13.917 FPS comparison predates the current ASM defaults
and is superseded.

Use `-Instrumentation` with `-Benchmark` to build `out\dos-profile\qprof.exe`
and collect the hierarchical renderer profile through the timedemo runner:

~~~powershell
.\tools\timedemo-dos.ps1 -Instrumentation -Runs 1
~~~

Instrumentation changes timing, so its FPS is diagnostic only.  The release
`qbench.exe` timedemo remains the authority for performance comparisons.  The
profile build writes three artifacts beside the executable in its DOS staging
directory:

- `timedemo.txt` contains the legacy flat counters plus a readable tree and a
  ranked self-time list.  With `-fpsstats`, it also contains the concise
  per-frame FPS summary.
- `timedemo.jsn` is an 8.3-safe JSON document containing the FPS summary,
  percentiles, variation, event counts, and sample-storage diagnostics.
- `profile.jsn` is an 8.3-safe JSON document containing node statistics,
  observed parent-to-child edges, benchmark metadata, workload metrics, and
  `memory` call/byte/alignment counters.
  The runner embeds both JSON documents under each run in
  `timedemo-result.json`.

Render the machine-readable profile as a tree and ranked views with:

~~~powershell
.\tools\profile-report.ps1 `
  -ProfileJson '.\out\dos-timedemo-YYYYMMDD-HHMMSS\quake\profile.jsn' `
  -BaselineResult '.\out\dos-timedemo-YYYYMMDD-HHMMSS\timedemo-result.json'
~~~

`-BaselineResult` is optional; when supplied, the report estimates profiling
overhead from the matched release timedemo.  It also reads a sibling
`timedemo.jsn` and prints the per-frame FPS summary.  `-BaselineSeconds
<seconds>` can be used instead when the release result is stored elsewhere.

The profile is a fixed-stack instrumentation layer designed for repeated
486-class runs.  Its observed execution graph is:

~~~text
frame
|- input
|- game
|- screen
|  |- view
|     |- view-lights
|     |- renderer
|        |- setup / visibility
|        |- edge-drawing
|           |- world-bsp
|           |- edge-scan
|              |- surfaces
|                 |- surface-cache / gradients
|                 |- texture-spans / z-spans
|                 |- turbulent-spans / sky-spans / solid-spans
|           |- brush-entities
|        |- entities -> sprites / alias-model
|        |- viewmodel -> alias-model
|        |- particles / warp
|  |- overlay / palette / present
|- audio -> sound-spatial / sound-mix / cd-audio
~~~

The JSON `edges` array is the authoritative parent-to-child relationship.  It
is collected from the actual runtime stack, so `sound-mix` can correctly
appear below an extra render update as well as below the normal audio phase.
The tree reports edge-inclusive and edge-self time for each occurrence, while
the node records aggregate totals across all parents.  Inclusive time answers
"how expensive is this subsystem with its children"; self time answers "what
remains in this node after measured children" and identifies expensive leaf
operations.  Nested percentages must not be added together.

The profiler times the stable frame, screen, view, renderer, edge, surface,
cache, gradient, span, entity, particle, sound, and present boundaries.  It
does not time every recursive BSP or scanline callback.  Instead it counts BSP
nodes/leaves/culls/surface tests, scanlines, edge insert/remove/step calls,
span flushes, surface classes, spans/pixels/16-pixel segments, alias models
and vertices, particles, presented rectangles/pixels, and sound updates/mixes.
That keeps the hot recursive paths lightweight while still explaining their
cost.

A matched 2026-09-10 diagnostic snapshot, collected before the clipped alias
transform promotion, measured the instrumented profile
at `77.017236` seconds and the raw release timedemo at `69.162451` seconds, an
estimated **11.36% profiling overhead**.  The profile run also used 520,782
profile timer reads plus 1,939 frame-statistics timer reads, reached stack
depth 8, and reported zero stack errors; two open scopes were intentionally
discarded when timedemo exit occurred inside the final demo message.  This
overhead is acceptable for diagnosis but the instrumented FPS must not be used
as an optimization result.

The current canonical seeded fixture was revalidated after adding the platform
coverage. The release run completed 969 frames in 59.419751 seconds
(16.307709 FPS) with framebuffer checksum 1047377823. The matched
instrumented run completed the same 969 frames in 67.282890 seconds
(14.401878 diagnostic FPS) with the same checksum. Its platform counters
were zero for joystick and collision work because the canonical timedemo uses
-nojoy; use an interactive PROFILE486 run with input enabled when measuring
those paths.

The current self-time ranking from that profile is:

The platform line in timedemo.txt has this form:

~~~text
platform joystick-reads <count> joystick-poll-iterations <count> joystick-timeouts <count> move-calls <count> hull-check-calls <count>
~~~text

| Rank | Node | Self seconds | % of profiled frame | Work |
| ---: | --- | ---: | ---: | --- |
| 1 | Texture spans | 19.708498 | 25.60% | 1,454,414 spans / 43,956,202 pixels |
| 2 | Surface cache | 11.194143 | 14.54% | 55,300 normal surfaces |
| 3 | Alias model | 9.965974 | 12.95% | 5,470 models / 417,090 vertices |
| 4 | Z spans | 8.346734 | 10.84% | 58,051 surface calls |
| 5 | World BSP | 8.312930 | 10.80% | 375,709 BSP node visits |
| 6 | Edge scan self | 6.780973 | 8.81% | 147,288 scanlines |

These are measured diagnostic hotspots, not optimization instructions.  A
later confirmation profile (`out\dos-timedemo-20260910-222107`) ranked the
same leaves: texture spans 25.67%, surface cache 14.55%, alias 12.83%,
Z spans 10.87%, world BSP 10.83%, edge-scan self 8.83%.  Unrolled 16-pixel
span stores remain the default after dword packing (noise) and a stosb loop
(~2.8% slower).  Surface-cache work should stay inline; a combined wrap-guard
plus alias view-matrix hoist won 12.4 ms.  A texture row-lookup experiment
was reverted after its faster run failed the exact framebuffer check
(`2955717646` versus the known-good `4154140932`).

