# 486 ASM experiment handoff

This checkout is a DOS WinQuake/software-renderer preservation project.  The
purpose of the ASM work is experimental: compare small hand-written 486 paths
with the original C under the same DJGPP build and DOSBox-X workload, then
promote only changes that preserve the exact framebuffer and win the complete
timedemo.  This is a continuation note for the next agent; operational build
and run details remain in `BUILD-DOS.md`.

## Current state

### Current texture-span follow-up (2026-09-29)

The latest PROFILE486 control run is
`out\dos-timedemo-20260929-071039\timedemo-result.json`: 969 frames,
framebuffer checksum `1047377823`, with texture spans first at 27.92% self
time and alias models next at 13.29%. The instrumented duration is attribution
only.

The new opt-in `-TextureSpanStores stosw` path uses unrolled `STOSW` stores
for full 16-pixel segments; `word` remains the default. Candidate smoke and
full `bench486` correctness passed (`2378409472`). Three alternating pinned
timedemo pairs retained 969 frames and checksum `1047377823`; medians were
59.265502 seconds for `word` and 59.325327 seconds for `stosw` (0.10094%
slower). Keep `stosw` only for reproducible A/B work. Full profile, timing,
spread, and artifact details are in `BUILD-DOS.md` under “Latest PROFILE486
and texture-span STOSW experiment.” Alias-model rendering is the next hotspot.

### Current parity-gated closure (2026-09-28)

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

### Horizontal-flat mip-0 surface blocks (2026-09-29)

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

### Monster gib trail zero-XY experiment (2026-09-29)

`R_RocketTrail` creates `pt_grav` only for the `EF_GIB` and `EF_ZOMGIB` blood
trail variants. Those particles start with zero velocity on all axes and only
their vertical velocity changes. The opt-in
`-GibTrailHorizontalIntegration skipzero` path skips the two horizontal
zero-velocity position updates in `R_DrawParticles`; the default `control`
path retains the original C behavior. The selector is supported by the build,
timedemo, smoke, and `bench486` runners. PROFILE486 reports
`metrics.gib_trail_particles` so a replay can confirm it exercises this path.

The pinned `demo1` profile processed 8,162 gib trail particles out of 134,544
total particle updates over 969 frames. The three-run control median was
59.344081 seconds; `skipzero` measured 59.337036 seconds, a repeatable
0.0119% improvement. All six timedemo runs retained framebuffer checksum
`1047377823`. Candidate smoke passed and `bench486` reported correctness PASS
with checksum `2378409472`. Keep `control` as the default: the measured gain is
below the 0.05% promotion gate. Artifacts are in
`out\dos-timedemo-20260928-224352`,
`out\dos-timedemo-20260928-224550`,
`out\dos-timedemo-20260928-224937`,
`out\dos-bench-20260928-225518`, and `out\dos-smoke`.

The mip-0 eight-row extension also remains opt-in. Five fresh alternating
runs, with both executables rebuilt from the same source, measured 59.344242
seconds median for the four-row control and 59.338650 seconds for unroll8, a
0.0094% gain below the gate. All ten runs completed 969 frames with checksum
`1047377823`; smoke and full correctness passed. Keep
`SurfaceBlockMip0Rows=unroll4` as the release value.

The mip-0 sixteen-row extension also remains opt-in. Five fresh alternating
runs measured 59.344220 seconds median for the four-row control and 59.335845
seconds for unroll16, a 0.0141% gain below the gate. All ten runs completed
969 frames with checksum `1047377823`; smoke and full correctness passed. Keep
`SurfaceBlockMip0Rows=unroll4` as the release value.

### Pre-surface-block-loop control and PROFILE486 baseline (2026-09-28)

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

### Alias-span address-update experiment (2026-09-28)

The next alias-rasterizer experiment adds an opt-in
-AliasSpanAddressing control|branch selector.  branch defines
ASM486_ALIAS_SPAN_BRANCH_ADDRESS in D_PolysetAff8Start, replacing the
indexed two-entry advancetable lookup with direct base/extra address updates
selected by the T-carry mask.  The candidate tests that mask before the
S-carry-producing update, then uses a fixed ADC displacement; sample order,
depth tests, light/colormap lookup, destination writes, span tails, and the
control path remain unchanged.  control is still the production default.

Both variants used the aggressive DJGPP GCC 12.2.0 i486 profile
(-O3 -march=i486), 83 retained C sources, 21 assembly sources, the pinned
DOSBox-X 486 profile, CWSDPMI, and the legal Steam id1 data root.  The
isolated executable hashes are:

| artifact | control | branch candidate |
| --- | --- | --- |
| qbench.exe | F93123A52971DDD57C4B070DBC9E88C4DE2AD36B270C4203B0A141AE4749E749 | C2430CC7A4DB3D7983B5F35E8B5081925D5C44E0FC29FF777D45693CC64898A8 |
| quake.exe | C7989BEEBA18D22DCB1D1D467124F2B5E04A8D06DE6DF96BD083B8F21E6D5FD1 | 0CBE9F2B4F01EDF05BDDD80F7CD670A9F3C258589033009DB626EA2BFBAE0F8D |

The correctness results are
out\dos-bench-20260928-134700\bench-result.json for control and
out\dos-bench-20260928-133843\bench-result.json for the candidate.  Both
reported DOSBox-X exit 0, 486 benchmark correctness PASS, and end checksum
2378409472.  The candidate smoke evidence is
out\dos-smoke-aliasspanaddrbranch-result.json with clean DOSBox-X/Quake
exits; the final default-control smoke result is
out\dos-smoke\smoke-result.json.

The independent alternating release samples were:

| variant | samples (seconds) | median | median FPS | spread |
| --- | --- | ---: | ---: | ---: |
| control | 59.408173 / 59.408253 / 59.408238 | 59.408238 | 16.310869 | 0.000080 |
| branch | 60.056674 / 59.593444 / 59.593426 | 59.593444 | 16.260178 | 0.463248 |

Every run completed 969 frames with framebuffer checksum 1047377823.  The
branch median is 0.185206 seconds (0.311751%) slower than control, so it
fails the required 0.05% promotion threshold and remains opt-in only.  No
visual-quality, resolution, presentation, scene, or timing changes were made.
The final default-control closure timedemo is
out\dos-timedemo-20260928-140755\timedemo-result.json: 969 frames,
59.408222 seconds, and checksum 1047377823.

The current PROFILE486 attribution remains texture spans at 28.11%, alias
models at 13.38%, and world BSP at 11.49%; after rejecting this alias-span
address path, world BSP traversal was the next hotspot investigated.

### World-BSP frame-count cache experiment (2026-09-28)

The world BSP walk has an opt-in
-BspFrameCountImplementation control|local selector.  local snapshots the
immutable per-frame r_framecount once after node visibility/frustum culling
and reuses it for leaf surface marking and both node-surface visibility
loops.  The control path retains the original global reads and remains the
production default.  No traversal order, surface order, comparison, or
rendering operation changes.

The reproducible commands are:

~~~powershell
.\tools\build-dos.ps1 -Benchmark -Clean -NoBootstrap -BspFrameCountImplementation control
.\tools\build-dos.ps1 -Benchmark -Clean -NoBootstrap -BspFrameCountImplementation local
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation control -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 600
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation local -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 600
.\tools\smoke-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation local -DynamicLightImplementation asm -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1' -TimeoutSeconds 180
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -BspFrameCountImplementation control -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1'
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -BspFrameCountImplementation local -DataRoot 'C:\Program Files (x86)\Steam\steamapps\common\Quake\id1'
~~~

Both variants used DJGPP GCC 12.2.0, target i586-pc-msdosdjgpp,
-O3 -march=i486, 83 retained C sources, 21 assembly sources, the pinned
DOSBox-X 486 profile, CWSDPMI, and the same legal Steam id1 data root.  The
final executable hashes are:

| artifact | control | local candidate |
| --- | --- | --- |
| qbench.exe | D8CC026621C603512028138E546BEBF806F540CA74918AE344D16FF0DD843D46 | BBD6BC2468382872730AA8978552C4C1931EE12D1BAD11BBCA9996571F086FD6 |
| quake.exe | 866EBCE2072AA6F7E954A79A802E3199D6CAABCFC5C0E995246B226AF1FBBDEF | 2CB2B5F1DF06B3F28BB9490BE8FDFA2069CBBAB0713828AD747D3FCA0213D121 |

The correctness results are
out\dos-bench-20260928-163429\bench-result.json for control and
out\dos-bench-20260928-162612\bench-result.json for local.  Both reported
DOSBox-X exit 0, 486 benchmark correctness PASS, and end checksum 2378409472.
The candidate smoke evidence is out\dos-smoke-bspframecache-result.json with
DOSBox-X and Quake exit codes 0; the final control smoke evidence is
out\dos-smoke\smoke-result.json, also with both exit codes 0.

The independent alternating release samples were:

| variant | samples (seconds) | median | median FPS | spread |
| --- | --- | ---: | ---: | ---: |
| control | 59.408213 / 59.408180 / 59.408194 | 59.408194 | 16.310881 | 0.000033 |
| local | 59.435670 / 59.435661 / 59.435771 | 59.435670 | 16.303341 | 0.000110 |

Every run completed 969 frames with framebuffer checksum 1047377823.  The
local median is 0.027476 seconds slower, or 0.046250%, so it does not clear
the required 0.05% promotion threshold.  The candidate is rejected for
promotion but retained as an explicit opt-in experiment; control remains the
production default.  Release evidence is in
out\dos-timedemo-20260928-164250, out\dos-timedemo-20260928-164441,
out\dos-timedemo-20260928-164556, out\dos-timedemo-20260928-164708,
out\dos-timedemo-20260928-164832, and out\dos-timedemo-20260928-164945.
The final rebuilt control closure is
out\dos-timedemo-20260928-165256\timedemo-result.json: 969 frames,
59.408217 seconds, and checksum 1047377823.

The profile ranking remains texture spans at 28.11%, alias models at 13.38%,
world BSP at 11.49%, and surface cache at 10.03%; the surface-cache rebuild
path is the next hotspot to investigate.  No visual-quality, resolution,
presentation, scene, or timing changes were made.

### Texture-span address-update experiment (2026-09-28)

The full 16-pixel word-store texture loop has an opt-in
`-TextureSpanAddressing control|branch` selector.  `branch` replaces the
indexed two-entry `advancetable` lookup with direct base/extra address adds
selected by the T carry, while retaining the S carry and the original sample
and store sequence.  It is restricted to `TextureSpanStores=word`,
`TextureSpanLoadOrder=control`, and `TextureSpanRowPath=control`.
`control` remains the production default.

The candidate build was isolated under
`out\dos-memasm-spanaddrbranch-zneg4-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm`.
Its benchmark `qbench.exe` SHA-256 is
`8D44EA9AC5E3002B05E7E0C25B8697166AA8BF6D7DD4FE85A080A4173334694E`; the
normal smoke executable SHA-256 is
`B14F6732726AB59DF860D4AC97D81C9314FC1481705872B95E1310750BB96FA2`.
The selector and build metadata are recorded in the result JSON files.

The candidate correctness result
`out\dos-bench-20260928-124646\bench-result.json` reported
`486 benchmark correctness PASS` and end checksum `2378409472`.  The
candidate smoke result was also a clean DOSBox-X/Quake exit.  However, the
release timedemo result
`out\dos-timedemo-20260928-125539\timedemo-result.json` exposed a parity
failure: all three 969-frame runs produced framebuffer checksum `2110466403`
instead of the required `1047377823`.

```text
branch: 60.664292 / 60.664491 / 60.664483 seconds
median 60.664483 seconds, 15.973103 FPS
```

The candidate was `1.256377` seconds (`2.114824%`) slower than the fresh
control median and failed the release checksum gate, so it is rejected for
promotion.  It remains an explicit opt-in only to reproduce the rejection;
the default control path is unchanged.  The next pass should move to the
alias-model rasterizer hotspot, then world BSP if no exact-parity win appears.

### Current reproducibility note (2026-09-26)

ASM/setup: D_SetupFrame now lazily rebuilds viewspantable only when the active
view buffer or effective row stride changes. Full correctness and video tests
pass. Three raw demo1 runs measured 59.422468 / 59.422417 / 59.422374
seconds (median 16.306977 FPS), checksum 1047377823 on every run, versus the
16.297855 FPS clean baseline.

The benchmark worktree seeds srand(1) at the start of PROFILE486 timedemos and
uses -falign-jumps=16 in the aggressive DOS build. These changes make the
current profiling/timedemo workload deterministic enough for A/B comparison,
but they change the framebuffer reference from older handoff runs. The current
worktree authority is 969 frames with checksum 1047377823; older reports using
4154140932 remain historical results and must not be mixed into current A/B
comparisons.

The optional ASM surface-cache predicate was rechecked with guarded dispatch
and then rejected: C median 59.506742 seconds (16.283870 FPS) versus ASM median
59.512084 seconds (16.282407 FPS) across three raw runs. All runs completed
969 frames with checksum 1047377823, and both variants passed the full 486
benchmark correctness PASS harness. Keep the C surface-cache predicate as the
default; a focused helper win is insufficient when the complete timedemo loses.

The negative-gradient Z-span eight-pixel packing schedule was rechecked with
the current seeded workload. It is available only through the explicit
`-ZSpanNegativeUnroll unroll8` build/timedemo option; `control` remains the
production default. Three matched runs completed 969 frames with checksum
1047377823: control measured 59.408069 seconds median and `unroll8` measured
59.408076 seconds. The candidate is rejected as a marginal regression, but the
selector remains for reproducible A/B work. The accompanying PROFILE486 run
puts texture spans first at 28.11% of instrumented self time, making them the
next optimization target; the instrumented duration is attribution evidence,
not a release timing claim.

### Texture-span row-cross experiment (2026-09-28)

`D_DrawSpans16` now has an opt-in `-TextureSpanRowPath norowcross` selector,
implemented by `ASM486_SPAN16_NO_ROW_CROSS`; `control` remains the default.
For full 16-pixel segments, the candidate uses an S-only texture-address loop
only when the clamped T endpoint is non-negative relative to the start and both
endpoints are in the same texture row.  Negative gradients and row crossings
use the unchanged control DDA.  The 8-bit span path is outside this slice.

The matched aggressive i486 builds were made with:

```powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanRowPath control
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanRowPath norowcross
```

Both `bench-dos.ps1 -SkipBuild` runs passed `486 benchmark correctness PASS`
with end checksum `2378409472`.  Three alternating release timedemo pairs were
run with `tools\dosbox-x-486-high.conf`, CWSDPMI, the seeded `demo1` workload,
and the same `id1` data.  Every run completed 969 frames with framebuffer
checksum `1047377823`:

```text
control:    59.408221 / 59.408218 / 59.408243 s, median 59.408221 s, 16.310874 FPS
norowcross: 59.753011 / 59.753108 / 60.217335 s, median 59.753108 s, 16.216730 FPS
```

`norowcross` is `0.344887` seconds (`0.580537%`) slower than control.  The
median delta is above the `0.05%` escalation threshold, so no five-sample repeat
was required.  The candidate is rejected for promotion and retained as an
explicit opt-in experiment; `control` stays the release default.  Build,
benchmark, and timedemo JSON metadata record `textureSpanRowPath`, and the
candidate output is isolated under the ignored `...-spannorow` directory.

PROFILE486 evidence is in `out\dos-timedemo-20260928-070210` (control) and
`out\dos-timedemo-20260928-070331` (candidate).  The new profile counters are
`row_eligible=0,row_fast=0` for control and
`row_eligible=209338,row_fast=209338` for the candidate.  This proves the
candidate path was exercised, but the instrumented timing remains attribution
evidence rather than a release performance claim.

### Texture-span load-order experiment (2026-09-28)

The full 16-pixel texture-span word-store loop now has an opt-in
`-TextureSpanLoadOrder control|loadfirst` selector. `loadfirst` starts each
current texel load before the independent fixed-point S/T accumulator updates;
the carry-producing updates, sample order, and packed destination stores are
unchanged. It requires `-TextureSpanStores word`; `control` remains the
production default.

The candidate passed the existing correctness harness with end checksum
`2378409472`. Initial three-run timedemos under the pinned DOSBox-X 486
profile completed 969 frames with framebuffer checksum `1047377823` on every
run:

```text
control:    59.408224 / 59.408166 / 59.408042 s, median 59.408166 s
loadfirst:  59.408243 / 59.408113 / 59.408102 s, median 59.408113 s
```

Three additional alternating control/candidate pairs were:

```text
control:    59.408221 / 59.408177 / 59.408211 s, median 59.408211 s
loadfirst:  59.408215 / 59.408193 / 59.408237 s, median 59.408215 s
```

The alternating median difference is `0.000004` seconds, inside the observed
run spread. This is a noise-level result, so `loadfirst` remains an explicit
opt-in experiment and `control` remains the release default.

The matched benchmark executables were built with the pinned
`i586-pc-msdosdjgpp-gcc 12.2.0` aggressive profile (`-O3 -march=i486`), 83 C
sources, and 21 assembly sources. The control `qbench.exe` SHA-256 is
`8D2623E045ED5DB4133D47B35B69335F8995422A815A8347158F27ACE123958F`; the
`loadfirst` candidate is
`9A5DFCDDFD35235C9BA72FDE1CEDC8429E70B59D5FB1E25B2CA0DE0C883C6D05`.
The candidate profile executable SHA-256 is
`EFBF1ECB4684C2D97AAFA89FA06B1AF8E7F65F0D4ACC415467FE0EDF00602428`.
The instrumented candidate run (`out\dos-timedemo-20260928-093436`) took
67.271309 seconds for 969 frames and ranked texture spans 28.11%, alias models
13.38%, world BSP 11.49%, surface cache 10.03%, Z spans 9.37%, and edge
scanning 9.00% by self-time. Input, game, audio, and present accounted for
0.03%, 0.88%, 0.03%, and 0.64%, respectively. These timings are profiling
attribution, not a release claim.

Final closure validation after the control rebuild passed as well:
`out\dos-bench-20260928-094143\bench-result.json` records DOSBox-X exit code
`0`, `486 benchmark correctness PASS`, and end checksum `2378409472`; the
candidate `out\dos-smoke\smoke-result.json` records DOSBox-X and Quake exit
codes both `0`.

### Alias-model prepare source-cursor experiment (2026-09-28)

The final PROFILE486 control ranked texture spans at `28.11%` self time, alias
models at `13.38%`, world BSP at `11.49%`, surface cache at `10.03%`, Z spans
at `9.37%`, and edge-scan self at `9.00%`; alias work was 5,470 models and
417,090 vertices. The new build-time selector is
`-AliasPrepareImplementation control|local`, with `control` unchanged as the
production default. The `local` candidate only carries `r_apverts` through
`R_AliasPreparePoints` in a local pointer, then publishes the same final
post-incremented cursor. Clip-bound loads, helper/comparison order, fixed-point
and x87 behavior, flags, simulation, audio, and framebuffer writes remain
unchanged. The previously rejected `aliasvrect`-local hoist was not retried.

Both final builds used DJGPP GCC 12.2.0, target `i586-pc-msdosdjgpp`,
`-O3 -march=i486`, 83 C sources, and 21 assembly sources. The control and
candidate `qbench.exe` hashes are respectively
`18C5A92B2F6CB0DF6BB10BADDDA1491BB0BCFC11738BB80A80B56A939FBCCA33` and
`876B1AD6C22BFEC9B1CC6048F5E97A01A8F34B45D64E55522D30BE81D6A1580A`; the
instrumented `qprof.exe` hashes are
`CFEA0ED0F24DC7F85F99CD57C6B8BDCA27B36460317699D453564F61BEEB151B` and
`3729E13DECDB7F203E0F939E1ABE5193882976AEB3A5C7792F0D3A255CBEBEDE`.
The build manifests record the selector and keep the candidate in the
`...-aliaslocal...` output family. Their `sourceCommit` is
`de1d41d12d3e54286291c59e35822e27182e2228`; the selector and source-cursor
change are the intentional working-tree patch under test.

The benchmark, timedemo, and smoke wrapper auto-build paths also use named
parameter forwarding, so a missing isolated executable cannot misbind a
selector or benchmark switch. Explicit build followed by `-SkipBuild` remains
the preferred measured workflow.

The control correctness result is
`out\dos-bench-20260928-111615\bench-result.json`; the candidate result is
`out\dos-bench-20260928-104656\bench-result.json`. Both passed
`486 benchmark correctness PASS` with end checksum `2378409472` and DOSBox-X
exit code `0`. The candidate smoke result reports DOSBox-X and Quake exit code
`0`.

The fresh alternating release set was:

```text
control: 59.408180 / 59.408212 / 59.408172 s, median 59.408180 s, 16.310885 FPS
local:   59.404173 / 59.404192 / 59.404109 s, median 59.404173 s, 16.311986 FPS
```

Every run completed 969 frames with framebuffer checksum `1047377823`. The
candidate median is `0.004007` seconds faster (`0.006745%`), with maximum
within-variant spread `0.000083` seconds. It still fails the required `0.05%`
promotion threshold, so it is rejected and retained only as an opt-in
experiment; `control` remains the default. Release results are in
`out\dos-timedemo-20260928-110615`, `...-110752`, `...-110904`,
`...-111017`, `...-111130`, and `...-111242`. The control and candidate
PROFILE486 runs are `out\dos-timedemo-20260928-111433` and
`out\dos-timedemo-20260928-110347`; their instrumented timings are attribution
evidence only.

### Texture-span tail-store experiment (2026-09-28)

The variable-length final segment of `D_DrawSpans16` has an opt-in
`-TextureSpanTailStores control|word` selector.  The `word` candidate defines
`ASM486_SPAN16_TAIL_WORD_STORES`, packs adjacent pre-final samples with `movw`,
and preserves the existing fixed-point DDA order and final-sample behavior.
Full 16-pixel segments and `D_DrawSpans8` are unchanged; `control` remains the
default.

Both matched aggressive i486 builds passed `486 benchmark correctness PASS` with
end checksum `2378409472`.  Three alternating release timedemo pairs used the
pinned DOSBox-X 486 profile, CWSDPMI, seeded `demo1`, and the same `id1` data.
Every run completed 969 frames with framebuffer checksum `1047377823`:

```text
control: 59.408215 / 59.868491 / 59.408242 s, median 59.408242 s, 16.310868 FPS
word:    60.135289 / 60.135318 / 60.135324 s, median 60.135318 s, 16.113659 FPS
```

`word` is `0.727076` seconds (`1.223864%`) slower than control.  The median
delta is above the `0.05%` escalation threshold, so no five-sample repeat was
required.  The candidate is rejected for promotion but retained as an explicit
opt-in experiment; `control` stays the release default.  Build, benchmark, and
timedemo JSON metadata record `textureSpanTailStores`, and the candidate output
is isolated under the ignored `...-spantailword` directory.

The next sequential pass also rejected two leads. The proposed surf8.s
lightright-store removal was invalid: the stores at the end of the mip0, mip1,
and mip2 blocks feed the next loop iteration through C(lightright), so they are
live lighting state and must remain. A scoped zero-vector early-out before
VectorNormalize in DropPunchAngle passed the correctness harness and retained
969 frames/checksum 1047377823, but its three-run median was 16.283890 FPS
versus the 16.283870 FPS baseline, an insignificant 0.000020 FPS difference.
It was reverted as measurement noise. Do not promote either experiment.

The nested repository is the Git boundary: `D:\Project\486quake\quake`.
The current source uses the `aggressive` profile (`-O3 -march=i486`) and the
repository-owned `tools\dosbox-x-486-high.conf` profile (`cputype=486`, fixed
33445 cycles, DOSBox-X 2026.08.31, 16 MB).  The current default selections are:

- ASM: alias projection, alias bounding-box projection, clipped alias
  transform/lighting, texture-animation selection, and lightmap normalization.
- `stosb`: turbulent-span stores.
- `word`: 16-pixel texture-span stores are the production default.  The full
  segment path packs adjacent destination pixels with `movw` while preserving
  the original sampling/DDA order.  Three matched runs measured
  `59.408238 / 59.408105 / 59.408106` seconds (median `59.408106`), with
  checksum `1047377823` on every run.  `byte` remains the original unrolled
  control path; dword packing and the stosb loop remain explicit alternatives.
  The earlier `59.497xxx` / `4154140932` measurements are historical and are
  not comparable with the current seeded workload.
- C: memory helpers, texture-axis cache predicate, surface-cache predicate,
  mip-level selection, BSP plane-dot, and BSP frustum clipping.
- ASM: generic lightmap style accumulation is now the production default via
  LightMapStylesImplementation=asm. The C reference remains selectable.
  The focused maps-1..4 cases all matched, and matched demo1 runs measured
  C at 59.512120 / 59.512084 / 59.512013 seconds versus ASM at
  59.503904 / 59.503792 / 59.503771 seconds, with checksum 1047377823 on
  every run. The full correctness harness passed for both variants.
- ASM: fused no-dynamic-light 2/3/4-style lightmap accumulation is also now
  the production default via FusedLightMapImplementation=asm. Focused boundary
  cases and full correctness passed. Matched demo1 runs measured C at
  59.504490 / 59.504450 / 59.504481 seconds versus ASM at
  59.502617 / 59.502563 / 59.502535 seconds; all runs kept checksum
  1047377823.
- ASM: the first alias transform composition now uses the specialized diagonal
  matrix path by default via AliasMatrixCompositionImplementation=special.
  AngleVectors and the second composition remain unchanged. Three matched
  demo1 runs measured C at 59.502611 / 59.502548 / 59.502529 seconds versus
  special at 59.455982 / 59.455677 / 59.455756 seconds; every run kept
  checksum 1047377823 and the full correctness harness passed.
- ASM: the existing dynamic-light sample loop is now the production default via
  DynamicLightImplementation=asm. Matched demo1 runs measured C at
  59.422461 / 59.422365 / 59.422373 seconds versus ASM at
  59.410915 / 59.410949 / 59.410930 seconds; all runs kept checksum
  1047377823 and the full ASM correctness harness passed.
- VGA full-frame linear-copy fast path was tested and rejected. Direct VGA
  parity tests passed, and forced -stdvid timedemos kept checksum 1047377823,
  but the guarded candidate measured 16.302751 FPS versus the matched control
  at 16.303103 FPS. The candidate was reverted; retain the expanded VGA
  coverage, but do not promote the copy shortcut.
- Inlined 486 setup: power-of-two surface wrap in `R_DrawSurface`, release
  builds skip `D_CheckCacheGuard`, and `R_AliasSetViewMatrix` fills the alias
  view matrix once per frame.
- `Mod_LoadTexinfo` copies `vecs[2][4]` with nested `j<2`/`k<4` loops so
  `-O3` `-Waggressive-loop-optimizations` cannot walk off the array.
- Bmodel span drawing: consecutive surfaces from the same brush entity keep
  the rotated axes; later revisits reuse `R_RotateBmodelCached` instead of
  rebuilding the matrix with `sin`/`cos`.  `R_RotateBmodel` remains the
  reference.
- Face Z gradients: `R_SetSurfaceZGradients` reuses one plane's finished
  `d_zistep` values while the drawing `currententity` is unchanged this
  frame.  The entity pointer replaces three `modelorg` float comparisons;
  the miss path remains the original `TransformVector` / `1/z` arithmetic.
- Z spans: `D_DrawZSpans` ASM uses `zspantable` row bases instead of
  IMUL `d_zrowbytes`.  The span list cursor lives in `%ebp` so the pack
  loop can scratch `%esi` without push/pop per span.  The first packed pair
  in both positive- and negative-gradient loops uses 486 `shldl`/`rorl`
  packing instead of a masked `%esi` high-word merge; the C multiply path
  remains the reference.
- Edge scan: `R_GenerateSpans` / `Lgs_leading` reuses the live
  `surfaces` pointer in `%eax` instead of reloading it before the leading
  surface add.  `Lnewtop_fpop2` no longer loads a dead `st_key` into
  `%eax` before `Lnewtop` overwrites it.  `R_EmitEdge` omits the
  discarded next-edge pretouch loads on both leading and trailing sides,
  loads `edge_p` and `r_pedge` only after the horizontal early-out
  (`leal` for `edge_p+et_size` so CF from the ceil compare feeds the side
  test; no preload into `%esi`), and drops an unused `r_pedge` load on the
  fully-clipped both-points-out path (cacheoffset only).
  `LPop5AndDone` loads `r_framecount` only when `cacheoffset != 0x7FFFFFFF`
  (matches C; partially-clipped exits skip the dead dword).
  `TrailingEdge`
  uses memory `decl` for `--surf->spanstate` (ZF test; inverted path
  needs no extra store), emit / `LNoEmit2` unlink with the already-loaded
  `st_next` in `%ecx` instead of reloading into `%edx`, skips the
  `r_bmodelactive` update when `insubmodel` is 0, and uses `decl`/`incl`
  memory forms for bmodel enter/leave (matching C's `++`/`--`).
  Emit compares `iu` to `st_last_u` via memory `cmpl` (load `last_u` into
  `%edx` only when emitting).
  Leading
  non-inverted paths store `movl $1` into `spanstate` (was 0) instead of
  `incl`+store; inverted `Lxl_done` still uses `incl`.
  Leading first key test uses memory `cmpl st_key(%esi),%eax` (drops
  preload into `%ecx`; dead on `Lnewtop` / `Lzcheck_for_newtop`).
  Sort walks `Lsortloopnb` / `Lsortloop` use the same memory `cmpl`
  (drop per-probe key preload into `%ecx`).
  `R_StepActiveU` `LPushBack` checks `edge_aftertail` before loading
  `et_prev`/`et_next` (matches C; every scanline's finish early-out
  skips two dead dword loads).
  `R_StepActiveU` step probes 1–3 defer `et_next` past the order
  early-out; `LPushBack` / `LPushBack2` load continuation `et_next` only
  after aftertail (matches C; drops the duplicate unlink load).
  Probe 4 keeps its preload for `jnl LNextEdge`.
  `R_RemoveEdges` finishes both unlink stores before testing
  `nextremove` (matches C; drops `%ebx` push/pop and the odd-tail
  `Lre_done` second-store path).
  `R_InsertNewEdges` defers `et_next` past the `et_u` early-out on the
  first three search probes (dead on `LAddedge` / `LAddedge2`); the
  fourth probe keeps the original `jg` fallthrough so long walks do
  not pay an extra `jmp`.  Search probes use memory `cmpl et_u(...)`
  (drop preload into `%ebx`).
  `R_StepActiveU` `LPushBackLoop` defers `et_prev` past the first
  `et_u` early-out (dead on `LPushBackFound`); second probe unchanged.
  Pushback search uses memory `cmpl et_u(...)` (drop preload into `%ebx`).
  Step probes use memory `addl et_u_step(...)` (drop preload into `%ebx`).
  Leading `Lnewtop` compares `iu` to `st_last_u` via memory `cmpl` (load
  `last_u` into `%edx` only when emitting), matching TrailingEdge.
  `R_EmitEdge` compares `ceilv0` to `r_ceilv1` via memory `cmpl` and loads
  `r_ceilv1` into `%ecx` only when the edge is non-horizontal (CF still
  feeds the side `jc` after `leal`).
  `D_PolysetRecursiveTriangle` midpoint s/t/zi uses memory `addl` of
  `lp2` fields (drop `%edx` preloads); x/y still keep `lp1` live for
  nodraw compares and `new[0]`/`new[1]` into LDraw.
  `R_EmitEdge` u-clamp uses memory `cmpl` against vrect left/right
  (load the clamp bound into `%edx` only on the taken clamp paths).
  EmitEdge `LSide1`/`LSide0` use memory `subl C(surfaces)` for the
  `surface_p - surfaces` index instead of preloading `surfaces` into
  `%esi`; `%esi` is then set with `movl %edx,%esi` (0) or
  `movl $1,%esi` for the sort side.
- Texture spans: `D_DrawSpans16` / `D_DrawSpans8` ASM load dest rows from
  `viewspantable` (`d_viewbuffer + d_scantable[v]`, filled in
  `D_SetupFrame`).  Alias polyset, sprites, particles, and live
  `Turbulent8` dest rows use the same table.  Live
  `D_RasterizeAliasPolySmooth` dest and Z rows also use
  `viewspantable` / `zspantable`; the multiply form stays in a comment.
  C `D_DrawSpans8` still
  multiplies `screenwidth`.  `D_PolysetDrawFinalVerts` hoists the
  viewmodel clip edges into registers/locals; C matches the live ASM.
  `D_PolysetSetUpForLineScan` uses a 64x64 `adivtab` for `tm,tn` in
  `[-31,32]` (was 32x32 / `[-15,16]`); longer edges still use IDIV /
  `FloorDivMod`.  Live ASM `D_PolysetDrawSpans8` builds `advancetable` /
  `tstep` once per call (same pattern as `lzistepx`).
  Aff8 pixel leaves use `movzbl` for the texel/`(light<<8)|texel`
  colormap index instead of `xorl`+`movb`.
  Aff8 `LExactlyOneLong` loads `ptex` only after the Z test passes.
  Aff8 multi `Lp8` skips the post-group s/t/z/ptex step when the last
  group finishes (`decw`/`jz` before the dead advance).
  `D_PolysetDrawFinalVerts` uses `movzbl` for the skin texel (drops
  `andl $0x00FF` before the light-shifted colormap add) and forms
  `(light<<8)|texel` via `movb` of `v[4]`'s high byte into `%dh` (Aff8-style;
  drops dword light load/`andl $0xFF00`/`addl`).
  `D_DrawSubdiv` sets `d_pcolormap` only after the backface cull (matches
  C; skips the store on culled triangles).
  `D_RasterizeAliasPolySmooth` reuses left-edge s/t base products for the
  extra-step path (`d_countextrastep = ubasestep + 1`).
  Live ASM `D_PolysetScanLeftEdge` keeps the package cursor in `%esi`,
  live `d_pdest`/`d_pz` in `%edi`/`%ebp`, and spills light/zi/aspancount
  on the stack (aspancount written back once on exit).  The discarded
  next-package cache pretouch `movb` is omitted; the first store after
  advancing `%esi` still touches the line.  After packaging the last
  row, the Bresenham step is skipped (`decl`/`jz` before the step;
  matches Aff8 last-group).  `D_PolysetRecursiveTriangle`
  pixel leaf reuses live `new[1]`/`new[0]` in `%ecx`/`%ebp` from the Z
  setup (`movzbl` colormap index; no stack reloads).  Leading-edge nodraw
  loads `lp2[0]` only on the equal-`y` path (into `%eax` so live
  `new[0]`/`new[1]` in `%edx`/`%ebp` survive into `LDraw`, skipping the
  stack reloads at draw entry).  Near-edge `|dy|` split checks
  defer the next-edge `lp3[0]`/`lp1[0]` prefetches until after the
  `ja LSplit`/`LSplit2` early-outs.  Same-edge `|dx|` early-outs skip the
  y loads until `|dy|` is actually tested (`LSplit3` saves `lp1` locally).
- Sprite and particle Z: ASM uses `zspantable` instead of IMUL
  `d_zrowbytes`.  The C multiply paths remain the reference.
- `R_DrawSurface` wraps the per-column source offset with AND when the
  mip width is a power of two; the compare/branch loop remains the
  non-POT reference.
- Surface cache: `SURFCACHE_SIZE_AT_320X200` is `1800*1024` (3x the
  original 600 KB).  1900 KB and larger failed checksum `2955717646`.
  `D_CacheSurface` skips `R_TextureAnimation` for static textures and
  fills `r_drawsurf` only on a miss; unused extra light styles are skipped
  when `styles[1] == 255`.  `R_TextureAnimation` remains the
  animated/alternate reference.  `R_BuildLightMap` folds ambient into the first
  lightmap style so the common one-style case writes `blocklights` once.
  When there are no dynamic lights, invert/clamp is fused into that write
  for one to four styles; dlights still accumulate then call
  `R_BuildLightMapNormalize_*`.  `R_AddDynamicLights` keeps the per-texel
  distance in an integer and walks `blocklights` by row;
  `R_AddDynamicLights_C` remains the float-`dist` reference.
  Rebuilds no longer compute unused `surfscale` or store
  `cache->mipscale`; the header field remains for layout.
  `R_MarkLights` skips faces whose plane distance already fails the
  same `radius - fabs(planedist) < minlight` reject used by
  `R_AddDynamicLights`, and also skips faces whose projected impact
  is farther than `fmin` from the lightmap rect under the same integer
  idist metric, so impossible dlight marks no longer force
  surface-cache rebuilds.  `cache->dlight` is set only when
  `R_AddDynamicLights` actually increments a sample (`r_dlight_contributed`),
  so zero-contribution marked rebuilds do not sticky-miss the next frame.
  `D_CacheSurface` also probes `R_DlightContributes` on marked frames with a
  clean cache hit so phantom marks skip the rebuild on the marked frame itself.

Every ASM candidate retains its C implementation.  `build-dos.ps1`,
`bench-dos.ps1`, and `timedemo-dos.ps1` expose independent `c|asm` selectors
and write separate ignored output directories when needed.  `out\` contains
generated executables, staged data, logs, JSON reports, and object files; it is
not source and must not be committed.

## Completed experiments and decisions

This ledger contains historical measurements from multiple benchmark
generations.  Entries using framebuffer checksum `4154140932` predate the
current `srand(1)` seeded workload; the current release authority is 969
frames with checksum `1047377823`, as recorded in the fresh control section
above.  Do not compare timings across those checksum generations.

The entries below preserve their original alternating C/ASM evidence and
checksums; newer exact-parity results are recorded in the current sections
above.  The percentages below are DOSBox-X evidence, not a claim about all
physical 486 variants.

| Experiment | Focused result | Timedemo result | Decision |
| --- | --- | --- | --- |
| Texture-span setup (`d_draw16.s`) | Narrow address-arithmetic change | About 0.10% faster | Kept |
| Turbulent stores | Existing ASM 20.6--28.8% faster than C; `stosb` tied it in isolation | `stosb` 0.086207% faster than existing ASM | `stosb` default |
| Alias projection (`R_AliasProjectFinalVert`) | 7.316--7.317% faster | 0.017696% faster | ASM default |
| Texture animation (`R_TextureAnimationFrame`) | 1.052--31.999% faster | 0.009406% faster | ASM default |
| Lightmap normalization (`R_BuildLightMap`) | 9.447--9.969% faster | 0.0275% faster | ASM default |
| Alias bbox projection (`R_AliasCheckBBox`) | 16.667--20.120% faster | 0.0264% faster | ASM default |
| Clipped alias transform (`R_AliasTransformFinalVert`) | 20.000--25.218% faster | 0.150883% faster | ASM default |
| Memory helpers (`Q_memset`/`Q_memcpy`) | About 4.6--64.4% faster by case | ~0.019% faster end-to-end on current 486 timedemo; checksum pass | **ASM default**; C reference |
| Texture-axis predicate (`D_GetTextureAxes`) | 0.000% to -0.002% | Not promoted | C default |
| Surface-cache predicate (`D_CacheSurface`) | 3.846--5.000% faster | 0.030% slower | C default |
| Mip selector (`D_MipLevelForScale`) | Mixed: -8.697% to +7.143% | 0.0092% slower | C default |
| BSP plane dot (`R_RecursiveWorldNode`) | Mixed: -13.334% to +21.052% | 0.0367% slower | C default |
| BSP clipping (`R_RecursiveWorldNode`) | Mixed: -4.651% to +55.931% | 0.2749% slower | C default |
| Span16 dword stores (`d_draw16.s`) | Checksum pass | Median 68.958760 s vs 68.958817 s (noise) | `byte` default; `dword` opt-in |
| Span16 dword stores recheck (current source, 486 profile) | Three no-FPS-stat runs: 62.568941 / 62.568978 / 62.568999 s; checksum pass | Matching byte runs: 62.569014 / 62.568957 / 62.568953 s; medians differ by ~1 microsecond | `byte` remains default |
| Aff8 Z-store scheduling probe (`d_polysa.s`) | Moved Z store ahead of skin load in all eight pixels | 62.568983 / 62.569006 / 62.569015 s; ~27 microseconds slower than matched byte baseline; checksum pass | Reverted |
| Span16 loop+stosb (`d_draw16.s`) | Checksum pass | 70.980641 s / 13.651610 FPS, ~2.8% slower | `byte` default; `loop` opt-in |
| Surface block `movw` (`block8.h`) | Checksum pass | Noise vs byte stores | Reverted |
| Surface wrap + cache guard + alias view matrix | Inlined, no new helper | 68.946370 s / 14.054401 FPS, 12.4 ms faster | Kept |
| Aggressive `-O3` vs `-O2` | Checksum pass; `+quit` smoke pass | 68.421397 s / 14.162237 FPS | **Default**; `-O2` is `-OptimizationProfile baseline` |
| Bmodel span rotation cache (`d_edge.c` / `R_RotateBmodelCached`) | Id per-polygon `sin`/`cos` FIXME | 68.379696 s / 14.170874 FPS, 41.7 ms faster | Kept |
| Fused first-style lightmap (`R_BuildLightMap`) | Ambient+style0 in one write pass | 68.309838 s / 14.185365 FPS, 69.9 ms faster | Kept |
| Fused one-style normalize (`R_BuildLightMap`) | Invert/clamp in the first write when there are no extra styles or dlights | 68.265779 s / 14.194521 FPS, 44.1 ms faster | Kept |
| One-style lightmap inverse-base hoist (`R_BuildLightMap`) | Hoist `255*256 - ambient` out of the common no-dlight texel loop | 62.052978 s / 15.615689 FPS median vs 62.057653 s / 15.614513 FPS baseline; 0.0075% faster, checksum pass | Kept |
| Dynamic-light S-axis accumulator (`R_AddDynamicLights`, `R_DlightContributes`) | Replace repeated `local[0] - s*16` calculation with an integer scanline accumulator; preserve sample order | 62.018356 s / 15.624406 FPS median; 34.6 ms faster than the prior default, checksum pass | Kept |
| Z-gradient cache key (`R_SetSurfaceZGradients`) | Use the stable drawing entity pointer instead of three `modelorg` float comparisons | 61.989240 s / 15.631745 FPS median across five runs; checksum pass | Kept |
| BSP visibility predicate order (`R_RecursiveWorldNode`) | Check `visframe` before the surface backface flag in both node surface loops | 61.976925 s / 15.634851 FPS median across five runs; 12.3 ms faster, checksum pass | Kept |
| Zero-step Z-span stores (`D_DrawZSpans`) | When fixed-point `izistep` is zero, reuse the initial-Z result with `rep stosw` instead of per-pixel gradient updates | 61.559877 s / 15.740772 FPS median across five runs; checksum pass | Kept |
| BSP node visibility predicate order (`R_RecursiveWorldNode`) | Reject stale node `visframe` before checking `CONTENTS_SOLID` | 61.556783 s / 15.741564 FPS median across five runs; 3.1 ms faster, checksum pass | Kept |
| Integer subdivided alias cull determinant (`D_PolysetDraw`) | Replace the six-load x87 determinant with the matching 32-bit integer expression used by the non-subdivided path | 61.496717 s / 15.756939 FPS median across three runs; 60.1 ms faster, checksum pass | Kept |
| Integer determinant base restore (`D_PolysetDraw`) | Restore `%edi` from stable `r_affinetridesc.pfinalverts` instead of stack push/pop around the scratch determinant | 61.487373 s / 15.759333 FPS median across five runs; 9.3 ms faster, checksum pass | Kept |
| Z-span first-pair packing (`D_DrawZSpans`) | Pack the first aligned depth pair with 486 `shldl`/`rorl` in both gradient signs; fixed-point stepping and later pair schedule unchanged | 60.901914 / 60.901634 / 60.901646 s; median 60.901646 s / 15.910900 FPS; framebuffer checksum `4154140932` on every run | Kept |
| Fused extra-style normalize (`R_BuildLightMap`) | Same one-pass invert/clamp for 2--4 styles when there are no dlights | 68.265121 s / 14.194657 FPS, 0.66 ms faster | Kept |
| Integer dlight inner loop (`R_AddDynamicLights`) | Integer distance + row pointer; `R_AddDynamicLights_C` kept | 68.209972 s / 14.206133 FPS, 55.1 ms faster | Kept |
| Face Z-gradient cache (`R_SetSurfaceZGradients`) | Reuse one plane's `d_zistep` while `modelorg` is stable; original math on miss | 68.198777 s / 14.208466 FPS, 11.2 ms faster | Kept |
| POT column wrap (`R_DrawSurface`) | AND wrap on power-of-two mip widths; compare/branch remains the non-POT path | 68.197221 s / 14.208790 FPS, 1.6 ms faster | Kept |
| Alias `AngleVectors` cache (`R_AliasSetUpTransform`) | 16-slot per-frame basis reuse; `AngleVectors` miss path | 68.212837 s / 14.205537 FPS, 15.6 ms slower | Reverted |
| Direct mip0 drawer (`R_DrawSurface`) | Direct `R_DrawSurfaceBlock8_mip0` in the POT column loop | 68.198298 s / 14.208566 FPS, 1.1 ms slower | Reverted |
| Z-span row table (`D_DrawZSpans`) | Use existing `zspantable` instead of IMUL `d_zrowbytes`; C multiply kept | 68.049361 s / 14.239663 FPS, 147.9 ms faster | Kept |
| Texture-span row table (`D_DrawSpans16`) | `viewspantable` dest rows instead of `d_scantable` plus `d_viewbuffer`; C multiply kept | 67.999624 s / 14.250078 FPS, 49.7 ms faster | Kept |
| Extra `viewspantable` dest sites | Same table in polyset, sprites, and particles | 67.990997 s / 14.251887 FPS, 8.6 ms faster | Kept |
| Sprite/particle Z row table | `zspantable` instead of IMUL `d_zrowbytes` in `d_spr8.s` / `d_parta.s` | 67.986326 s / 14.252866 FPS, 4.7 ms faster | Kept |
| Remainder t-zero cachewidth skip (`D_DrawSpans16`) | Skip remainder IMUL when integer t-step is 0 | 68.007120 s / 14.248508 FPS, 20.8 ms slower | Reverted |
| Texture-source row table (`cachespantable`) | Per-surface `cacheblock+t*cachewidth` table for span starts | 68.333304 s / 14.180494 FPS, 347 ms slower | Reverted |
| 2x surface cache (`SURFCACHE_SIZE_AT_320X200`) | 1200 KB instead of 600 KB | 67.415956 s / 14.373452 FPS, 570.4 ms faster | Ladder; 3x kept |
| 3x surface cache (`SURFCACHE_SIZE_AT_320X200`) | 1800 KB instead of 600 KB | 67.249168 s / 14.409100 FPS, 166.8 ms faster than 2x | Kept |
| Turbulent dest rows (`Turbulent8`) | `viewspantable[v] + u` instead of `screenwidth * v` | 67.247873 s / 14.409378 FPS, 1.3 ms faster | Kept |
| Static surface-cache hit path (`D_CacheSurface`) | Skip `R_TextureAnimation` and `r_drawsurf` stores on static hits | 67.229543 s / 14.413306 FPS, 18.3 ms faster | Kept |
| FinalVerts clip hoist (`D_PolysetDrawFinalVerts`) | Hoist `vrectright`/`vrectbottom` out of the vertex loop | 67.218606 s / 14.415652 FPS, 10.9 ms faster | Kept |
| Unused extra-style skip (`D_CacheSurface`) | Skip lightadj[1-3] compares when `styles[1]==255` | 67.200437 s / 14.419549 FPS, 18.2 ms faster | Kept |
| Alias raster dest/Z tables (`D_RasterizeAliasPolySmooth`) | `viewspantable`/`zspantable` instead of `ystart` IMUL | 67.185736 s / 14.422704 FPS, 14.7 ms faster | Kept |
| Face edge setup (`R_RenderFace`) | Hoist `surfedges + firstedge`; unroll 4 clip-plane links | 67.097222 s / 14.441731 FPS, 88.5 ms faster | Kept |
| Bmodel clip unroll (`R_RenderBmodelFace`) | Same 4 clip-plane links as world faces | 67.097295 s / 14.441715 FPS, 0.07 ms, overlapping ranges | Reverted |
| Bmodel surfedges hoist (`R_DrawSolidClippedSubmodelPolygons`) | `pmodel->surfedges + firstedge` like world faces | 67.096341 s / 14.441920 FPS, 0.88 ms faster | Kept |
| Surface draw 8-bit setup (`R_DrawSurface`) | Skip `r_pixbytes` 16-bit path; reuse `r_stepback` for `r_sourcemax` | 67.093880 s / 14.442450 FPS, 2.46 ms faster | Kept |
| Mipscale step tables (`D_CalcGradients`) | Precompute `xscaleinv`/`yscaleinv`/`0x10000` × mip once per frame | 67.091882 s / 14.442880 FPS, 2.0 ms faster | Kept |
| Unused surfscale FDIV (`D_CacheSurface`) | Skip `1.0/(1<<mip)` and unread `cache->mipscale` store | 67.085585 s / 14.444235 FPS, 6.3 ms faster | Kept |
| Skip live `blocksize` (`R_DrawSurface`) | Stop storing 16-bit block globals; dest used local step only | checksum `2281919689` | Reverted |
| `R_DrawSurface` surfmip hoist | Local `mip` for rebuild setup shifts | 67.085593 s / 14.444234 FPS, noise | Reverted |
| Mip-scaled modelorg (`D_CalcGradients`) | Precompute `transformed_modelorg × mip` on world/bmodel switch | 67.096034 s / 14.441986 FPS, 4.2 ms slower | Reverted |
| DrawSurfaces Restore/Set CALL skip | Skip no-op `D_RestoreWorldDrawingState` / same-entity `D_SetBmodelDrawingState` | 67.093276 s / 14.442580 FPS, 1.4 ms slower | Reverted |
| Direct `D_DrawSpans16` | Compare `d_drawspans` and call 16-pixel drawer directly | 67.101141 s / 14.440887 FPS, 9.3 ms slower | Reverted |
| World `r_drawpolys` hoist | Duplicate surface loops so span path skips poly dispatch | hitch min 1.89 FPS | Reverted |
| Alias `skintable` start addr | Always `D_PolysetUpdateTables`; row lookup instead of `t*skinwidth` | 67.270496 s / 14.404533 FPS, 178.6 ms slower | Reverted |
| Face vert-base hoist (`R_RenderFace`) | Local `r_pcurrentvertbase` for `R_ClipEdge` | 67.123877 s / 14.435996 FPS, 32.0 ms slower | Reverted |
| Fused smax POT wrap (`R_DrawSurface`) | One POT test for soffset wrap and column loop | hitch min 1.91 FPS | Reverted |
| Face model hoist (`R_RenderFace`) | Local `currententity->model` for edges/surfedges | 67.093926 s / 14.442440 FPS, 0.05 ms, run-1 outlier | Reverted |
| AnimateLight length-1 skip (`R_AnimateLight`) | Skip `i % len` when `len==1` | 67.095987 s / 14.441996 FPS, 2.1 ms slower | Reverted |
| Gradient step cache (`D_CalcGradients`) | Reuse s/t step-origin while texinfo/mip/modelorg match | 67.220030 s / 14.415346 FPS, 34.3 ms slower | Reverted |
| Unclipped alias `movzbl` expand (`r_aliasa.s`) | Full-dword vertex expand like the clipped helper | 67.200278 s / 14.419583 FPS, 0.16 ms, overlapping ranges | Reverted |
| Inlined fused frustum (`R_RecursiveWorldNode`) | Multiply `minmaxs` into the plane; no `rejectpt` stores | 67.200552 s / 14.419524 FPS, hitch min 1.87 FPS | Reverted |
| FinalVerts colormap hoist (`D_PolysetDrawFinalVerts`) | Stack-cache `acolormap` next to clip edges | 67.200621 s / 14.419510 FPS, 0.18 ms slower | Reverted |
| Turbulent last-segment divisor switch | Constant `/1`..`/15` so GCC emits IMUL magic | 67.275508 s / 14.403459 FPS, 27.6 ms slower | Reverted |
| Alias POT skinwidth shift (`D_PolysetCalcGradients`) | `shll %cl` when skinwidth is POT, IMUL fallback | 67.260820 s / 14.406604 FPS, 11.7 ms slower | Reverted |
| PreparePoints clip hoist (`R_AliasPreparePoints`) | Locals for `aliasvrect` clip edges | 67.234277 s / 14.412292 FPS, 15.7 ms slower | Reverted |
| 1900 KB surface cache | between 1800 and 2100 | checksum `2955717646` | Reverted |
| 2000 KB surface cache | between 1800 and 2100 | checksum `2955717646` | Reverted |
| 2100 KB surface cache | between 1800 and 2400 | checksum `2955717646`; run 1 hitch min 1.72 FPS | Reverted |
| 4x surface cache (`SURFCACHE_SIZE_AT_320X200`) | 2400 KB | checksum `2955717646` | Reverted |
| Aggressive `-funroll-loops` (`build-dos.ps1`) | Faster but wrong FB | 66.801015 s / 14.505767 FPS; checksum `2623602099` | Reverted |
| MarkLights plane cull (`R_MarkLights`) | Same reject as `R_AddDynamicLights` | 66.776824 s / 14.511022 FPS, 185.8 ms faster | Kept |
| MarkLights S/T extent cull (`R_MarkLights`) | AABB expand by `fmin` after plane reject | 64.253958 s / 15.080783 FPS, 2522.9 ms faster | Kept |
| MarkLights idist cull (`R_MarkLights`) | Clamp-to-rect idist replaces AABB expand | 64.128594 s / 15.110264 FPS, 125.4 ms faster | Kept |
| MarkLights 2x2 sample cull (`R_MarkLights`) | Exact 2x2 discrete idist vs continuous clamp | 64.241100 s / 15.083802 FPS, 112.5 ms slower | Reverted |
| Dlight sample window (`R_AddDynamicLights`) | Clamp s/t loops to idist-feasible indices | run 2 checksum `696680082` | Reverted |
| Sticky dlight cache flag (`D_CacheSurface`) | `cache->dlight` only if a sample was lit | 64.113828 s / 15.113744 FPS, 14.8 ms faster | Kept |
| Alias adivtab 32→64 (`D_PolysetSetUpForLineScan`) | Wider table hit, same FloorDivMod values | 64.104105 s / 15.116037 FPS, 9.7 ms faster | Kept |
| Phantom-mark dlight probe (`D_CacheSurface`) | `R_DlightContributes` skip on marked clean cache | 64.092171 s / 15.118851 FPS, 11.9 ms faster | Kept |
| Alias clip hoist + skip Z reflag (`R_AliasClip`) | Hoist vrect; Z writes final flags | 64.134559 s / 15.108859 FPS, 42.4 ms slower | Reverted |
| Polyset span advancetable hoist (`D_PolysetDrawSpans8`) | Once-per-call `advancetable`/`tstep` | 64.003272 s / 15.139851 FPS, 88.9 ms faster | Kept |
| Polyset sstep hoist (`D_PolysetDrawSpans8`) | BSS `sstep` for `a_sstepxfrac` in pixel loop | 64.012388 s / 15.137695 FPS, 9.1 ms slower | Reverted |
| Polyset Bresenham const hoist (`D_PolysetDrawSpans8`) | Local copies of erroradjust*/ubasestep/countextra | 64.039951 s / 15.131180 FPS, 36.7 ms slower | Reverted |
| Left-edge s/t step CSE (`D_RasterizeAliasPolySmooth`) | Reuse base products for extra steps | 63.984395 s / 15.144318 FPS, 18.9 ms faster | Kept |
| Left-edge ptexextrastep via `a_ststepxwhole` | Carry-adjust + branch instead of skinwidth IMUL | 64.060863 s / 15.126241 FPS, 76.5 ms slower | Reverted |
| Z-span list cursor in `%ebp` (`D_DrawZSpans`) | Drop per-span push/pop of span pointer | 63.895076 s / 15.165488 FPS, 89.3 ms faster | Kept |
| Z-span odd-pixel tag in `%ebp` bit0 (`D_DrawZSpans`) | Drop count push/pop via pointer tag | 63.959669 s / 15.150173 FPS, 64.6 ms slower | Reverted |
| ScanLeftEdge skinwidth stack hoist (`D_PolysetScanLeftEdge`) | Push skinwidth once; `addl (%esp)` on tfrac carry | 63.905049 s / 15.163121 FPS, 10.0 ms slower | Reverted |
| ScanLeftEdge package cursor in `%esi` (`D_PolysetScanLeftEdge`) | Keep `d_pedgespanpackage` live; publish once on exit | 63.783005 s / 15.192135 FPS, 112.1 ms faster | Kept |
| DrawSpans8 stack-live aspancount/errorterm (`D_PolysetDrawSpans8`) | Stack copies for outer right-edge loop | 63.819708 s / 15.183397 FPS, 36.7 ms slower | Reverted |
| ScanLeftEdge pdest/pz cursors (`D_PolysetScanLeftEdge`) | `%edi`/`%ebp` live; light/zi on stack | 63.741911 s / 15.201929 FPS, 41.1 ms faster | Kept |
| ScanLeftEdge aspancount stack (`D_PolysetScanLeftEdge`) | Spill `d_aspancount` beside light/zi; write back once | 63.726061 s / 15.205710 FPS, 15.7 ms faster | Kept |
| Sky `viewspantable` dest (`D_DrawSkyScans8`) | Same table as texture spans | Noise vs aspancount default (~0.01 ms) | Reverted |
| Span16 s/t integer CSE (`d_draw16.s`) | Keep clamped s/t in regs across sfrac/tfrac shifts | 63.784645 s / 15.191744 FPS, ~43 ms slower | Reverted |
| Span16 early `pnext` preload (`d_draw16.s`) | Store next span in `pspantemp` during FDIV setup | Noise / slight loss vs aspancount default | Reverted |
| ScanLeftEdge erroradjust stack (`D_PolysetScanLeftEdge`) | Spill `erroradjustup`/`down` beside aspancount | Hitch min 1.93 FPS; ~13 ms slower median | Reverted |
| ScanLeftEdge errorterm stack (`D_PolysetScanLeftEdge`) | Spill `errorterm` beside aspancount | ~13 ms slower than aspancount-only | Reverted |
| Turbulent sstep/tstep/pbase stack hoist (`D_DrawTurbulent8Span_asm486`) | Snapshot three span-invariant globals once | 63.743347 s / 15.201586 FPS, ~17 ms slower | Reverted |
| Edge-scan surfaces CSE (`R_GenerateSpans` / `Lgs_leading`) | Drop dead `movl C(surfaces),%eax` before leading add | 63.652849 s / 15.223200 FPS, 73.2 ms faster | Kept |
| Edge-scan both-edges leading precompute (`R_GenerateSpans`) | Finish leading surf* before `TrailingEdge`; drop post-call reload | 63.654537 s / 15.222796 FPS, ~1.7 ms slower | Reverted |
| Edge-scan dead `st_key` reload (`Lnewtop_fpop2`) | Remove load overwritten by `Lnewtop` | 63.652266 s / 15.223339 FPS, 0.58 ms faster | Kept |
| TrailingEdge `st_next` CSE (`TrailingEdge`) | Reuse `%ecx` instead of reloading `st_next` | ~63.652240 s, ~0.03 ms (noise) | Reverted |
| DrawSpans8 aspancount register CSE (`D_PolysetDrawSpans8`) | Keep original aspancount in `%ebp` for += | ~63.652379 s, ~0.11 ms slower | Reverted |
| ScanLeftEdge pretouch removal (`D_PolysetScanLeftEdge`) | Drop discarded `movb` cache pretouch | 63.623244 s / 15.230283 FPS, 29.0 ms faster | Kept |
| EmitEdge pretouch removal (`R_EmitEdge`) | Drop discarded next-edge `movl (%edx),%eax` on both sides | 63.614724 s / 15.232323 FPS, 8.5 ms faster | Kept |
| TrailingEdge unlink via live `%ecx` (`TrailingEdge`) | Use preloaded `st_next` directly on emit/LNoEmit2; no reload or `movl %ecx,%edx` | 63.583628 s / 15.239772 FPS, 31.1 ms faster | Kept |
| EmitEdge single `r_pedge` load (`R_EmitEdge`) | Drop preload into `%esi`; load once after horizontal early-out for `et_owner` | 63.573196 s / 15.242273 FPS, 10.4 ms faster | Kept |
| TrailingEdge skip `r_bmodelactive` RMW (`TrailingEdge`) | Skip load/sub/store when `insubmodel==0` | 63.523798 s / 15.254125 FPS, 49.4 ms faster | Kept |
| Bmodel `incl`/`decl` `r_bmodelactive` (`TrailingEdge` / `Lbmodel_leading`) | Memory inc/dec instead of load/add/store; world skip kept | 63.500960 s / 15.259612 FPS, 22.8 ms faster | Kept |
| EmitEdge drop unused clipped `r_pedge` load (`R_EmitEdge`) | Fully-clipped path wrote only `cacheoffset`; `%ecx` load was dead | 63.488089 s / 15.262705 FPS, 12.9 ms faster | Kept |
| TrailingEdge memory `decl` spanstate (`TrailingEdge`) | `--surf->spanstate` via `decl mem`; drop inverted-path store | 63.355125 s / 15.294737 FPS, 133.0 ms faster | Kept |
| Leading spanstate `movl $1` (`Lgs_leading` / `Lbmodel_leading`) | Known-zero fall-through stores 1; skip `incl`/%edx | 63.281476 s / 15.312538 FPS, 73.6 ms faster | Kept |
| EmitEdge defer `edge_p` past horizontal early-out (`R_EmitEdge`) | Load `edge_p`+`leal` next only when emitting; CF preserved | 63.267301 s / 15.315969 FPS, 14.2 ms faster | Kept |
| RecursiveTriangle live new[0]/new[1] (`D_PolysetRecursiveTriangle`) | Reuse Z-setup `%ecx`/`%ebp`; `movzbl` colormap; drop stack reloads | 63.265453 s / 15.316416 FPS, 1.8 ms faster | Kept |
| Aff8 pixel `movzbl` colormap index (`D_PolysetDrawSpans8`) | Replace `xorl`+`movb` with `movzbl` in LDraw8–1 / one-long | 63.179599 s / 15.337229 FPS, 85.9 ms faster | Kept |
| FinalVerts `movzbl` skin texel (`D_PolysetDrawFinalVerts`) | Drop `movb`+`andl $0x00FF`; zero-extend into colormap add | 63.178180 s / 15.337574 FPS, 1.4 ms faster | Kept |
| DrawSubdiv defer `d_pcolormap` past cull (`D_DrawSubdiv`) | Set colormap only when triangle will draw; match C order | 63.145837 s / 15.345430 FPS, 32.3 ms faster | Kept |
| Aff8 one-long defer `ptex` past Z (`LExactlyOneLong`) | Skip skin load on occluded one-pixel Aff8 spans | 63.143310 s / 15.346044 FPS, 2.5 ms faster | Kept |
| RecursiveTriangle defer `lp2[0]` (`D_PolysetRecursiveTriangle`) | Load `lp2[0]` only on equal-`y` nodraw test; flags preserved | 63.141084 s / 15.346585 FPS, 2.2 ms faster | Kept |
| RecursiveTriangle defer split-path prefetches (`D_PolysetRecursiveTriangle`) | Load next-edge `lp3[0]`/`lp1[0]` only after `|dy|` fails to split | 63.139434 s / 15.346986 FPS, 1.7 ms faster | Kept |
| RecursiveTriangle defer `|dy|` y-loads past `|dx|` (`D_PolysetRecursiveTriangle`) | Skip same-edge y loads on `|dx|` early-out; fix `LSplit3` rotate | 63.121804 s / 15.351272 FPS, 17.6 ms faster | Kept |
| StepActiveU defer `et_prev`/`et_next` past aftertail (`R_StepActiveU`) | Match C: early-out before unlink loads on every scanline finish | 63.112658 s / 15.353497 FPS, 9.1 ms faster | Kept |
| InsertNewEdges defer `et_next` past `et_u` (probes 1–3) (`R_InsertNewEdges`) | Skip next-edge load on taken early-out; keep probe-4 `jg` fallthrough | 63.105267 s / 15.355295 FPS, 7.4 ms faster | Kept |
| StepActiveU defer `et_prev` past first `et_u` (`LPushBackLoop`) | Skip prev load on taken pushback early-out; probe 2 unchanged | 63.103178 s / 15.355803 FPS, 2.1 ms faster | Kept |
| EmitEdge defer `r_framecount` past cacheoffset EO (`LPop5AndDone`) | Match C: load framecount only when tagging fully-clipped cache | 63.102686 s / 15.355923 FPS, 0.5 ms faster | Kept |
| StepActiveU defer step-loop `et_next` past order EO (`R_StepActiveU`) | Probes 1–3; load continuation only after aftertail; drop dup unlink load | 63.091427 s / 15.358664 FPS, 11.3 ms faster | Kept |
| RemoveEdges both-stores-then-advance (`R_RemoveEdges`) | Match C unlink; drop `%ebx` push/pop and odd-tail `Lre_done` store | 63.087263 s / 15.359677 FPS, 4.2 ms faster | Kept |
| FinalVerts Aff8-style light<<8 colormap index (`D_PolysetDrawFinalVerts`) | `movb` high byte of `v[4]` into `%dh`; drop dword/`andl`/`addl` | 63.084374 s / 15.360381 FPS, 2.9 ms faster | Kept |
| Leading memory `cmpl` first `st_key` (`Lgs_leading` / `Lbmodel_leading`) | Drop `surf2->key` preload; dead on newtop / 1/z-check | 63.012013 s / 15.378020 FPS, 72.4 ms faster | Kept |
| RecursiveTriangle keep live new[0]/new[1] into LDraw (`D_PolysetRecursiveTriangle`) | Equal-y uses `%eax` for `lp2[0]`; skip stack reloads at draw entry | 63.006559 s / 15.379351 FPS, 5.5 ms faster | Kept |
| Leading sort-loop memory `cmpl` `st_key` (`Lsortloopnb` / `Lsortloop`) | Drop per-probe key preload; same pattern as first-key keep | 62.953783 s / 15.392244 FPS, 52.8 ms faster | Kept |
| Aff8 multi skip dead last-group stepper (`Lp8`) | `decw`/`jz` before s/t/z/ptex advance on final group | 62.830543 s / 15.422436 FPS, 123.2 ms faster | Kept |
| InsertNewEdges memory `cmpl et_u` (`R_InsertNewEdges`) | Drop `%ebx` key preload per probe; keep probe-4 `jg` fallthrough | 62.787258 s / 15.433068 FPS, 43.3 ms faster | Kept |
| StepActiveU `LPushBackLoop` memory `cmpl et_u` (`R_StepActiveU`) | Drop `%ebx` key preload on pushback walk probes | 62.783533 s / 15.433983 FPS, 3.7 ms faster | Kept |
| TrailingEdge memory `cmpl st_last_u` (`TrailingEdge`) | Load `last_u` into `%edx` only on emit; dead on `LNoEmit2` | 62.782647 s / 15.434201 FPS, 0.9 ms faster | Kept |
| ScanLeftEdge skip dead last-row Bresenham (`D_PolysetScanLeftEdge`) | `decl`/`jz` before step after last package; shared epilogue | 62.753905 s / 15.441270 FPS, 28.7 ms faster | Kept |
| StepActiveU memory `addl et_u_step` (`R_StepActiveU`) | Drop `%ebx` u_step preload on all four step probes | 62.649598 s / 15.466979 FPS, 104.3 ms faster | Kept |
| Leading `Lnewtop` memory `cmpl st_last_u` (`R_GenerateSpans`) | Load `last_u` into `%edx` only on emit; same as TrailingEdge | 62.623729 s / 15.473368 FPS, 25.9 ms faster | Kept |
| EmitEdge defer `r_ceilv1` past horizontal EO (`R_EmitEdge`) | Memory `cmpl`; load `%ecx` only when emitting; CF kept for side | 62.621766 s / 15.473853 FPS, 2.0 ms faster | Kept |
| RecursiveTriangle memory `addl` s/t/zi midpoints (`D_PolysetRecursiveTriangle`) | Drop lp2 preloads for new[2]/[3]/[5]; keep lp1 x/y live for nodraw | 62.605144 s / 15.477961 FPS, 16.6 ms faster | Kept |
| EmitEdge memory `cmpl` u-clamp (`R_EmitEdge`) | Load vrect clamp bounds into `%edx` only when clamping | 62.588326 s / 15.482121 FPS, 16.8 ms faster | Kept |
| EmitEdge memory `subl surfaces` (`R_EmitEdge`) | Drop `surfaces` preload into `%esi`; set sort side from `%edx`/immediate | 62.580291 s / 15.484108 FPS, 8.0 ms faster | Kept |

The last accepted clipped-transform comparison used three runs per variant:

```text
C:   69.063022 / 69.062948 / 69.062989 s, median 69.062989 s, 14.030670 FPS
ASM: 68.958781 / 68.958804 / 68.958785 s, median 68.958785 s, 14.051872 FPS
```

The gain is 104.204 ms per timedemo.  Disassembly showed the useful 486-level
difference: the C helper reloads packed vertex bytes through compiler-generated
temporaries for each dot product, while ASM expands them once into scratch
storage and reuses them with x87 arithmetic.  The call boundary is shared.
The helper is intentionally small; it does not rewrite the larger alias path.

## Current baseline and evidence

- Historical pre-experiment reference: 69.234885 s / 13.995834 FPS median.
- Pre-change lock on this pass (`out\dos-timedemo-20260910-221227`):
  `68.958977 / 68.958817 / 68.958799` s, median **68.958817 s / 14.051865 FPS**,
  969 frames, checksum `4154140932`.  Alias-transform focused bench PASS
  (`out\dos-bench-20260910-221009`).  One instrumented profile
  (`out\dos-timedemo-20260910-222107`) ranked self time as texture spans
  25.67%, surface cache 14.55%, alias model 12.83%, Z spans 10.87%, world BSP
  10.83%, edge-scan self 8.83%.  Full-16 `tzero` segments were 1,026,030;
  `tfrac-zero` was 28, so a pure horizontal inner loop is not the common case.
- Current `-O2` after inlined surface/alias setup
  (`out\dos-timedemo-20260910-224722`): `68.946589 / 68.946370 / 68.946351` s,
  median **68.946370 s / 14.054401 FPS**.  Gain is 12.447 ms (0.018%) with the
  same 969-frame checksum.  Kept as `-OptimizationProfile baseline`.
- Previous `-O3` default after the texinfo UB fix and passing `+quit` smoke
  (`out\dos-timedemo-20260910-232607`): `68.421643 / 68.421316 / 68.421397` s,
  median **68.421397 s / 14.162237 FPS**.
- Previous default after the bmodel span-rotation cache
  (`out\dos-timedemo-20260910-233942`): `68.379915 / 68.379696 / 68.379627` s,
  median **68.379696 s / 14.170874 FPS**, checksum `4154140932`.  About
  41.7 ms faster than the previous `-O3` default.  `R_RotateBmodel` still
  rebuilds the matrix; span drawing uses `R_RotateBmodelCached` plus
  consecutive-entity skip.
- Previous default after fusing ambient into the first lightmap style
  (`out\dos-timedemo-20260910-234742`): `68.309988 / 68.309789 / 68.309838` s,
  median **68.309838 s / 14.185365 FPS**, checksum `4154140932`.  About
  69.9 ms faster than the bmodel-cache default.
- Previous default after fusing invert/clamp into the one-style write
  (`out\dos-timedemo-20260911-051131`): `68.265960 / 68.265718 / 68.265779` s,
  median **68.265779 s / 14.194521 FPS**, checksum `4154140932`.  About
  44.1 ms faster than the fused first-style write.
- Previous default after fusing invert/clamp for extra styles as well
  (`out\dos-timedemo-20260911-051834`): `68.265281 / 68.265038 / 68.265121` s,
  median **68.265121 s / 14.194657 FPS**, checksum `4154140932`.  About
  0.66 ms faster than one-style-only fusion; every extra-style run was
  faster than every one-style-only run.
- Previous default after the integer dlight inner loop
  (`out\dos-timedemo-20260911-052933`): `68.210077 / 68.209972 / 68.209845` s,
  median **68.209972 s / 14.206133 FPS**, checksum `4154140932`.  About
  55.1 ms faster than extra-style fusion.  Worst-frame FPS rose from
  6.279967 to 6.299928; low-1% from 6.802995 to 6.837195.  Dlights still
  feed the two-pass accumulate-then-normalize path.
- Previous default after the face Z-gradient cache
  (`out\dos-timedemo-20260911-053759`): `68.198978 / 68.198777 / 68.198746` s,
  median **68.198777 s / 14.208466 FPS**, checksum `4154140932`.  About
  11.2 ms faster than the integer-dlight default; every run was faster than
  every previous-default run.  `out\dos-timedemo-20260911-050318` was a
  stale-`qbench` rerun and is not evidence for this change.
- Previous default after power-of-two column wrap in `R_DrawSurface`
  (`out\dos-timedemo-20260911-054347`): `68.197434 / 68.197202 / 68.197221` s,
  median **68.197221 s / 14.208790 FPS**, checksum `4154140932`.  About
  1.6 ms faster than the Z-gradient cache; every run was faster than every
  Z-cache run.
- Previous default after `D_DrawZSpans` used `zspantable`
  (`out\dos-timedemo-20260911-062059`): `68.049783 / 68.049361 / 68.049299` s,
  median **68.049361 s / 14.239663 FPS**, checksum `4154140932`.  About
  147.9 ms faster than the POT-wrap default.  Worst-frame FPS rose from
  6.300360 to 6.311090.  C `D_DrawZSpans` still multiplies `d_zwidth`.
- Previous default after texture-span `viewspantable` dest addressing
  (`out\dos-timedemo-20260911-063418`): `67.999833 / 67.999624 / 67.999594` s,
  median **67.999624 s / 14.250078 FPS**, checksum `4154140932`.  About
  49.7 ms faster than the Z-span-table default.  Worst-frame FPS rose from
  6.311090 to 6.316737.  C `D_DrawSpans8` still multiplies `screenwidth`.
- Previous default after polyset/sprite/particle `viewspantable` dest
  addressing (`out\dos-timedemo-20260911-064221`):
  `67.991123 / 67.990960 / 67.990997` s, median
  **67.990997 s / 14.251887 FPS**, checksum `4154140932`.  About 8.6 ms
  faster than texture-span-only `viewspantable`.  Worst-frame FPS rose from
  6.316737 to 6.318577.
- Previous default after sprite/particle `zspantable` Z addressing
  (`out\dos-timedemo-20260911-065037`): `67.986523 / 67.986326 / 67.986315` s,
  median **67.986326 s / 14.252866 FPS**, checksum `4154140932`.  About
  4.7 ms faster than extra-`viewspantable`.  Worst-frame FPS rose from
  6.318577 to 6.320384.
- Previous default after 2x surface cache (1200 KB)
  (`out\dos-timedemo-20260911-133815`): `67.416141 / 67.415956 / 67.415942` s,
  median **67.415956 s / 14.373452 FPS**, checksum `4154140932`.  About
  570.4 ms faster than the 600 KB default.
- Previous default after 3x surface cache (1800 KB)
  (`out\dos-timedemo-20260911-134300`): `67.249266 / 67.249142 / 67.249168` s,
  median **67.249168 s / 14.409100 FPS**, checksum `4154140932`.  About
  166.8 ms faster than 2x.  1900 KB, 2000 KB, 2100 KB, and 2400 KB
  were all faster but checksum `2955717646` (same hash as the
  reverted texture-source row-lookup).  Do not grow the cache past
  1800 KB without a new checksum-identical size.
- Previous default after `Turbulent8` `viewspantable` dest rows
  (`out\dos-timedemo-20260911-143822`): `67.248071 / 67.247843 / 67.247873` s,
  median **67.247873 s / 14.409378 FPS**, checksum `4154140932`.  About
  1.3 ms faster than the 1800 KB default.  Worst-frame min FPS is
  6.320384.
- Previous default after the static surface-cache hit path
  (`out\dos-timedemo-20260911-152128`): `67.229687 / 67.229543 / 67.229518` s,
  median **67.229543 s / 14.413306 FPS**, checksum `4154140932`.  About
  18.3 ms faster than the `Turbulent8` dest-row default.  Worst-frame
  min FPS rose from 6.320384 to 6.321120.  Every run was faster than
  every previous-default run.
- Previous default after the FinalVerts clip-rect hoist
  (`out\dos-timedemo-20260911-152839`): `67.218821 / 67.218606 / 67.218548` s,
  median **67.218606 s / 14.415652 FPS**, checksum `4154140932`.  About
  10.9 ms faster than the static cache-hit default.  Worst-frame min
  FPS rose from 6.321120 to 6.321254.  Every run was faster than every
  previous-default run.
- Previous default after skipping unused extra light styles
  (`out\dos-timedemo-20260911-154031`): `67.200635 / 67.200347 / 67.200437` s,
  median **67.200437 s / 14.419549 FPS**, checksum `4154140932`.  About
  18.2 ms faster than the FinalVerts hoist.  Worst-frame min FPS is
  6.321254.  Every run was faster than every previous-default run.
- Previous default after alias raster dest/Z row tables
  (`out\dos-timedemo-20260911-161154`): `67.185888 / 67.185693 / 67.185736` s,
  median **67.185736 s / 14.422704 FPS**, checksum `4154140932`.  About
  14.7 ms faster than the extra-style skip.  Worst-frame min FPS rose
  from 6.321254 to 6.322259.  Every run was faster than every
  previous-default run.
- Previous default after `R_RenderFace` surfedges hoist and clip unroll
  (`out\dos-timedemo-20260911-173034`): `67.097430 / 67.097210 / 67.097222` s,
  median **67.097222 s / 14.441731 FPS**, checksum `4154140932`.  About
  88.5 ms faster than the alias raster dest/Z default.  Worst-frame min
  FPS rose from 6.322259 to 6.325209.  Every run was faster than every
  previous-default run.
- Previous default after the clipped-bmodel surfedges hoist
  (`out\dos-timedemo-20260911-174206`): `67.096456 / 67.096339 / 67.096341` s,
  median **67.096341 s / 14.441920 FPS**, checksum `4154140932`.  About
  0.88 ms faster than the `R_RenderFace` default.  Worst-frame min FPS
  rose from 6.325209 to 6.325275.  Every run was faster than every
  previous-default run.
- Previous default after `R_DrawSurface` 8-bit setup
  (`out\dos-timedemo-20260911-174904`): `67.093796 / 67.093948 / 67.093880` s,
  median **67.093880 s / 14.442450 FPS**, checksum `4154140932`.  About
  2.46 ms faster than the clipped-bmodel hoist.  Worst-frame min FPS
  rose from 6.325275 to 6.325880.  Every run was faster than every
  previous-default run.
- Previous default after mipscale step tables
  (`out\dos-timedemo-20260911-182120`): `67.091435 / 67.091882 / 67.091930` s,
  median **67.091882 s / 14.442880 FPS**, checksum `4154140932`.  About
  2.0 ms faster than the 8-bit surface-setup default.  Worst-frame min
  FPS rose from 6.325880 to 6.325980.  Every run was faster than every
  previous-default run.
- Previous default after skipping the unused `surfscale` FDIV
  (`out\dos-timedemo-20260911-191612`): `67.085825 / 67.085569 / 67.085585` s,
  median **67.085585 s / 14.444235 FPS**, checksum `4154140932`.  About
  6.3 ms faster than the mipscale-table default.  Worst-frame min FPS
  rose from 6.325980 to 6.326751.  Every run was faster than every
  previous-default run.
- Previous default through commit `f6ea9c6` (`out\dos-timedemo-20260914-121838`):
  `66.962797 / 66.962567 / 66.962657` s, median
  **66.962567 s / 14.470771 FPS**, checksum `4154140932` on all three runs.
  About 123 ms (0.18%) faster than the pre-unroll default above.  Eight
  further commits landed after this doc's 67.085585 s snapshot: solid-surface
  `viewspantable` spans (`e869b7d`), integer dlight contribution and test
  (`03bb815`, `06ab02b`), 4x fused lightmap loops (`41757fc`), hoisted
  `R_DrawSurface` mip dispatch (`53a7d7f`), lightstyle counter + `rep` tails +
  16B align (`41aa622`, `3cc85f5`), and `R_RenderFace` / `R_BuildLightMap`
  unrolling (`33c0ebf`, `f6ea9c6`).
  Matching instrumented diagnostic (`out\dos-timedemo-20260914-122314`,
  12.950385 FPS) ranks self time as texture spans 26.24%, surface cache
  13.56%, alias model 13.16%, Z spans 10.98%, world BSP 10.48%, edge-scan
  self 9.07%, surfaces self 5.50%, turbulent 2.57%.  Of 3,513,435 full
  16-pixel texture segments, 1,027,061 (29.2%) have a zero integer t-step;
  `full-tdelta-zero` is only 28, so the fractional t accumulator still
  carries.
- Previous default re-lock without `-funroll-loops`
  (`out\dos-timedemo-20260914-134340`): `66.962837 / 66.962633 / 66.962597` s,
  median **66.962633 s / 14.470758 FPS**, checksum `4154140932` on all three
  runs.  Matches the `f6ea9c6` reference within run noise.
- Previous default after `R_MarkLights` plane cull
  (`out\dos-timedemo-20260914-140045`): `66.776961 / 66.776735 / 66.776824` s,
  median **66.776824 s / 14.511022 FPS**, checksum `4154140932` on all three
  runs.  About 185.8 ms faster than the re-lock; every run was faster than
  every re-lock run.  Faces that cannot receive a dlight sample are no
  longer marked, so `D_CacheSurface` keeps hits instead of rebuilding with
  an empty dlight pass.
- Previous default after `R_MarkLights` S/T extent cull
  (`out\dos-timedemo-20260914-142303`): `64.253958 / 64.253841 / 65.839411` s,
  median **64.253958 s / 15.080783 FPS**, checksum `4154140932` on all three
  runs.  About 2522.9 ms faster than the plane-cull default; every run was
  faster than the plane-cull median.  Run 3 was slower than runs 1/2 but
  still clear of the prior median.  Projected impact outside the lightmap
  rect expanded by `fmin` is no longer marked.
- Previous default after `R_MarkLights` clamp-to-rect idist cull
  (`out\dos-timedemo-20260914-143404`): `64.128632 / 64.128594 / 64.128523` s,
  median **64.128594 s / 15.110264 FPS**, checksum `4154140932` on all three
  runs.  About 125.4 ms faster than the AABB-expand default; every run was
  faster than every AABB-expand run.  Uses the same integer idist metric as
  `R_AddDynamicLights` against the clamped lightmap rect.
- Previous default after sticky `cache->dlight` flag
  (`out\dos-timedemo-20260914-163457`): `64.114027 / 64.113796 / 64.113828` s,
  median **64.113828 s / 15.113744 FPS**, checksum `4154140932` on all three
  runs.  About 14.8 ms faster than the idist-cull default; every run was
  faster than the idist-cull median.  `D_CacheSurface` sets `cache->dlight`
  from `r_dlight_contributed` after `R_DrawSurface`.
- Previous default after alias `adivtab` 32→64
  (`out\dos-timedemo-20260914-164951`): `64.104105 / 64.103726 / 64.569991` s,
  median **64.104105 s / 15.116037 FPS**, checksum `4154140932` on all three
  runs.  About 9.7 ms faster than the sticky-dlight default.  Run 3 was
  slower than the prior median; runs 1/2 were faster.  `D_PolysetSetUpForLineScan`
  tables `tm,tn` in `[-31,32]`.
- Previous default after phantom-mark dlight probe
  (`out\dos-timedemo-20260914-180707`): `64.092357 / 64.092171 / 64.092163` s,
  median **64.092171 s / 15.118851 FPS**, checksum `4154140932` on all three
  runs.  About 11.9 ms faster than the adivtab-64 default; every run was
  faster than the prior median.  `D_CacheSurface` calls `R_DlightContributes`
  when a clean cache is marked this frame and skips the rebuild on a miss.
- Previous default after polyset span advancetable hoist
  (`out\dos-timedemo-20260914-182901`): `64.003358 / 64.003148 / 64.003272` s,
  median **64.003272 s / 15.139851 FPS**, checksum `4154140932` on all three
  runs.  About 88.9 ms faster than the phantom-mark default; every run was
  faster than the prior median.  ASM `D_PolysetDrawSpans8` builds
  `advancetable`/`tstep` once per call.
- Previous default after left-edge s/t step CSE
  (`out\dos-timedemo-20260915-051520`): `63.984653 / 63.984268 / 63.984395` s,
  median **63.984395 s / 15.144318 FPS**, checksum `4154140932` on all three
  runs.  About 18.9 ms faster than the advancetable default; every run was
  faster than the prior median.  Confirms the earlier
  `out\dos-timedemo-20260915-051014` keep (that set had a run-2 hitch).
  `D_RasterizeAliasPolySmooth` reuses s/t base products for extra steps.
- Previous default after Z-span `%ebp` list cursor
  (`out\dos-timedemo-20260915-055029`): `63.895311 / 63.895076 / 63.895065` s,
  median **63.895076 s / 15.165488 FPS**, checksum `4154140932` on all three
  runs.  About 89.3 ms faster than the left-edge CSE default; every run was
  faster than the prior median.  ASM `D_DrawZSpans` keeps the span list in
  `%ebp` and drops the per-span push/pop.
- Previous default after ScanLeftEdge `%esi` package cursor
  (`out\dos-timedemo-20260915-064521`): `63.783098 / 63.783005 / 63.782908` s,
  median **63.783005 s / 15.192135 FPS**, checksum `4154140932` on all three
  runs.  About 112.1 ms faster than the Z-span default; every run was
  faster than the prior median.  ASM `D_PolysetScanLeftEdge` keeps
  `d_pedgespanpackage` in `%esi` for the whole scan and publishes once on
  both exit paths; `errorterm` / `d_aspancount` use `%eax`.
- Previous default after ScanLeftEdge pdest/pz cursors
  (`out\dos-timedemo-20260915-070155`): `63.741911 / 63.741666 / 63.742057` s,
  median **63.741911 s / 15.201929 FPS**, checksum `4154140932` on all three
  runs.  About 41.1 ms faster than the package-cursor default; every run was
  faster than the prior median.  `%edi`/`%ebp` hold live `d_pdest`/`d_pz`;
  light/zi sit on the stack for the scan.
- Re-lock before this pass (`out\dos-timedemo-20260915-073048`):
  `63.741869 / 63.741679 / 63.741717` s, median
  **63.741717 s / 15.201975 FPS**, checksum `4154140932` on all three runs.
  Matches the pdest/pz default within run noise.
- Current default after ScanLeftEdge aspancount stack spill
  (`out\dos-timedemo-20260915-080929`): `63.726312 / 63.726047 / 63.726061` s,
  median **63.726061 s / 15.205710 FPS**, checksum `4154140932` on all three
  runs.  About 15.7 ms faster than the re-lock; every run was faster than
  every re-lock run.  `d_aspancount` lives at `0(%esp)` beside light/zi;
  both exit paths write it back once.
- Current default after edge-scan `surfaces` CSE
  (`out\dos-timedemo-20260915-092321`): `63.652962 / 63.652822 / 63.652849` s,
  median **63.652849 s / 15.223200 FPS**, checksum `4154140932` on all three
  runs.  About 73.2 ms faster than the aspancount default; every run was
  faster than the prior median.  `Lgs_leading` reuses `%eax` already loaded
  with `surfaces` instead of reloading it.
- Current default after edge-scan dead `st_key` reload removal
  (`out\dos-timedemo-20260915-094804`): `63.652309 / 63.652161 / 63.652266` s,
  median **63.652266 s / 15.223339 FPS**, checksum `4154140932` on all three
  runs.  About 0.58 ms faster than the surfaces-CSE default; every run was
  faster than the prior median.  `Lnewtop_fpop2` no longer loads `st_key`
  into `%eax` before `Lnewtop` overwrites it.
- Current default after ScanLeftEdge pretouch removal
  (`out\dos-timedemo-20260915-101018`): `63.623427 / 63.623209 / 63.623244` s,
  median **63.623244 s / 15.230283 FPS**, checksum `4154140932` on all three
  runs.  About 29.0 ms faster than the st_key default; every run was faster
  than the prior median.  The discarded `movb spanpackage_t_size(%esi),%al`
  pretouch is gone; the next package write after `addl` still warms the line.
- Current default after EmitEdge pretouch removal
  (`out\dos-timedemo-20260915-102159`): `63.615049 / 63.614724 / 63.614690` s,
  median **63.614724 s / 15.232323 FPS**, checksum `4154140932` on all three
  runs.  About 8.5 ms faster than the ScanLeftEdge-pretouch default; every
  run was faster than the prior median.  Both leading/trailing
  `movl (%edx),%eax` next-edge pretouches in `R_EmitEdge` are gone.
- Current default after TrailingEdge unlink via live `%ecx`
  (`out\dos-timedemo-20260915-103948`): `63.583853 / 63.583607 / 63.583628` s,
  median **63.583628 s / 15.239772 FPS**, checksum `4154140932` on all three
  runs.  About 31.1 ms faster than the EmitEdge-pretouch default; every run
  was faster than every prior-default run.  Emit and `LNoEmit2` unlink with
  the already-loaded `st_next` in `%ecx` instead of reloading into `%edx`.
- Current default after EmitEdge single `r_pedge` load
  (`out\dos-timedemo-20260915-104810`): `63.573476 / 63.573196 / 63.573176` s,
  median **63.573196 s / 15.242273 FPS**, checksum `4154140932` on all three
  runs.  About 10.4 ms faster than the TrailingEdge-unlink default; every
  run was faster than every prior-default run.  Horizontal edges skip
  `r_pedge` entirely; non-horizontal edges load it once for `et_owner`.
- Current default after TrailingEdge skip of `r_bmodelactive` RMW
  (`out\dos-timedemo-20260915-110651`): `63.523808 / 63.523798 / 63.523763` s,
  median **63.523798 s / 15.254125 FPS**, checksum `4154140932` on all three
  runs.  About 49.4 ms faster than the EmitEdge-`r_pedge` default; every
  run was faster than every prior-default run.  World surfaces
  (`insubmodel==0`) skip the `r_bmodelactive` load/sub/store.
- Current default after bmodel `incl`/`decl` of `r_bmodelactive`
  (`out\dos-timedemo-20260915-111815`): `63.501194 / 63.500915 / 63.500960` s,
  median **63.500960 s / 15.259612 FPS**, checksum `4154140932` on all three
  runs.  About 22.8 ms faster than the world-skip default; every run was
  faster than every prior-default run.  `Lbmodel_leading` uses
  `incl C(r_bmodelactive)`; TrailingEdge bmodels use `decl`.
- Current default after dropping unused clipped `r_pedge` load
  (`out\dos-timedemo-20260915-113652`): `63.488166 / 63.488089 / 63.488004` s,
  median **63.488089 s / 15.262705 FPS**, checksum `4154140932` on all three
  runs.  About 12.9 ms faster than the bmodel-incl/decl default; every run
  was faster than every prior-default run.  Fully-clipped edges only update
  `cacheoffset`.
- Current default after TrailingEdge memory `decl` of `spanstate`
  (`out\dos-timedemo-20260915-115111`, rebench of `114708`):
  `63.355242 / 63.355064 / 63.355125` s, median **63.355125 s / 15.294737 FPS**,
  checksum `4154140932` on all three runs.  About 133.0 ms faster than the
  clipped-`r_pedge` default; every run was faster than every prior-default
  run.  First bench (`114708`) was `63.355247 / 63.355017 / 63.355112` s.
- Current default after leading spanstate `movl $1`
  (`out\dos-timedemo-20260915-120825`): `63.281763 / 63.281476 / 63.281405` s,
  median **63.281476 s / 15.312538 FPS**, checksum `4154140932` on all three
  runs.  About 73.6 ms faster than the TrailingEdge-spanstate-decl default;
  every run was faster than every prior-default run.  Non-inverted leading
  paths store immediate 1; `Lxl_done` keeps `incl`.
- Current default after EmitEdge deferred `edge_p`
  (`out\dos-timedemo-20260915-122259`): `63.267487 / 63.267234 / 63.267301` s,
  median **63.267301 s / 15.315969 FPS**, checksum `4154140932` on all three
  runs.  About 14.2 ms faster than the leading-`movl $1` default; every run
  was faster than every prior-default run.  Horizontal edges skip
  `edge_p`/`leal`; CF from the ceil `cmpl` still feeds the side `jc`.
- Current default after RecursiveTriangle live `new[0]`/`new[1]`
  (`out\dos-timedemo-20260915-124237`): `63.265572 / 63.265453 / 63.265414` s,
  median **63.265453 s / 15.316416 FPS**, checksum `4154140932` on all three
  runs.  About 1.8 ms faster than the deferred-`edge_p` default; every run
  was faster than every prior-default run.
- Current default after Aff8 pixel `movzbl`
  (`out\dos-timedemo-20260915-125058`): `63.179791 / 63.179533 / 63.179599` s,
  median **63.179599 s / 15.337229 FPS**, checksum `4154140932` on all three
  runs.  About 85.9 ms faster than the RecursiveTriangle default; every run
  was faster than every prior-default run.  LDraw8–1 and `LExactlyOneLong`
  use `movzbl` for the texel half of the colormap index.
- Current default after FinalVerts `movzbl` skin texel
  (`out\dos-timedemo-20260915-131025`): `63.178491 / 63.178164 / 63.178180` s,
  median **63.178180 s / 15.337574 FPS**, checksum `4154140932` on all three
  runs.  About 1.4 ms faster than the Aff8-`movzbl` default; every run was
  faster than every prior-default run.
- Current default after DrawSubdiv deferred `d_pcolormap`
  (`out\dos-timedemo-20260915-132507`): `63.146060 / 63.145728 / 63.145837` s,
  median **63.145837 s / 15.345430 FPS**, checksum `4154140932` on all three
  runs.  About 32.3 ms faster than the FinalVerts-`movzbl` default; every
  run was faster than every prior-default run.  Culled triangles skip the
  colormap store.
- Current default after Aff8 one-long deferred `ptex`
  (`out\dos-timedemo-20260915-133615`): `63.143406 / 63.143310 / 63.143203` s,
  median **63.143310 s / 15.346044 FPS**, checksum `4154140932` on all three
  runs.  About 2.5 ms faster than the DrawSubdiv-colormap default; every
  run was faster than every prior-default run.  Occluded one-pixel spans
  skip the skin pointer load.
- Current default after RecursiveTriangle deferred `lp2[0]`
  (`out\dos-timedemo-20260915-140237`): `63.141181 / 63.141050 / 63.141084` s,
  median **63.141084 s / 15.346585 FPS**, checksum `4154140932` on all three
  runs.  About 2.2 ms faster than the Aff8-one-long-`ptex` default; every
  run was faster than every prior-default run.  Unequal-`y` leading edges
  skip the `lp2[0]` load.
- Current default after RecursiveTriangle deferred split-path prefetches
  (`out\dos-timedemo-20260915-144910`): `63.139641 / 63.139434 / 63.139417` s,
  median **63.139434 s / 15.346986 FPS**, checksum `4154140932` on all three
  runs.  About 1.7 ms faster than the `lp2[0]`-defer default; every run was
  faster than every prior-default run.  `LSplit`/`LSplit2` skip the next-edge
  `lp3[0]`/`lp1[0]` loads.
- Current default after RecursiveTriangle deferred `|dy|` y-loads
  (`out\dos-timedemo-20260915-150014`): `63.121965 / 63.121804 / 63.121646` s,
  median **63.121804 s / 15.351272 FPS**, checksum `4154140932` on all three
  runs.  About 17.6 ms faster than the split-prefetch default; every run was
  faster than every prior-default run.  `|dx|` early-outs skip both y loads;
  `LSplit3` does `movl %ebx,%edx` locally.
- Current default after StepActiveU deferred aftertail unlink loads
  (`out\dos-timedemo-20260915-153501`): `63.113353 / 63.112658 / 63.112628` s,
  median **63.112658 s / 15.353497 FPS**, checksum `4154140932` on all three
  runs.  About 9.1 ms faster than the `|dx|` y-load default; every run was
  faster than every prior-default run.  Scanline finish via `edge_aftertail`
  no longer loads `et_prev`/`et_next`.
- Current default after InsertNewEdges deferred `et_next` (probes 1–3)
  (`out\dos-timedemo-20260915-154958`): `63.105419 / 63.105230 / 63.105267` s,
  median **63.105267 s / 15.355295 FPS**, checksum `4154140932` on all three
  runs.  About 7.4 ms faster than the StepActiveU-aftertail default; every
  run was faster than every prior-default run.  Taken `et_u` early-outs
  skip the next-edge load; probe 4 keeps `jg` fallthrough.
- Current default after StepActiveU `LPushBackLoop` deferred `et_prev`
  (`out\dos-timedemo-20260915-160134`): `63.103349 / 63.103178 / 63.103124` s,
  median **63.103178 s / 15.355803 FPS**, checksum `4154140932` on all three
  runs.  About 2.1 ms faster than the InsertNewEdges-`et_next` default;
  every run was faster than every prior-default run.  First-probe
  `LPushBackFound` skips the `et_prev` load.  (An earlier measurement
  `out\dos-timedemo-20260915-155745` had a hitch min 1.88 FPS on run 2;
  the clean re-run is the accepted evidence.)
- Current default after EmitEdge deferred `r_framecount` on `LPop5AndDone`
  (`out\dos-timedemo-20260915-163753`): `63.102870 / 63.102606 / 63.102686` s,
  median **63.102686 s / 15.355923 FPS**, checksum `4154140932` on all three
  runs.  About 0.5 ms faster than the `LPushBackLoop`-`et_prev` default;
  every run was faster than every prior-default run.  Partially-clipped
  exits (`cacheoffset == 0x7FFFFFFF`) skip the `r_framecount` load.
- Current default after StepActiveU deferred step-loop `et_next`
  (`out\dos-timedemo-20260915-165144`): `63.091567 / 63.091379 / 63.091427` s,
  median **63.091427 s / 15.358664 FPS**, checksum `4154140932` on all three
  runs.  About 11.3 ms faster than the `r_framecount`-defer default; every
  run was faster than every prior-default run.  Aftertail / pushback no
  longer pay a probe preload; unlink uses one `et_next` load.
- Current default after RemoveEdges both-stores-then-advance
  (`out\dos-timedemo-20260915-171204`): `63.087380 / 63.087263 / 63.087206` s,
  median **63.087263 s / 15.359677 FPS**, checksum `4154140932` on all three
  runs.  About 4.2 ms faster than the StepActiveU-`et_next` default; every
  run was faster than every prior-default run.  Odd-length remove lists
  no longer take a special path to finish `prev->next`.
- Current default after FinalVerts Aff8-style light<<8 index
  (`out\dos-timedemo-20260915-172059`): `63.084563 / 63.084374 / 63.084351` s,
  median **63.084374 s / 15.360381 FPS**, checksum `4154140932` on all three
  runs.  About 2.9 ms faster than the RemoveEdges default; every run was
  faster than every prior-default run.
- Current default after leading memory `cmpl` first `st_key`
  (`out\dos-timedemo-20260915-173942`): `63.011902 / 63.012013 / 63.012104` s,
  median **63.012013 s / 15.378020 FPS**, checksum `4154140932` on all three
  runs.  About 72.4 ms faster than the FinalVerts-light<<8 default; every
  run was faster than every prior-default run.  `Lnewtop` /
  `Lzcheck_for_newtop` skip the `surf2->key` register preload.
- Current default after RecursiveTriangle live new[] into LDraw
  (`out\dos-timedemo-20260915-174638`): `63.006416 / 63.006581 / 63.006559` s,
  median **63.006559 s / 15.379351 FPS**, checksum `4154140932` on all three
  runs.  About 5.5 ms faster than the leading-`st_key`-`cmpl` default; every
  run was faster than every prior-default run.  Unequal-`y` draws skip
  stack reloads of `new[0]`/`new[1]`.
- Current default after leading sort-loop memory `cmpl` `st_key`
  (`out\dos-timedemo-20260915-180350`): `62.953648 / 62.953783 / 62.953854` s,
  median **62.953783 s / 15.392244 FPS**, checksum `4154140932` on all three
  runs.  About 52.8 ms faster than the live-new-into-LDraw default; every
  run was faster than every prior-default run.
- Current default after Aff8 multi skip dead last-group stepper
  (`out\dos-timedemo-20260915-182515`): `62.830458 / 62.830543 / 62.830579` s,
  median **62.830543 s / 15.422436 FPS**, checksum `4154140932` on all three
  runs.  About 123.2 ms faster than the sort-loop-`st_key` default; every
  run was faster than every prior-default run.
- Current default after InsertNewEdges memory `cmpl et_u`
  (`out\dos-timedemo-20260915-183750`): `62.787043 / 62.787258 / 62.787362` s,
  median **62.787258 s / 15.433068 FPS**, checksum `4154140932` on all three
  runs.  About 43.3 ms faster than the Aff8-last-group default; every run
  was faster than every prior-default run.
- Current default after `LPushBackLoop` memory `cmpl et_u`
  (`out\dos-timedemo-20260915-184357`): `62.783709 / 62.783486 / 62.783533` s,
  median **62.783533 s / 15.433983 FPS**, checksum `4154140932` on all three
  runs.  About 3.7 ms faster than the InsertNewEdges-`et_u`-`cmpl` default;
  every run was faster than every prior-default run.
- Current default after TrailingEdge memory `cmpl st_last_u`
  (`out\dos-timedemo-20260915-190100`): `62.782709 / 62.782647 / 62.782532` s,
  median **62.782647 s / 15.434201 FPS**, checksum `4154140932` on all three
  runs.  About 0.9 ms faster than the `LPushBackLoop`-`et_u`-`cmpl` default;
  every run was faster than every prior-default run.
- Current default after ScanLeftEdge skip dead last-row Bresenham
  (`out\dos-timedemo-20260915-200539`): `62.810895 / 62.753822 / 62.753905` s,
  median **62.753905 s / 15.441270 FPS**, checksum `4154140932` on all three
  runs.  About 28.7 ms faster than the TrailingEdge-`last_u` default; every
  run was faster than every prior-default run.  (Earlier measurement
  `out\dos-timedemo-20260915-200144` had a 62.856 s middle-run outlier;
  the clean re-run is the accepted evidence.)
- Current default after StepActiveU memory `addl et_u_step`
  (`out\dos-timedemo-20260915-202546`): `62.651188 / 62.649598 / 62.649569` s,
  median **62.649598 s / 15.466979 FPS**, checksum `4154140932` on all three
  runs.  About 104.3 ms faster than the ScanLeftEdge default; every run
  was faster than every prior-default run.
- Current default after leading `Lnewtop` memory `cmpl st_last_u`
  (`out\dos-timedemo-20260915-203108`): `62.623894 / 62.623729 / 62.623708` s,
  median **62.623729 s / 15.473368 FPS**, checksum `4154140932` on all three
  runs.  About 25.9 ms faster than the StepActiveU-`et_u_step` default; every
  run was faster than every prior-default run.
- Current default after EmitEdge defer `r_ceilv1` past horizontal EO
  (`out\dos-timedemo-20260915-204522`): `62.621949 / 62.621766 / 62.621726` s,
  median **62.621766 s / 15.473853 FPS**, checksum `4154140932` on all three
  runs.  About 2.0 ms faster than the `Lnewtop`-`last_u` default; every run
  was faster than every prior-default run.
- Current default after RecursiveTriangle memory `addl` s/t/zi midpoints
  (`out\dos-timedemo-20260915-205607`): `62.605330 / 62.605144 / 62.605103` s,
  median **62.605144 s / 15.477961 FPS**, checksum `4154140932` on all three
  runs.  About 16.6 ms faster than the EmitEdge-`r_ceilv1` default; every
  run was faster than every prior-default run.
- Previous default after EmitEdge memory `cmpl` u-clamp
  (`out\dos-timedemo-20260915-210614`): `62.588579 / 62.588326 / 62.588325` s,
  median **62.588326 s / 15.482121 FPS**, checksum `4154140932` on all three
  runs.  About 16.8 ms faster than the RecursiveTriangle-midpoint default;
  every run was faster than every prior-default run.
- Current default after EmitEdge memory `subl surfaces`
  (`out\dos-timedemo-20260915-211623`): `62.580216 / 62.580291 / 62.580319` s,
  median **62.580291 s / 15.484108 FPS**, checksum `4154140932` on all three
  runs.  About 8.0 ms faster than the u-clamp default; every run was faster
  than every prior-default run.  `LSide1`/`LSide0` compute
  `surface_p - surfaces` with memory `subl C(surfaces)` and set the sort
  side register from zeroed `%edx` or immediate 1.

## Important decisions and assumptions

- Original C bodies stay intact as references; do not delete them to make ASM
  the only implementation.
- A focused microbenchmark win is not sufficient.  Require correctness,
  matched release timedemos, and a measured end-to-end gain before changing a
  default.
- Keep `-O3 -march=i486` as the measured default, the same DOSBox-X
  version/profile/cycles, demo, data, and command-line options for A/B
  comparisons.  Use `-OptimizationProfile baseline` for `-O2`.  Do not
  enable newer ISA requirements.  Do not add `-funroll-loops` to the
  aggressive C flags; it failed the framebuffer checksum gate.
- Exact framebuffer checksum is the automated parity gate.  It does not prove
  complete visual or gameplay parity outside the timedemo.
- `R_AliasTransformFinalVert_asm486` uses static scratch labels in
  `asm486_experiments.s`; this is acceptable for the current single-threaded
  DOS renderer, but the helper is not reentrant.
- DOSBox-X timing is an emulated 486-class model.  No physical 486 measurement
  has been made, and only `demo1` has been used for the documented matched
  end-to-end comparisons.

## Failed or inconclusive work

- `Lgs_lastspan` memory `cmpl st_last_u`
  (`out\dos-timedemo-20260915-204034`) matched checksum `4154140932` but
  was ~4.3 ms slower than the `Lnewtop`-`last_u` default (median 62.628042 s).
  Once-per-scanline right-edge emit; do not retry.
- Aff8 DrawSpans8 skip last-span right-edge Bresenham
  (`out\dos-timedemo-20260915-201944`) matched checksum `4154140932` but
  was ~19.5 ms slower than the ScanLeftEdge default (median 62.773405 s).
  Peeking the `-999999` sentinel before the step hurt the common path;
  do not retry.
- Particle NxN drop `%esi` push; use dead `%eax` for `d_zrowbytes`
  (`out\dos-timedemo-20260915-195244`) matched checksum `4154140932` but
  was noise (~0.3 ms vs the TrailingEdge-`last_u` default).  Do not retry.
- Leading inverted `Lxl_done` memory `incl` spanstate
  (`out\dos-timedemo-20260915-185246`) matched checksum `4154140932` but
  was noise (~0.1 ms vs the `LPushBackLoop`-`et_u`-`cmpl` default).
  Do not retry.
- EmitEdge defer `r_ceilv1` fistl past `r_nearzionly` (`out\dos-timedemo-20260915-181715`)
  matched checksum `4154140932` but was ~20.4 ms slower than the sort-loop
  `st_key` default (median 62.974149 s).  Extra `fxch` around deferred
  `fistl` on the common emit path hurt more than skipping ceil on
  nearzionly; do not retry.
- Sprite `D_SpriteDrawSpans` v/u CSE across Z and dest setup
  (`out\dos-timedemo-20260915-172816`) matched checksum `4154140932` but
  was noise (~0.14 ms vs the FinalVerts-light<<8 default).  Keeping
  `sspan_t_v`/`u` live did not move end-to-end time; do not retry.
- Particle defer rect-edge loads past clip early-outs (`D_DrawParticle`)
  (`out\dos-timedemo-20260915-170311`) matched checksum `4154140932` but
  was noise (~0.4 ms vs the StepActiveU-`et_next` default).  Short-circuit
  loads for `d_vrectright_particle` / `d_vrectx` did not move end-to-end
  time; do not retry.
- RecursiveTriangle keep `lp2[1]` live via `leal` for nodraw compare
  (`out\dos-timedemo-20260915-161932`) matched checksum `4154140932` but
  was noise/tied vs the `LPushBackLoop`-`et_prev` default (median
  63.103192 s; run 1 outlier 63.699628 s).  Avoiding the `4(%esi)` reload
  did not move end-to-end time; do not retry.
- InsertNewEdges defer `et_next` on all four probes with `jle`+`jmp`
  (`out\dos-timedemo-20260915-154519`) matched checksum `4154140932` but
  was noise (~0.4 ms vs the StepActiveU-aftertail default).  The extra
  unconditional `jmp` on long walks cancelled the load savings; keep
  probes 1–3 only with probe-4 `jg` fallthrough.  Do not retry the
  four-probe+`jmp` form.
- InsertNewEdges unify `LAddedge2` into `LAddedge` (`out\dos-timedemo-20260915-152701`)
  matched checksum `4154140932` but was ~4.2 ms slower than the `|dx|` y-load
  default (median 63.125989 s).  Falling through with `movl %esi,%ecx` hurt;
  do not retry.
- Sprite `Spr8Entry2_8` drop dead texel preload (`out\dos-timedemo-20260915-152226`)
  matched checksum `4154140932` but was noise (~0.1 ms).  `LLEntry2_8` already
  reloads after Z; removing the entry stub `movb` did not move end-to-end time;
  do not retry.
- Aff8 hoist `pz`/`zi` before one-long vs multi (`out\dos-timedemo-20260915-151700`)
  matched checksum `4154140932` but was noise (~0.1 ms).  Sharing loads across
  the `cmpl $1` split (flags preserved by `movl`) did not help; do not retry.
- Particle defer `pt_color` past Z (`out\dos-timedemo-20260915-135449`)
  matched checksum `4154140932` but was noise (~0.4 ms vs the Aff8-one-long
  default).  Per-leaf color loads for 1x1 after Z / NxN at entry did not
  move end-to-end time enough to keep; do not retry.
- Leading defer `surfaces[1].next` past inverted early-out
  (`out\dos-timedemo-20260915-123249`) matched checksum `4154140932` but was
  noise/~tied vs the deferred-`edge_p` default (median 63.267303 s).
  Splitting `LPatch2`/`LPatch2b` after the spanstate tests did not move
  end-to-end time; do not retry.
- TrailingEdge hoist `st_next` into `%ecx` for `LNoEmit`
  (`out\dos-timedemo-20260915-120218`) matched checksum `4154140932` but was
  noise (~0.08 ms vs the spanstate-decl default).  Preloading before the
  top-of-stack compare and sharing the emit unlink form for `LNoEmit` did
  not move end-to-end time; do not retry.
- EmitEdge `r_pedge`/`et_owner` into FDIV shadow (`out\dos-timedemo-20260915-112708`)
  matched checksum `4154140932` but was noise (~0.03 ms vs the bmodel
  incl/decl default).  Starting u-step FDIV before the owner store did not
  help; keep owner store before the side branch.  Do not retry.
- PolysetCalcGradients s/t step CSE (`out\dos-timedemo-20260915-113155`)
  matched checksum `4154140932` but median tied the prior default
  (63.500960 s).  Copying `r_sstepx`/`r_tstepx` before `shll` to avoid a
  second pair of loads did not move end-to-end time; do not retry.
- Leading spanstate-before-insubmodel reorder (`out\dos-timedemo-20260915-110203`)
  matched checksum `4154140932` but was noise (~0.01 ms vs the EmitEdge
  `r_pedge` default).  Testing inversion before loading `insubmodel` and
  dropping the redundant `Lbmodel_leading` spanstate retest did not move
  end-to-end time; do not retry.
- Span16 FILD-overlapped v/u loads (`out\dos-timedemo-20260915-103436`)
  matched checksum `4154140932` but was noise/~0.14 ms slower than the
  EmitEdge-pretouch default (median 63.614868 s vs 63.614724 s).  Loading
  `espan_t_v`/`espan_t_u` into `%eax`/`%ecx` under FILD and skipping the
  FDIV-shadow reloads did not help under DOSBox-X's 486 model; do not retry
  moving those dest-setup loads earlier in `D_DrawSpans16`.
- DrawSpans8 aspancount register CSE (`out\dos-timedemo-20260915-100552`)
  matched checksum `4154140932` but was noise/~0.11 ms slower than the
  st_key default.  Do not retry keeping a second copy of `d_aspancount` in
  `%ebp` for the right-edge `+=` update.
- TrailingEdge `st_next` CSE via `movl %ecx,%edx` (`out\dos-timedemo-20260915-095842`)
  matched checksum `4154140932` but was noise (~0.03 ms).  Replaced by the
  kept direct-`%ecx` unlink (`out\dos-timedemo-20260915-103948`); do not
  retry the intermediate `movl %ecx,%edx` form.
- Edge-scan both-edges leading precompute (`out\dos-timedemo-20260915-094223`)
  matched checksum `4154140932` but was ~1.7 ms slower than the surfaces-CSE
  default (63.654537 s vs 63.652849 s).  Finishing `surf*` before
  `TrailingEdge` avoided a reload but the leading-only join cost more;
  do not retry.
- Turbulent sstep/tstep/pbase stack hoist (`out\dos-timedemo-20260915-091357`)
  matched checksum `4154140932` but was ~17 ms slower than the aspancount
  default (63.743347 s vs 63.726061 s).  Absolute C-global loads beat
  stack-relative copies for those three invariants; do not retry.
- HDPMI32 as an alternate DPMI server (`DPMI-HDPMI32.md`,
  `out\dos-dpmi-compare-20260915-084120`): resident `HDPMI32 -r` is
  detected and Quake completes `demo1`, but every run failed checksum
  `2955717646` vs `4154140932`.  Median FPS looked ~0.05% higher while
  measuring different pixels, and one of five HDPMI runs hitching widened
  its FPS range to 0.325.  Keep CWSDPMI; do not promote HDPMI32.
- A texture row-lookup experiment was reverted after a faster run produced
  checksum `2955717646` instead of `4154140932`.
- The isolated surface-cache, mip, BSP-dot, and BSP-clip wins did not survive
  the real call boundary and workload; their C paths remain defaults.
- The broad mixed benchmark matrix in
  `out\dos-bench-20260910-204331` exceeded its 300-second diagnostic bound
  before producing a result JSON.  It is not a passing benchmark and should
  not be used as evidence.
- Alias `AngleVectors` caching (`out\dos-timedemo-20260911-055546`) matched
  checksum `4154140932` but was 15.6 ms slower than the current default.
  Hit rate did not cover the probe/copy cost; do not retry a per-frame
  angle-basis cache.
- Direct mip0 column calls (`out\dos-timedemo-20260911-060235`) matched
  checksum `4154140932` but were 1.1 ms slower than the indirect
  `(*pblockdrawer)()` POT loop.  Do not retry direct mip drawers.
- Remainder `EntryN_16` t-zero cachewidth skip
  (`out\dos-timedemo-20260911-132341`) matched checksum `4154140932` but
  was 20.8 ms slower (68.007120 s vs 67.986326 s).  The extra remainder
  branch cost more than the skipped IMUL; do not retry.
- Texture-source `cachespantable` (`out\dos-timedemo-20260911-133154`)
  matched checksum `4154140932` but was 347 ms slower.  Filling source
  rows per surface cost more than the per-span cachewidth IMUL; do not
  retry a per-surface source-row table.
- Alias POT skinwidth shift (`out\dos-timedemo-20260911-140630`)
  matched checksum `4154140932` but was 11.7 ms slower (67.260820 s
  vs 67.249168 s).  The extra `test`/`js`/`jmp` around one per-triangle
  IMUL cost more than the shift; do not retry a branched skinwidth
  shift.
- PreparePoints clip-rect hoist (`out\dos-timedemo-20260911-153350`)
  matched checksum `4154140932` but was 15.7 ms slower (67.234277 s
  vs 67.218606 s).  Extra locals around the transform/project calls
  spilled; do not retry hoisting `aliasvrect` in `R_AliasPreparePoints`.
- Alias clip hoist + skip Z reflag (`out\dos-timedemo-20260914-181813`)
  matched checksum `4154140932` but was 42.4 ms slower (64.134559 s
  vs 64.092171 s).  Extra locals / `clip != R_Alias_clip_z` branch in
  `R_AliasClip` cost more than the skipped retest; do not retry.
- Polyset sstep hoist (`out\dos-timedemo-20260914-183707`)
  matched checksum `4154140932` but was 9.1 ms slower (64.012388 s
  vs 64.003272 s).  Routing `a_sstepxfrac` through BSS `sstep` in the
  pixel loop did not beat the direct C global; keep `addl C(a_sstepxfrac)`.
- Polyset Bresenham const hoist (`out\dos-timedemo-20260914-184757`)
  matched checksum `4154140932` but was 36.7 ms slower (64.039951 s
  vs 64.003272 s).  Local copies of `erroradjustup`/`down`, `ubasestep`,
  and `d_countextrastep` for the span prologue cost more than the C
  global loads; do not retry.
- Left-edge `d_ptexextrastep` via `a_ststepxwhole`
  (`out\dos-timedemo-20260915-053730`) matched checksum `4154140932`
  but was 76.5 ms slower (64.060863 s vs 63.984395 s).  Carry adjust
  plus ±1/`t_adj` branches cost more than `(textra>>16)*skinwidth`; keep
  the direct IMUL form from the left-edge s/t CSE keep.
- Z-span odd-pixel `%ebp` bit0 tag (`out\dos-timedemo-20260915-060125`)
  matched checksum `4154140932` but was 64.6 ms slower (63.959669 s
  vs 63.895076 s).  Tagging the span cursor to drop the count push/pop
  cost more than the stack traffic; keep `pushl %ecx` / `popl %ecx`.
- ScanLeftEdge skinwidth stack hoist (`out\dos-timedemo-20260915-061218`)
  matched checksum `4154140932` but was 10.0 ms slower (63.905049 s
  vs 63.895076 s).  Pushing `skinwidth` once and `addl (%esp)` on tfrac
  carry did not beat the direct `r_affinetridesc` load; do not retry.
- DrawSpans8 stack-live aspancount/errorterm
  (`out\dos-timedemo-20260915-065310`) matched checksum `4154140932`
  but was 36.7 ms slower (63.819708 s vs 63.783005 s).  Routing the
  outer right-edge mutables through stack slots cost more than the C
  globals; keep direct `C(d_aspancount)` / `C(errorterm)` traffic.
  (ScanLeftEdge aspancount stack spill is a different site and was kept.)
- ScanLeftEdge erroradjust stack (`out\dos-timedemo-20260915-075950`)
  matched checksum `4154140932` but hitch min 1.93 FPS and ~13 ms slower
  median than the aspancount-only default.  Do not retry spilling
  `erroradjustup`/`down` beside the kept ScanLeftEdge stack locals.
- ScanLeftEdge errorterm stack (`out\dos-timedemo-20260915-080441`)
  matched checksum `4154140932` but was ~13 ms slower than aspancount-only.
  Do not retry spilling `errorterm` beside aspancount in ScanLeftEdge.
- Span16 s/t integer CSE (`out\dos-timedemo-20260915-074041`) matched
  checksum `4154140932` but was ~43 ms slower.  Do not retry keeping
  clamped s/t in registers across the sfrac/tfrac shifts in
  `D_DrawSpans16`.
- Span16 early `pnext` preload (`out\dos-timedemo-20260915-075512`)
  matched checksum `4154140932` but was noise/slightly slower.  Do not
  retry storing the next span in `pspantemp` during FDIV setup.
- Sky `viewspantable` dest (`out\dos-timedemo-20260915-075043`) matched
  checksum `4154140932` but was noise (~0.01 ms).  Do not retry
  `D_DrawSkyScans8` row-table addressing for timedemo gain; multiply
  form remains.
- Unclipped alias `movzbl` expand (`out\dos-timedemo-20260911-155009`)
  matched checksum `4154140932` but the 0.16 ms median delta sat
  inside the previous run spread; do not retry byte-store vs
  `movzbl` expansion in `R_AliasTransformAndProjectFinalVerts`.
- Inlined fused frustum (`out\dos-timedemo-20260911-155650`)
  matched checksum `4154140932` but run 3 hitched to 1.87 FPS and
  the median was 0.12 ms slower.  Do not retry fused `minmaxs`
  multiplies in `R_RecursiveWorldNode`; the extra CALL helper already
  lost, and this inlined form did not beat the original stores.
- FinalVerts colormap hoist (`out\dos-timedemo-20260911-160304`)
  matched checksum `4154140932` but was 0.18 ms slower (67.200621 s
  vs 67.200437 s).  Do not retry stacking `acolormap` in
  `D_PolysetDrawFinalVerts`; the clip-edge hoist is enough.
- Gradient step cache (`out\dos-timedemo-20260911-161755`)
  matched checksum `4154140932` but was 34.3 ms slower (67.220030 s
  vs 67.185736 s).  The texinfo/mip/modelorg compares cost more than
  the skipped step muls; do not retry a last-used `D_CalcGradients`
  step-origin cache.
- Mip-scaled modelorg (`D_CalcGradients`,
  `out\dos-timedemo-20260911-183436`) matched checksum `4154140932`
  but was 4.2 ms slower (67.096034 s vs 67.091882 s) with an 846 ms
  first-run outlier.  Do not retry precomputing
  `transformed_modelorg × mipscale`; the per-frame `xscaleinv` tables
  are enough.
- DrawSurfaces Restore/Set CALL skip
  (`out\dos-timedemo-20260911-184541`) matched checksum `4154140932`
  but was 1.4 ms slower (67.093276 s vs 67.091882 s).  Extra
  per-surface `span_bmodel` tests cost more than the no-op CALL on
  the 486; do not retry skipping `D_RestoreWorldDrawingState` /
  `D_SetBmodelDrawingState` with caller-side ifs.
- Direct `D_DrawSpans16` (`out\dos-timedemo-20260911-185331`)
  matched checksum `4154140932` but was 9.3 ms slower (67.101141 s
  vs 67.091882 s).  Do not retry a per-surface compare against
  `d_drawspans` to turn the indirect CALL into a direct one.
- World `r_drawpolys` hoist (`out\dos-timedemo-20260911-185857`)
  matched checksum `4154140932` but run 1 hitched to **1.89 FPS**
  (67.545301 s).  Runs 2/3 were ~3 ms faster and are not a promote.
  Do not retry duplicating `R_RecursiveWorldNode` surface loops to
  hoist `r_drawpolys`; growing that function hitches like fused
  frustum.
- Alias `skintable` start addressing
  (`out\dos-timedemo-20260911-190512`) matched checksum `4154140932`
  but was 178.6 ms slower (67.270496 s vs 67.091882 s).  Do not
  retry `skintable` in `D_RasterizeAliasPolySmooth` or calling
  `D_PolysetUpdateTables` on the clipped path; keep the
  `t*skinwidth` start IMUL and the drawtype-only table fill.
- Skip live `blocksize` (`R_DrawSurface`,
  `out\dos-timedemo-20260911-192431`) was faster but checksum
  `2281919689`.  The 8-bit column loop still advances `soffset` with
  the `blocksize` global.  Do not skip storing `blocksize`; dest
  `horzblockstep` is not enough.
- `R_DrawSurface` surfmip hoist (`out\dos-timedemo-20260911-193158`)
  matched checksum `4154140932` but the 0.008 ms median delta sat
  inside the previous run spread (67.085593 s vs 67.085585 s).  Do
  not retry a local `mip` for rebuild setup; `-O3` already CSEs
  `r_drawsurf.surfmip`.
- Face vert-base hoist (`R_RenderFace`,
  `out\dos-timedemo-20260911-182623`) matched checksum `4154140932`
  but was 32.0 ms slower (67.123877 s vs 67.091882 s).  The extra
  local spilled the edge loop; do not retry hoisting
  `r_pcurrentvertbase` in `R_RenderFace`.
- AnimateLight length-1 skip (`out\dos-timedemo-20260911-180922`)
  matched checksum `4154140932` but was 2.1 ms slower (67.095987 s
  vs 67.093880 s).  The extra `len==1` branch cost more than the
  skipped IDIV; do not retry length-1 or POT remainder in
  `R_AnimateLight`.
- Face model hoist (`R_RenderFace`,
  `out\dos-timedemo-20260911-180409`) matched checksum `4154140932`
  but the median was 0.05 ms slower (67.093926 s vs 67.093880 s)
  with a 500 ms first-run outlier.  Do not retry hoisting
  `currententity->model` in `R_RenderFace`; the surfedges pointer is
  enough.
- Fused smax POT wrap (`R_DrawSurface`,
  `out\dos-timedemo-20260911-175426` and confirmation
  `out\dos-timedemo-20260911-175849`) matched checksum `4154140932`
  but hitched: first confirmation run min **1.91 FPS**, and the first
  measurement run was 700 ms slower.  Do not retry folding the soffset
  wrap into the column-loop POT test.
- Bmodel clip unroll (`R_RenderBmodelFace`,
  `out\dos-timedemo-20260911-173554`) matched checksum `4154140932` but
  the median was 0.07 ms slower than the `R_RenderFace` default
  (67.097295 s vs 67.097222 s) with fully overlapping run ranges.
  Do not retry unrolling the bmodel clip-plane list; world-face
  surfedges addressing was the real win.
- Turbulent last-segment divisor switch
  (`out\dos-timedemo-20260911-150819`) matched checksum `4154140932`
  but was 27.6 ms slower (67.275508 s vs 67.247873 s).  GCC did emit
  IMUL magic, but the 15-way jump table cost more than two IDIVs; do
  not retry a switch or jump table around the last-segment divide.
- 1900 KB (`out\dos-timedemo-20260911-142256`), 2000 KB
  (`out\dos-timedemo-20260911-141744`), 2100 KB
  (`out\dos-timedemo-20260911-135941`), and 2400 KB
  (`out\dos-timedemo-20260911-135043`) were all faster (about
  14.43 FPS) but checksum `2955717646`.  2100 KB run 1 also hitched
  to 1.72 FPS.  1800 KB is the largest checksum-identical size
  measured.  Do not retry 1900 KB or larger without a new
  checksum-identical size.
- Aggressive `-funroll-loops` in `tools\build-dos.ps1`
  (`out\dos-timedemo-20260914-134806`) was about 161.6 ms faster than the
  matched control (`out\dos-timedemo-20260914-134340`: median
  66.962633 s / 14.470758 FPS) at median **66.801015 s / 14.505767 FPS**,
  but every run produced framebuffer checksum `2623602099` instead of
  `4154140932`.  Do not retry global `-funroll-loops` under `-ffast-math`;
  targeted source unrolls that keep the checksum remain allowed.
- MarkLights 2x2 sample cull (`out\dos-timedemo-20260914-161209`) matched
  checksum `4154140932` but was 112.5 ms slower than the continuous
  clamp-to-rect idist default (64.241100 s / 15.083802 FPS vs
  64.128594 s / 15.110264 FPS).  Extra per-face sample work cost more than
  the few additional culls; do not retry a 2x2 or fuller discrete sample
  scan in `R_MarkLights`.
- Dlight sample-window clamp in `R_AddDynamicLights`
  (`out\dos-timedemo-20260914-162709`) produced checksum `696680082` on
  run 2 (runs 1/3 kept `4154140932`).  Do not retry clamping the live
  s/t loops by a float floor window derived from `fmin_scaled`; keep the
  full-grid walk.  `R_AddDynamicLights_C` remains the reference.

## Priority-ordered next steps

1. Reproduce the current `-O3` default three-run `demo1` timedemo
   (15.484108 FPS median, checksum `4154140932`,
   `out\dos-timedemo-20260915-211623`) before further edits.
   `timedemo-dos.ps1` does **not** rebuild an existing `qbench.exe`; run
   `build-dos.ps1 -Benchmark` first after source changes, then
   `-SkipBuild` for the timedemo.
   **DPMI note (2026-09-15):** HDPMI32 as a CWSDPMI alternative was tested
   with engine unchanged (`DPMI-HDPMI32.md`).  It runs and probes as vendor
   `HDPMI` 3.20, but every timedemo failed checksum `2955717646` vs
   known-good `4154140932`.  Keep CWSDPMI; do not promote HDPMI32.
   Do not retry turbulent sstep/tstep/pbase stack hoisting
   (`out\dos-timedemo-20260915-091357`; ~17 ms slower).
   Do not retry both-edges leading precompute before `TrailingEdge`
   (`out\dos-timedemo-20260915-094223`; ~1.7 ms slower).
   Do not retry TrailingEdge `movl %ecx,%edx` CSE (noise); the direct-`%ecx`
   unlink is kept.  Do not retry DrawSpans8 aspancount register CSE.
   Do not restore ScanLeftEdge or EmitEdge discarded pretouch loads.
   Do not restore the EmitEdge `r_pedge` preload into `%esi`.
   Do not retry Span16 FILD-overlapped v/u dest loads
   (`out\dos-timedemo-20260915-103436`; noise).
   Do not retry leading spanstate-before-insubmodel reorder
   (`out\dos-timedemo-20260915-110203`; noise).
   Do not restore load/add/store for `r_bmodelactive` on the bmodel path.
   Do not retry EmitEdge owner-store into FDIV shadow
   (`out\dos-timedemo-20260915-112708`; noise).
   Do not retry PolysetCalcGradients s/t step CSE
   (`out\dos-timedemo-20260915-113155`; tied).
   Do not restore the unused clipped-path `r_pedge` load.
   Do not restore load/decl/store for TrailingEdge `spanstate`.
   Do not retry TrailingEdge `st_next` hoist for `LNoEmit`
   (`out\dos-timedemo-20260915-120218`; noise).
   Do not restore leading `incl`+%edx store for known-zero spanstate.
   Do not restore EmitEdge `edge_p` load before the horizontal early-out.
   Do not retry leading `surfaces[1].next` defer past inverted early-out
   (`out\dos-timedemo-20260915-123249`; noise).
   Do not restore RecursiveTriangle stack reloads of `new[0]`/`new[1]`.
   Do not restore Aff8 `xorl`+`movb` colormap index formation.
   Do not restore FinalVerts `movb`+`andl $0x00FF` skin texel load.
   Do not restore DrawSubdiv `d_pcolormap` setup under the FPU cull.
   Do not restore Aff8 one-long `ptex` load before the Z test.
   Do not retry particle `pt_color` defer past Z
   (`out\dos-timedemo-20260915-135449`; noise).
   Do not restore RecursiveTriangle `lp2[0]` load before the equal-`y` test.
   Do not restore RecursiveTriangle next-edge prefetches before `|dy|` split.
   Do not restore RecursiveTriangle y loads before `|dx|` early-out.
   Do not retry Aff8 `pz`/`zi` hoist before one-long vs multi
   (`out\dos-timedemo-20260915-151700`; noise).
   Do not retry `Spr8Entry2_8` dead texel preload removal
   (`out\dos-timedemo-20260915-152226`; noise).
   Do not retry InsertNewEdges `LAddedge2` fallthrough unify
   (`out\dos-timedemo-20260915-152701`; ~4.2 ms slower).
   Do not restore StepActiveU `et_prev`/`et_next` loads before the
   `edge_aftertail` early-out.
   Do not retry InsertNewEdges four-probe `et_next` defer with `jle`+`jmp`
   (`out\dos-timedemo-20260915-154519`; noise); keep probes 1–3 only.
   Do not restore InsertNewEdges `et_next` before the first three
   `et_u` early-outs.
   Do not restore StepActiveU `LPushBackLoop` `et_prev` before the first
   `et_u` early-out.  Do not extend that deferral to probe 2 with
   `jnl`+`jmp` (same trap as the four-probe InsertNewEdges form).
   Do not retry RecursiveTriangle `lp2[1]` live-keep via `leal` for nodraw
   (`out\dos-timedemo-20260915-161932`; noise).
   Do not restore EmitEdge `r_framecount` load before the `cacheoffset`
   `0x7FFFFFFF` early-out on `LPop5AndDone`.
   Do not restore StepActiveU step-loop `et_next` before order early-outs
   on probes 1–3.  Do not add a probe-4 `jl`+`jmp` form.
   Do not retry particle rect-edge load defer past clip early-outs
   (`out\dos-timedemo-20260915-170311`; noise).
   Do not restore RemoveEdges `%ebx` push or the odd-tail `Lre_done`
   second-store path.
   Do not restore FinalVerts dword light load/`andl $0xFF00`/`addl` for
   the colormap index.
   Do not retry sprite `D_SpriteDrawSpans` v/u CSE across Z/dest setup
   (`out\dos-timedemo-20260915-172816`; noise).
   Do not restore leading first-key `movl st_key(%esi),%ecx` before
   `cmpl` (`Lgs_leading` / `Lbmodel_leading`).
   Do not restore RecursiveTriangle `LDraw` stack reloads of `new[0]`/
   `new[1]` (keep live `%edx`/`%ebp` from midpoint; equal-y uses `%eax`
   for `lp2[0]`).
   Do not restore sort-loop `movl st_key(%esi),%ecx` before `cmpl`
   (`Lsortloopnb` / `Lsortloop`).
   Do not retry EmitEdge defer `r_ceilv1` past `r_nearzionly`
   (`out\dos-timedemo-20260915-181715`; ~20 ms slower).
   Do not restore Aff8 multi last-group stepper before `decw` exit
   (`Lp8`).
   Do not restore InsertNewEdges `movl et_u→%ebx` before `cmpl`.
   Do not restore `LPushBackLoop` `movl et_u→%ebx` before `cmpl`.
   Do not retry leading inverted `Lxl_done` memory `incl` spanstate
   (`out\dos-timedemo-20260915-185246`; noise).
   Do not restore TrailingEdge `st_last_u` preload before the `LNoEmit2`
   early-out.
   Do not retry particle NxN `%esi` push removal / `%eax` z-stride
   (`out\dos-timedemo-20260915-195244`; noise).
   Do not restore ScanLeftEdge last-row Bresenham step after the final
   package (`decl`/`jz` before step is kept).
   Do not retry Aff8 DrawSpans8 last-span right-edge Bresenham skip
   (`out\dos-timedemo-20260915-201944`; ~19.5 ms slower).
   Do not restore StepActiveU `movl et_u_step→%ebx` before `addl`.
   Do not restore leading `Lnewtop` `st_last_u` preload before the
   `LInsertAndExit` early-out.
   Do not retry `Lgs_lastspan` memory `cmpl st_last_u`
   (`out\dos-timedemo-20260915-204034`; ~4.3 ms slower).
   Do not restore EmitEdge `movl r_ceilv1→%ecx` before the horizontal
   `cmpl`/`jz`.
   Do not restore RecursiveTriangle `movl lp2→%edx` before midpoint
   `addl` for new[2]/new[3]/new[5].
   Do not restore EmitEdge u-clamp `movl` of vrect bounds before `cmpl`.
   Do not restore EmitEdge `movl C(surfaces),%esi` before the LSide1/LSide0
   `surface_p - surfaces` sub; the memory form and explicit sort-side
   `movl` are kept.
2. Texture spans remain ~26.2% self time (`out\dos-timedemo-20260911-184157`,
   diagnostic).  Dest rows now come from
   `viewspantable` in the 16/8-pixel drawers, polyset, sprites,
   particles, and live `Turbulent8`.  Live `D_RasterizeAliasPolySmooth`
   dest and Z rows use the same tables.  Keep the unrolled 16-pixel leaf; dword coalescing was
   noise and a compact stosb loop was ~2.8% slower.  Remainder t-zero
   IMUL skip and a per-surface source-row table both matched the
   checksum but lost end-to-end; do not retry those.  Do not revive
   the earlier checksum-failing texture-source row-lookup.  Do not
   retry a jump table around the turbulent last-segment divide.
   Do not retry a per-surface `d_drawspans == D_DrawSpans16`
   compare/direct CALL.  The start-address `cachewidth` IMUL sits in
   the FDIV shadow; do not add per-span branches to skip it.
   Do not retry `D_DrawSpans16` s/t integer CSE across the sfrac/tfrac
   shifts (`out\dos-timedemo-20260915-074041`; ~43 ms slower) or early
   `pnext` preload into `pspantemp` (`out\dos-timedemo-20260915-075512`;
   noise).  Do not retry `D_DrawSkyScans8` `viewspantable` dest rows
   (noise vs the aspancount default).  Do not retry FILD-overlapped
   v/u loads for dest setup.
3. Surface-cache rebuilds were ~14.5% at 600 KB.  The default cache is
   now 1800 KB; 1200 KB also matched the checksum.  1900 KB, 2000 KB,
   2100 KB, and 2400 KB all failed checksum `2955717646`.  Do not
   retry those sizes.  Do not add another predicate helper.  Static
   textures now skip `R_TextureAnimation` and `r_drawsurf` stores on
   a hit, and unused extra light styles are skipped when
   `styles[1] == 255`.  No-dlight invert/clamp is fused
   into the lightmap write for 1--4 styles, and `R_AddDynamicLights` now
   uses an integer distance.  Per-column wrap uses AND on power-of-two
   widths.  Direct mip drawers were 1.1 ms slower end-to-end; leave
   `(*pblockdrawer)()`.  Live `surf8.s` mip0 already uses `movl` dest
   packs; `block8.h` is unused.    Rebuild setup now skips the 16-bit
  `r_pixbytes` path and reuses `r_stepback` for `r_sourcemax`.
  Do not retry folding the soffset wrap into the column-loop POT test.
  Rebuilds no longer compute unused `surfscale` / `cache->mipscale`.
  Do not skip storing `blocksize`; the 8-bit column loop uses it for
  `soffset`.  Do not retry a local `mip` for `R_DrawSurface` setup.
  `R_MarkLights` now applies the `R_AddDynamicLights` plane reject and an
  O(1) clamp-to-rect idist cull (replacing the earlier `fmin` AABB expand).
  Do not retry a full per-sample MarkLights scan; phantom faces would pay
  the nested loop.  Do not retry a 2x2 discrete sample scan in
  `R_MarkLights`; it matched the checksum but was 112.5 ms slower.
  Do not retry an `R_AddDynamicLights` s/t sample-window clamp; it failed
  checksum `696680082`.  `cache->dlight` now tracks real sample adds via
  `r_dlight_contributed`.  Marked frames with a clean cache also probe
  `R_DlightContributes` before rebuilding.  Surface rebuild skips from the
  continuous-vs-discrete MarkLights gap are largely exhausted; do not add
  another surface-cache predicate helper or revive MarkLights sample scans /
  dlight loop windowing.
4. Alias leftover is now narrower polyset raster guts after the
   once-per-call `advancetable`/`tstep` hoist and left-edge s/t step CSE
   in `D_RasterizeAliasPolySmooth`.  RecursiveTriangle keeps live
   `new[0]`/`new[1]` through the pixel leaf, defers `lp2[0]` until
   equal-`y`, defers next-edge prefetches past `|dy|` split tests, and
   defers same-edge y loads past `|dx|` early-outs.  Aff8 leaves and
   FinalVerts use `movzbl` for the colormap index / skin texel.
   DrawSubdiv defers `d_pcolormap` until after the backface cull.
   Aff8 one-long defers `ptex` until after Z.
   Keep direct `addl C(a_sstepxfrac)` in the pixel loop; do not retry
   BSS `sstep` for that constant (`out\dos-timedemo-20260914-183707`;
   matched checksum but ~9 ms slower).  Do not retry local copies of
   right-edge Bresenham constants (`erroradjustup`/`down`, `ubasestep`,
   `d_countextrastep`) in the span prologue
   (`out\dos-timedemo-20260914-184757`; ~37 ms slower).
   Do not retry stack-live `d_aspancount`/`errorterm` for the outer
   `D_PolysetDrawSpans8` right-edge loop
   (`out\dos-timedemo-20260915-065310`; ~37 ms slower).
   Do not retry `d_ptexextrastep` via `a_ststepxwhole` with carry
   adjust/branches (`out\dos-timedemo-20260915-053730`; ~76 ms slower);
   keep `(sextra>>16)+(textra>>16)*skinwidth`.
   `D_PolysetDrawFinalVerts`
   hoists the viewmodel clip edges; C keeps the same locals as the live ASM.
   `D_RasterizeAliasPolySmooth` uses `viewspantable`/`zspantable`.
   `D_PolysetSetUpForLineScan` uses a 64x64 `adivtab` (`[-31,32]`); do not
   grow further without a timedemo win (D-cache cost).
   Do not retry an `AngleVectors` cache.
   Do not retry a branched POT skinwidth shift in `D_PolysetCalcGradients`.
   Do not retry hoisting `aliasvrect` locals in `R_AliasPreparePoints`.
   Do not retry hoisting `aliasvrect` / skipping Z reflag in `R_AliasClip`
   (`out\dos-timedemo-20260914-181813`; matched checksum but ~42 ms slower).
   Do not retry `movzbl` expansion in `R_AliasTransformAndProjectFinalVerts`.
   Do not retry fused `minmaxs` multiplies in `R_RecursiveWorldNode`.
   Do not retry stacking `acolormap` in `D_PolysetDrawFinalVerts`.
   Do not retry a last-used `D_CalcGradients` step-origin cache.
   Per-frame mipscale × `xscaleinv`/`yscaleinv`/`0x10000` tables are
   the kept substitute.  Do not retry precomputing
   `transformed_modelorg × mipscale` on world/bmodel switch.
   World faces now hoist `surfedges` and unroll the four clip-plane
   links in `R_RenderFace`.  Clipped bmodels hoist the same `surfedges`
   pointer.  Do not retry unrolling `R_RenderBmodelFace` clip planes.
   Do not retry hoisting `currententity->model` in `R_RenderFace`.
   Do not retry hoisting `r_pcurrentvertbase` in `R_RenderFace`.
   Do not retry length-1 or POT remainder in `R_AnimateLight`.
   Do not retry skipping no-op bmodel Restore/Set CALLs with extra
   per-surface ifs.  Do not retry duplicating world surface loops to
   hoist `r_drawpolys`.  Do not retry `skintable` start addressing in
   `D_RasterizeAliasPolySmooth`.     Do not retry a `D_PolysetScanLeftEdge`
   skinwidth stack hoist (`out\dos-timedemo-20260915-061218`; ~10 ms
   slower).  `D_PolysetScanLeftEdge` keeps `d_pedgespanpackage` in `%esi`
   and live `d_pdest`/`d_pz` in `%edi`/`%ebp` (light/zi/aspancount on
   stack), publishing the package pointer and writing back
   `d_aspancount` once on exit.  Do not restore the discarded package
   pretouch `movb`.  Z spans use `zspantable`
   and keep the span list in `%ebp` (no per-span push/pop of the list
   pointer); keep the count `pushl`/`popl` for the odd pixel.  Do not
   retry tagging `%ebp` bit0 to drop that count stack traffic
   (`out\dos-timedemo-20260915-060125`; ~65 ms slower).  Do not retry
   stack-hoisting `erroradjustup`/`down` or `errorterm` beside the
   kept aspancount spill in `D_PolysetScanLeftEdge`.  Do not retry
   `D_DrawSpans16` s/t integer CSE across the sfrac/tfrac shifts, early
   `pnext` preload into `pspantemp`, or `D_DrawSkyScans8`
   `viewspantable` dest rows (noise or slower).  Edge scan keeps the
   `Lgs_leading` `surfaces` CSE and TrailingEdge direct-`%ecx` unlink;
   `R_EmitEdge` loads `edge_p`/`r_pedge` only after the horizontal early-out
   (`leal` next pointer) and omits the unused fully-clipped `r_pedge` load;
   TrailingEdge uses memory `decl` for `spanstate`, skips `r_bmodelactive`
   when `insubmodel==0`, and uses `decl`/`incl` memory forms for bmodel
   enter/leave.  Leading non-inverted paths store `movl $1` for spanstate.
   Look for other dead reloads carefully before adding stack traffic.
   Do not revive BSP plane-dot/clip helpers.
   Face Z gradients are cached.

## Current implementation result

The current pass keeps the dynamic-light S-axis accumulator, the
`currententity`-keyed face Z-gradient cache, and changes `WinQuake/r_bsp.c`
to test a node's `visframe` before `CONTENTS_SOLID`, while both world-node
surface loops test `visframe` before the backface flag.  Predicate semantics
and recursion are unchanged.  In
`WinQuake/d_draw.s`, spans whose fixed-point `izistep` is zero now reuse the
same initial-Z/clamp calculation and fill the 16-bit depth words with
`rep stosw`; the normal positive/negative gradient paths are unchanged.  The
five-run node-order-plus-zero-step sample was `61.556987`, `61.556783`,
`61.556720`, `61.556934`, and `61.556789` seconds (969 frames and framebuffer
checksum `4154140932` each run), for a median `61.556783 s / 15.741564 FPS`
versus the committed zero-step baseline `61.559877 s / 15.740772 FPS`.  The full
`bench-dos.ps1` run reported `486 benchmark correctness PASS` with harness
checksum `2378409472`, and the smoke test passed.  In `WinQuake/d_polysa.s`,
the subdivided alias backface cull now uses the same 32-bit integer determinant
as `D_DrawNonSubdiv`, avoiding the x87 round trip for integer screen
coordinates.  The three-run candidate sample was `61.878873`, `61.496626`,
and `61.496717` seconds (969 frames and framebuffer checksum `4154140932` on
each run), for a median `61.496717 s / 15.756939 FPS`; the full correctness
harness also retained checksum `2378409472`.  The follow-up five-run sample
restoring `%edi` from the stable `r_affinetridesc.pfinalverts` field instead of
using a per-triangle stack pair was `61.487631`, `61.487324`, `61.487423`,
`61.487373`, and `61.487350` seconds, again with framebuffer checksum
`4154140932` on every run, for a median `61.487373 s / 15.759333 FPS`.
The follow-up Z-span first-pair `shldl`/`rorl` packing in both gradient signs
measured `60.901914`, `60.901634`, and `60.901646` seconds, with the same
969-frame framebuffer checksum on every run, for a median
`60.901646 s / 15.910900 FPS`.  The full correctness harness retained
checksum `2378409472`, and the rebuilt normal binary passed the DOS smoke test.

## Starting commands

Use a local, legally obtained `id1` directory containing `pak0.pak`:

```powershell
.\tools\build-dos.ps1 -Clean -Benchmark -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\smoke-dos.ps1 -SkipBuild -DataRoot 'C:\path\to\Quake\id1' `
  -TimeoutSeconds 90
.\tools\timedemo-dos.ps1 -DataRoot 'C:\path\to\Quake\id1' -Runs 3
```

For the direct C/ASM transform A/B, build each selected benchmark executable
and run the focused command with the matching selector:

```powershell
.\tools\build-dos.ps1 -Clean -Benchmark `
  -AliasTransformFinalImplementation c -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -AliasTransformFinalImplementation c `
  -DataRoot 'C:\path\to\Quake\id1'
.\tools\build-dos.ps1 -Clean -Benchmark `
  -AliasTransformFinalImplementation asm -NoBootstrap
.\tools\bench-dos.ps1 -SkipBuild -AliasTransformFinalOnly `
  -AliasTransformFinalImplementation asm `
  -DataRoot 'C:\path\to\Quake\id1'
```

The relevant source entry points are
`R_AliasTransformFinalVert` and
`R_AliasTransformFinalVert_asm486` in `WinQuake\r_alias.c` and
`WinQuake\asm486_experiments.s`.  Use `WinQuake\host_cmd.c` for the focused
benchmark harness and `tools\profile-report.ps1` for profile JSON.
