# Alias-raster and surface-block experiments (2026-09-29)

Extracted verbatim from `ASM486-HANDOFF.md` lines 3078-3426 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## Alias-raster child breakdown (2026-09-29) — C cost is 2.86%, not the predicted <1%

`alias-raster` is now split into its four children:
`alias-calcgradients`, `alias-linescan-setup`, `alias-scan-left-edge`, and
`alias-draw-spans`. The enum entries go after `BENCH486_PROFILE_ALIAS_RASTER`
in `src\quakedef.h`, the matching names after `"alias-raster"` in
`src\core\host_cmd.c` (the two lists must stay in identical order), and the
ENTER/LEAVE pairs are in `src\renderer\d_polyse.c` inside
`D_RasterizeAliasPolySmooth`, wrapping each call individually. The two
right-edge `linescan-setup` calls have no matching `ScanLeftEdge`; they exist
only to set `ubastep`/`erroradjust*` for the `D_PolysetDrawSpans8` right-edge
loop.

Measured from `out\dos-timedemo-20260929-095627\timedemo-result.json`
(frame total 77.643930 s, attribution only):

```text
alias-raster self   8.339431 s  10.74%   unattributed C glue
alias-draw-spans    3.287665 s   4.23%   ASM  153852 calls
alias-linescan-setup 2.222018 s  2.86%   C    263814 calls
alias-scan-left-edge 1.788217 s  2.30%   ASM  109962 calls
alias-calcgradients  1.420764 s   1.83%   ASM  124767 calls
```

Call multiplicities confirm the model: 124,767 triangles at ~22.8 per model,
2.11 line-scan setups and 1.23 draw-spans per triangle, 0.88 left-edge scans.

**A prior estimate in this session was wrong by 3.5x and is corrected here.**
The pre-measurement estimate put `D_PolysetSetUpForLineScan` at 0.32-0.63 s
(0.46-0.93% of frame), reasoning from a ~40-80 cycle `adivtab` lookup. It
actually costs **281.7 cycles per call**, because 263,814 non-inlined calls each
pay argument setup and the global write-back, and the estimate counted only the
fast-path body. It is 2.86% of frame, not under 1%. Recording the miss because
the ledger's value is precisely in not repeating wrong estimates.

Consequences for the next pass. The raster subtree is 51.1% identifiable C
(`alias-linescan-setup` at 2.86% of frame) and 48.9% ASM, and the largest single
item remains the **8.339 s of unattributed `alias-raster` self time (10.74% of
frame)** — larger than any named child. That residual is the C glue in
`D_RasterizeAliasPolySmooth`: the duplicated base/extra step precomputation at
`d_polyse.c:828-873` and `925-967`, the span-package setup blocks, and
`D_PolysetSetEdgeTable`. It has not yet been split. That residual, not the
line-scan helper, is the next thing worth instrumenting or porting.

Instrumentation integrity: `alias-models` 5470, `alias-vertices` 417090,
`line-setups` 263814, `stack-overflows` 0, `bad-leaves` 0, `max-depth` 8.
The release build is unchanged at 969 frames and checksum `1047377823`. Note the
instrumented run costs 77.6 s against 67.96 s for the previous level, so
timer reads rose from 553,450 to 1,858,372; instrumented durations are
attribution evidence only and must not be compared to release timings.

## Alias sub-node instrumentation and the alias cost breakdown (2026-09-29)

The alias-model bucket is no longer a single flat bracket. `BENCH486_PROFILE_ALIAS_SETUP`,
`BENCH486_PROFILE_ALIAS_TRANSFORM`, and `BENCH486_PROFILE_ALIAS_RASTER` were added to
`src\quakedef.h` (immediately after `ALIAS_MODEL`) and to the name table in
`src\core\host_cmd.c`. `src\renderer\r_alias.c` wraps three sub-regions of
`R_AliasDrawModel` and its two prepare helpers: the once-per-model setup
(`R_AliasSetupSkin` through `ziscale`, `r_alias.c:917-949`), the per-vertex
transform/project loop (in both `R_AliasPrepareUnclippedPoints` and
`R_AliasPreparePoints`), and the rasterizer call (the per-triangle
`D_PolysetDraw`/`R_AliasClipTriangle` loop in `R_AliasPreparePoints`, and
`D_PolysetDraw` in `R_AliasPrepareUnclippedPoints`). This is measurement only:
the `PROFILE486` macros compile to `((void)0)` in release builds, and the
release timedemo is unchanged at 969 frames and checksum `1047377823`.

The breakdown from `out\dos-timedemo-20260929-093012\timedemo-result.json`
(frame total 67.946126 s, attribution only):

```text
alias-raster      7.384299 s  10.87%   82.95% of the alias bucket
alias-transform   1.335922 s   1.97%   15.01%
alias-setup       0.181710 s   0.27%    2.04%
alias-model self  0.298821 s   0.44%   (unattributed remainder)
```

**This settles the question the previous pass could not.** The earlier
arithmetic showed the bucket cost ~716 cycles per vertex when an x87 transform
is only ~40-60, so it could not be transform-bound; the instrumentation
confirms that directly. The alias cost is overwhelmingly **rasterization**,
not setup and not the per-vertex transform. The three setup helpers
(`R_AliasSetupSkin`, `R_AliasSetUpTransform`, `R_AliasSetupLighting`,
`R_AliasSetupFrame`) together cost only 0.27%, and the per-vertex transform and
clip loop is 1.97%. Optimizing the setup prologue or the transform helper —
both of which had prior rejected experiments in the ledger — could not have
moved the needle.

The remaining alias cost is the pixel work itself: `D_PolysetDrawSpans8` and
`D_PolysetScanLeftEdge` in `src\renderer\d_polysa.s`, plus the three still-C helpers
they call, `D_PolysetSetEdgeTable`, `D_RasterizeAliasPolySmooth`, and
`D_PolysetSetUpForLineScan` in `src\renderer\d_polyse.c`. Because the pixel loops
in `d_polysa.s` are already heavily mined and the alignment experiment showed
the loop body resists rearrangement, the remaining C-to-ASM surface in the
alias raster path is the only unexhausted avenue, and it is now the
highest-value remaining target in the renderer.

Instrumentation integrity: `alias-models` is still 5470 and `alias-vertices`
still 417090, `max-depth` is 8 (was 6), and `stack-overflows` and `bad-leaves`
are both 0. The added sub-nodes cost 0.243 s (`0.36%`) against the prior
profile run. Note the three sub-nodes aggregate across both the `entities` and
`viewmodel` call sites, so their sum exceeds either single parent's inclusive
time; that is expected, not an accounting error. Because `alias-raster` now
appears directly in the ranked self-time list at 10.87%, it displaces
`world-bsp` (11.38%) and ranks third overall behind `texture-spans` (27.82%).

## Aff8 16-byte code-alignment experiment (2026-09-29) — rejected and reverted

This was the first attempt in the checkout to use the 486 code-layout axis.
Exploration had confirmed that register allocation, load scheduling, and CSE
were already mined, while **alignment padding was entirely untouched**: no NOP
filler, no `Bochs D4`-style macro, and no `.rept` filler exists in any of the
21 `.s` files, and `d_polysa.s` had exactly one `.p2align` (a `.data` label).
The Aff8 pixel loop had no alignment directives at all.

**The experiment code has since been reverted.** The temporary
`-Aff8LoopAlignment control|aligned` selector, its `ASM486_AFF8_ALIGN` define
in `src\renderer\d_polysa.s`, and the `AFF8_ALIGN` macro sites have all been
removed, along with the selector plumbing in `build-dos.ps1`, `bench-dos.ps1`,
`timedemo-dos.ps1`, and `smoke-dos.ps1`. The tree is back to its pre-experiment
state and this section is preserved as a record of the measurement. The
candidate had been defined as an `AFF8_ALIGN` macro (`.p2align 4,,15`) before
five hot labels: `LDrawLoop`, `LDraw16`, `LAff8LastGroup`, `LNextSpan`, and
`LExactlyOneLong`, with store counts, sampling order, and the fixed-point DDA
unchanged so that only instruction addresses moved.

Both variants used DJGPP GCC 12.2.0, target i586-pc-msdosdjgpp, `-O3
-march=i486`, 83 C sources, and 21 assembly sources, with the pinned
`tools\dosbox-x-486-high.conf` profile, CWSDPMI, and the seeded `demo1`
workload. Note that `qbench.exe` is **not byte-reproducible**: `host.c:912`
and `host_cmd.c:4643` embed `__TIME__`/`__DATE__` in a startup banner, so six
stamp bytes differ between any two builds of identical source. Hashes recorded
in this file identify a build, not the source; compare selectors and
framebuffer checksums instead. The control `qbench.exe` SHA-256 for this pass
was `96FC0BE537B01CA74CBC60D10D20F1610101792DCEA81D14F97396409543230B`.

The alignment was verified in the linked binaries before timing. The candidate
places `LDrawLoop` at `0x90960`, `LAff8LastGroup` at `0x90ce0`, `LNextSpan` at
`0x90cf0`, and `LExactlyOneLong` at `0x90d10`, all on 16-byte boundaries, with
13 NOP bytes of padding at `0x90ce3`-`0x90cef`. The `0x12345678` colormap
placeholder count is **189 in both binaries**, which confirms `D_Aff8Patch`
still covers all 18 patch slots and that `d_modech.c`'s
`D_PolysetAff8Start`..`End` writable range still spans every patched byte
after padding. The loop back-edge `jmp 0x90960` at `0x90cd7` confirms the
target.

Correctness and startup both passed. The candidate reported
`486 benchmark correctness PASS` with end checksum `2378409472`
(`out\dos-bench-20260929-084221\bench-result.json`) and a clean smoke test
with DOSBox-X and Quake exit codes both `0`.

Three alternating pinned `demo1` timedemo pairs followed. Every run completed
969 frames with framebuffer checksum `1047377823`:

```text
control: 59.265452 / 59.265481 / 59.265442 s; median 59.265481 s, 16.350159 FPS
aligned: 59.287251 / 59.287243 / 59.743230 s; median 59.743230 s, 16.219411 FPS
```

The aligned median is `0.477749` seconds (`0.806117%`) **slower** than
control, against a required 0.05% improvement, so the candidate was rejected
and is now fully removed. Artifacts remain in `out\dos-timedemo-20260929-085326`
through `out\dos-timedemo-20260929-085922`.

Two observations matter for interpreting this. First, the aligned spread is
`0.455987` s because the third sample (`59.743230`) is a clear outlier, while
its first two samples are only ~22 ms behind control; the project has seen
this same isolated-outlier pattern in earlier `stosw` runs. Second, and more
importantly, the direction is consistently wrong rather than noisy: even the
two clean aligned samples are slower than every control sample. The likely
cause is that the padding pushes already-large unrolled bodies across an extra
16-byte fetch boundary and displaces other lines from the 8 KB unified cache,
while the write-buffer and fetch-boundary costs this was meant to relieve turn
out not to dominate. *(Corrected: an earlier revision of this paragraph said
"I-cache placement." The 486 has no instruction cache — only an 8 KB unified
data cache — so the mechanism is fetch boundaries and unified-cache
displacement, not an I-cache.)* Because the measured effect is negative rather
than indistinguishable, this is a rejected result and not a null result. Note
also that a genuine physical-486 alignment benefit would not be expected to be
faithfully reproduced by DOSBox-X anyway (`BENCHMARK-COMPARISON.md`, under "Results", and see
"What this harness can and cannot measure" above).

## Current texture-span follow-up (2026-09-29)

A PROFILE486 control run is recorded in
`out\dos-timedemo-20260929-071039\timedemo-result.json`: 969 frames,
framebuffer checksum `1047377823`, with texture spans first at 27.92% self
time and alias models next at 13.29%. The instrumented duration is attribution
only. **This is no longer the most recent profile** — the alias subtree has
since been split into seven sub-nodes (see the sections above), which
re-attributes the alias bucket as 82.95% raster / 15.01% transform / 2.04%
setup, and reports `alias-raster` self time directly. The texture-span
percentage is unchanged; only the alias attribution is refined.

The new opt-in `-TextureSpanStores stosw` path uses unrolled `STOSW` stores
for full 16-pixel segments; `word` remains the default. Candidate smoke and
full `bench486` correctness passed (`2378409472`). Three alternating pinned
timedemo pairs retained 969 frames and checksum `1047377823`; medians were
59.265502 seconds for `word` and 59.325327 seconds for `stosw` (0.10094%
slower). Keep `stosw` only for reproducible A/B work. Full profile, timing,
spread, and artifact details are in `BUILD-DOS.md` under “Latest PROFILE486
and texture-span STOSW experiment.” Alias-model rendering is the next hotspot.

## Current parity-gated closure (2026-09-28)

The release defaults now use the mip-0 four-row and mip-1 eight-row
surface-block loops (`SurfaceBlockMip0Rows=unroll4`,
`SurfaceBlockMip1Rows=unroll8`). The mip-1 loop was promoted after a five-run
mip-0-only control median of 59.374140 seconds and a three-run combined median
of 59.344208 seconds, a 0.0504% improvement. The earlier mip-0 promotion
measured a 0.0573% gain against its control. Every timedemo completed 969
frames with framebuffer checksum `1047377823`; the candidate also passed DOS
smoke and full `bench486` correctness (`2378409472`). Both control paths remain
selectable for matched A/B comparisons.

The fresh PROFILE486 control run is
`out\dos-timedemo-20260929-055543\timedemo-result.json`. Its 67.797249-second
duration is attribution evidence, not release timing. Self-time ranking is
texture spans 27.89%, alias models 13.28%, world BSP 11.41%, surface cache
10.72%, Z spans 9.29%, and edge scanning 8.93%. The surface cache recorded
8,913 rebuilds, 6.481275 seconds of rebuild time, 5.616218 seconds in block
drawing, and no thrash frames. Mip-0 block drawing took 3.692177 seconds; the
profile counted 26,861 horizontal-flat blocks across mip levels. The release
gate remains 969 frames with checksum `1047377823`. Previously tested
texture-span addressing, load-order, and tail-store alternatives remain
rejected or below threshold. No visual-quality, resolution, presentation,
scene, or timing changes are part of this pass.

The BSP frame-count experiment remains unpromoted. Its `local` selector
preserved correctness, smoke, and release framebuffer parity, but its
three-run median was 59.435670 seconds versus 59.408194 seconds for its
control, so it did not clear the 0.05% improvement gate.

## Horizontal-flat mip-0 surface blocks (2026-09-29)

The opt-in `-SurfaceBlockMip0HorizontalFlat fast` path specializes blocks
whose top-left and top-right light values match and whose left/right vertical
steps also match. Each scanline then uses one constant light-map row, so the
drawer skips its per-texel horizontal light updates. The `control` selector
retains the original path. PROFILE486 counted 26,861 horizontal-flat blocks
across the mip levels, motivating a mip-0 specialization.

Five alternating pinned `demo1` runs measured control at
`59.344206 / 59.344204 / 59.344211 / 59.344238 / 59.344298` seconds and fast
at `59.265472 / 59.265448 / 59.265501 / 59.265486 / 59.265487` seconds. The
medians are `59.344211` and `59.265486` seconds, a 78.725 ms (0.13266%) gain;
the full timing ranges are 0.094 ms and 0.053 ms. Every run completed 969
frames with framebuffer checksum `1047377823`. Candidate smoke passed and the
full `bench486` correctness suite passed with checksum `2378409472`. Promote
`fast` as the build, smoke, benchmark, and timedemo default; `control` remains
available for A/B checks. Artifacts are in `out\dos-bench-20260929-061426`,
`out\dos-smoke`, and timedemo directories
`out\dos-timedemo-20260929-062348` through
`out\dos-timedemo-20260929-063449`.

## Pre-surface-block-loop control and PROFILE486 baseline (2026-09-28)

The exact-parity pass was re-established from the current source before the
new experiment.  The aggressive DJGPP i486 control build used the pinned
`tools\dosbox-x-486-high.conf` profile, CWSDPMI, the Steam `id1` data root,
and the current default selectors (`TextureSpanAddressing=control`).  The
benchmark executable is
`out\dos-memasm-zneg4-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm\qbench.exe`
with SHA-256
`0A9E78074153380228072A257D979E968887C7AD2311EC2DCCAAA162DC2C9EE1`.

The fresh gate artifacts are:

```text
correctness: out\dos-bench-20260928-122205\bench-result.json
smoke:       out\dos-smoke\smoke-result.json
timedemo:    out\dos-timedemo-20260928-123125\timedemo-result.json
PROFILE486:  out\dos-timedemo-20260928-123502\timedemo-result.json
```

Correctness reported `486 benchmark correctness PASS` with end checksum
`2378409472`; smoke exited cleanly with DOSBox-X and Quake exit codes `0`.
The three release timedemo runs all completed 969 frames with framebuffer
checksum `1047377823`:

```text
59.408238 / 59.408105 / 59.408106 seconds
median 59.408106 seconds, 16.310905 FPS
```

The fresh PROFILE486 run took 67.271354 seconds for attribution only.  Its
self-time ranking was texture spans 28.11%, alias models 13.38%, world BSP
11.49%, surface cache 10.03%, Z spans 9.37%, and edge scanning 9.00%.
Texture spans remain the largest renderer hotspot; after the measured
alias-span and world-BSP passes, the next eligible hotspot is the
surface-cache rebuild path.

After leaving the candidate opt-in, the default selectors were rebuilt again.
The final control `qbench.exe` SHA-256 is
`90AF568DE3DC9B8862EF7BB40D2477FB74A75E406CFD70E0A8E044A1064CFA11`; the
normal `quake.exe` SHA-256 is
`C4FD4C4DB5D303479CF02368DFF3100CD96811EB6B1AA9AF8AEAC1C5EE1A254B`.
The post-change control timedemo
`out\dos-timedemo-20260928-130729\timedemo-result.json` again completed 969
frames in 59.408233 seconds at 16.310870 FPS with checksum `1047377823`.
The final control smoke result in `out\dos-smoke\smoke-result.json` reports
DOSBox-X and Quake exit codes both `0`.

