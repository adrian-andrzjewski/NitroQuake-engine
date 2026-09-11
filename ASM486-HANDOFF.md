# 486 ASM experiment handoff

This checkout is a DOS WinQuake/software-renderer preservation project.  The
purpose of the ASM work is experimental: compare small hand-written 486 paths
with the original C under the same DJGPP build and DOSBox-X workload, then
promote only changes that preserve the exact framebuffer and win the complete
timedemo.  This is a continuation note for the next agent; operational build
and run details remain in `BUILD-DOS.md`.

## Current state

The nested repository is the Git boundary: `D:\Project\486quake\quake`.
The current source uses the `aggressive` profile (`-O3 -march=i486`) and the
repository-owned `tools\dosbox-x-486-high.conf` profile (`cputype=486`, fixed
33445 cycles, DOSBox-X 2026.08.31, 16 MB).  The current default selections are:

- ASM: alias projection, alias bounding-box projection, clipped alias
  transform/lighting, texture-animation selection, and lightmap normalization.
- `stosb`: turbulent-span stores.
- `byte`: 16-pixel texture-span stores (dword pack and stosb-loop remain
  opt-in; both matched checksum `4154140932` but did not beat the unrolled
  leaf).
- C: memory helpers, texture-axis cache predicate, surface-cache predicate,
  mip-level selection, BSP plane-dot, and BSP frustum clipping.
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
  `d_zistep` values while `modelorg` is unchanged this frame.  The miss
  path is the original `TransformVector` / `1/z` arithmetic.
- Z spans: `D_DrawZSpans` ASM uses `zspantable` row bases instead of
  IMUL `d_zrowbytes`.  The C multiply path remains the reference.
- Texture spans: `D_DrawSpans16` / `D_DrawSpans8` ASM load dest rows from
  `viewspantable` (`d_viewbuffer + d_scantable[v]`, filled in
  `D_SetupFrame`).  Alias polyset, sprites, particles, and live
  `Turbulent8` dest rows use the same table.  C `D_DrawSpans8` still
  multiplies `screenwidth`.  `D_PolysetDrawFinalVerts` hoists the
  viewmodel clip edges into registers/locals; C matches the live ASM.
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

Every ASM candidate retains its C implementation.  `build-dos.ps1`,
`bench-dos.ps1`, and `timedemo-dos.ps1` expose independent `c|asm` selectors
and write separate ignored output directories when needed.  `out\` contains
generated executables, staged data, logs, JSON reports, and object files; it is
not source and must not be committed.

## Completed experiments and decisions

All focused runs used alternating C/ASM samples and ended with
`486 benchmark correctness PASS`; accepted paths also passed matched `demo1`
timedemos with 969 frames and framebuffer checksum `4154140932` on every run.
The percentages below are DOSBox-X evidence, not a claim about all physical
486 variants.

| Experiment | Focused result | Timedemo result | Decision |
| --- | --- | --- | --- |
| Texture-span setup (`d_draw16.s`) | Narrow address-arithmetic change | About 0.10% faster | Kept |
| Turbulent stores | Existing ASM 20.6--28.8% faster than C; `stosb` tied it in isolation | `stosb` 0.086207% faster than existing ASM | `stosb` default |
| Alias projection (`R_AliasProjectFinalVert`) | 7.316--7.317% faster | 0.017696% faster | ASM default |
| Texture animation (`R_TextureAnimationFrame`) | 1.052--31.999% faster | 0.009406% faster | ASM default |
| Lightmap normalization (`R_BuildLightMap`) | 9.447--9.969% faster | 0.0275% faster | ASM default |
| Alias bbox projection (`R_AliasCheckBBox`) | 16.667--20.120% faster | 0.0264% faster | ASM default |
| Clipped alias transform (`R_AliasTransformFinalVert`) | 20.000--25.218% faster | 0.150883% faster | ASM default |
| Memory helpers (`Q_memset`/`Q_memcpy`) | About 4.6--64.4% faster by case | 0.0208% faster | C default; ASM opt-in |
| Texture-axis predicate (`D_GetTextureAxes`) | 0.000% to -0.002% | Not promoted | C default |
| Surface-cache predicate (`D_CacheSurface`) | 3.846--5.000% faster | 0.030% slower | C default |
| Mip selector (`D_MipLevelForScale`) | Mixed: -8.697% to +7.143% | 0.0092% slower | C default |
| BSP plane dot (`R_RecursiveWorldNode`) | Mixed: -13.334% to +21.052% | 0.0367% slower | C default |
| BSP clipping (`R_RecursiveWorldNode`) | Mixed: -4.651% to +55.931% | 0.2749% slower | C default |
| Span16 dword stores (`d_draw16.s`) | Checksum pass | Median 68.958760 s vs 68.958817 s (noise) | `byte` default; `dword` opt-in |
| Span16 loop+stosb (`d_draw16.s`) | Checksum pass | 70.980641 s / 13.651610 FPS, ~2.8% slower | `byte` default; `loop` opt-in |
| Surface block `movw` (`block8.h`) | Checksum pass | Noise vs byte stores | Reverted |
| Surface wrap + cache guard + alias view matrix | Inlined, no new helper | 68.946370 s / 14.054401 FPS, 12.4 ms faster | Kept |
| Aggressive `-O3` vs `-O2` | Checksum pass; `+quit` smoke pass | 68.421397 s / 14.162237 FPS | **Default**; `-O2` is `-OptimizationProfile baseline` |
| Bmodel span rotation cache (`d_edge.c` / `R_RotateBmodelCached`) | Id per-polygon `sin`/`cos` FIXME | 68.379696 s / 14.170874 FPS, 41.7 ms faster | Kept |
| Fused first-style lightmap (`R_BuildLightMap`) | Ambient+style0 in one write pass | 68.309838 s / 14.185365 FPS, 69.9 ms faster | Kept |
| Fused one-style normalize (`R_BuildLightMap`) | Invert/clamp in the first write when there are no extra styles or dlights | 68.265779 s / 14.194521 FPS, 44.1 ms faster | Kept |
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
- Current default after skipping unused extra light styles
  (`out\dos-timedemo-20260911-154031`): `67.200635 / 67.200347 / 67.200437` s,
  median **67.200437 s / 14.419549 FPS**, checksum `4154140932`.  About
  18.2 ms faster than the FinalVerts hoist.  Worst-frame min FPS is
  6.321254.  Every run was faster than every previous-default run.

## Important decisions and assumptions

- Original C bodies stay intact as references; do not delete them to make ASM
  the only implementation.
- A focused microbenchmark win is not sufficient.  Require correctness,
  matched release timedemos, and a measured end-to-end gain before changing a
  default.
- Keep `-O3 -march=i486` as the measured default, the same DOSBox-X
  version/profile/cycles, demo, data, and command-line options for A/B
  comparisons.  Use `-OptimizationProfile baseline` for `-O2`.  Do not
  enable newer ISA requirements.
- Exact framebuffer checksum is the automated parity gate.  It does not prove
  complete visual or gameplay parity outside the timedemo.
- `R_AliasTransformFinalVert_asm486` uses static scratch labels in
  `asm486_experiments.s`; this is acceptable for the current single-threaded
  DOS renderer, but the helper is not reentrant.
- DOSBox-X timing is an emulated 486-class model.  No physical 486 measurement
  has been made, and only `demo1` has been used for the documented matched
  end-to-end comparisons.

## Failed or inconclusive work

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

## Priority-ordered next steps

1. Reproduce the current `-O3` default three-run `demo1` timedemo
   (14.419549 FPS median, checksum `4154140932`) before further edits.
   `timedemo-dos.ps1` does **not** rebuild an existing `qbench.exe`; run
   `build-dos.ps1 -Benchmark` first after source changes, then
   `-SkipBuild` for the timedemo.
2. Texture spans remain ~25.7% self time.  Dest rows now come from
   `viewspantable` in the 16/8-pixel drawers, polyset, sprites,
   particles, and live `Turbulent8`.  Keep the unrolled 16-pixel leaf; dword coalescing was
   noise and a compact stosb loop was ~2.8% slower.  Remainder t-zero
   IMUL skip and a per-surface source-row table both matched the
   checksum but lost end-to-end; do not retry those.  Do not revive
   the earlier checksum-failing texture-source row-lookup.  Do not
   retry a jump table around the turbulent last-segment divide.
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
   packs; `block8.h` is unused.  Next surface work is fewer remaining
   rebuilds without changing lit output.
4. Alias leftover is now the per-vertex clip tests and polyset raster, not
   the per-model view matrix.  `D_PolysetDrawFinalVerts` hoists the
   viewmodel clip edges; C keeps the same locals as the live ASM.
   Do not retry an `AngleVectors` cache.
   Do not retry a branched POT skinwidth shift in `D_PolysetCalcGradients`.
   Do not retry hoisting `aliasvrect` locals in `R_AliasPreparePoints`.
   Do not retry `movzbl` expansion in `R_AliasTransformAndProjectFinalVerts`.
   Do not retry fused `minmaxs` multiplies in `R_RecursiveWorldNode`.
   Do not retry stacking `acolormap` in `D_PolysetDrawFinalVerts`.
   Z spans now use `zspantable`; edge scan is already assembly.  Do not
   revive BSP plane-dot/clip helpers.  Face Z gradients are cached.

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
