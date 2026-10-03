# Span, alias and BSP micro-experiments (2026-09-28)

Extracted verbatim from `ASM486-HANDOFF.md` lines 3332-3997 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## Monster gib trail zero-XY experiment (2026-09-29)

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

> **Superseded 2026-10-02: the release value is `unroll16`, not `unroll4`.** These
> two sub-gate closures were bundled with `SurfaceBlockMip1IndexHoist=hoist` and a
> fully-flat mip-1 body and cleared the gate at 0.0620%; see the `surf8` promotion
> in ``2026-10-02-surf8-bundle-and-promotion.md``, under "`surf8` flat axis: three measured wins bundled". `build-dos.ps1` is the authority for the current default.
> The measurements below stand.

The mip-0 sixteen-row extension also remains opt-in. Five fresh alternating
runs measured 59.344220 seconds median for the four-row control and 59.335845
seconds for unroll16, a 0.0141% gain below the gate. All ten runs completed
969 frames with checksum `1047377823`; smoke and full correctness passed. Keep
`SurfaceBlockMip0Rows=unroll4` as the release value.

> **Superseded 2026-10-02: the release value is `unroll16`.** As above. Note this
> makes the `unroll8` entry immediately above obsolete as a *candidate* — it is a
> strictly worse variant of a change that is already promoted, so there is nothing
> left to bundle it with.

## Alias-span address-update experiment (2026-09-28)

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

## World-BSP frame-count cache experiment (2026-09-28)

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
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation control -TimeoutSeconds 600
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation local -TimeoutSeconds 600
.\tools\smoke-dos.ps1 -SkipBuild -NoBootstrap -BspFrameCountImplementation local -DynamicLightImplementation asm -TimeoutSeconds 180
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -BspFrameCountImplementation control
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -BspFrameCountImplementation local
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

## Texture-span address-update experiment (2026-09-28)

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

## Texture-span row-cross experiment (2026-09-28)

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

## Texture-span load-order experiment (2026-09-28)

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

## Alias-model prepare source-cursor experiment (2026-09-28)

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

## Texture-span tail-store experiment (2026-09-28)

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

The nested repository is the Git boundary: `workspace\quake`.
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
- Surface cache: `SURFCACHE_SIZE_AT_320X200` is `2400*1024` (was `1800*1024`;
  **raised 2026-09-29 — 0.0635% faster, checksum `1047377823`, and the
  "1900 KB and larger failed checksum `2955717646`" claim below is a
  confounded build, not a cache-size defect**).
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

