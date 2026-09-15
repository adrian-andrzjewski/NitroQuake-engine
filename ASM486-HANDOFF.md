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
  IMUL `d_zrowbytes`.  The span list cursor lives in `%ebp` so the pack
  loop can scratch `%esi` without push/pop per span.  The C multiply
  path remains the reference.
- Edge scan: `R_GenerateSpans` / `Lgs_leading` reuses the live
  `surfaces` pointer in `%eax` instead of reloading it before the leading
  surface add.  `Lnewtop_fpop2` no longer loads a dead `st_key` into
  `%eax` before `Lnewtop` overwrites it.  `R_EmitEdge` omits the
  discarded next-edge pretouch loads on both leading and trailing sides,
  loads `edge_p` and `r_pedge` only after the horizontal early-out
  (`leal` for `edge_p+et_size` so CF from the ceil compare feeds the side
  test; no preload into `%esi`), and drops an unused `r_pedge` load on the
  fully-clipped both-points-out path (cacheoffset only).  `TrailingEdge`
  uses memory `decl` for `--surf->spanstate` (ZF test; inverted path
  needs no extra store), emit / `LNoEmit2` unlink with the already-loaded
  `st_next` in `%ecx` instead of reloading into `%edx`, skips the
  `r_bmodelactive` update when `insubmodel` is 0, and uses `decl`/`incl`
  memory forms for bmodel enter/leave (matching C's `++`/`--`).  Leading
  non-inverted paths store `movl $1` into `spanstate` (was 0) instead of
  `incl`+store; inverted `Lxl_done` still uses `incl`.
  `R_StepActiveU` `LPushBack` checks `edge_aftertail` before loading
  `et_prev`/`et_next` (matches C; every scanline's finish early-out
  skips two dead dword loads).
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
  `D_PolysetDrawFinalVerts` uses `movzbl` for the skin texel (drops
  `andl $0x00FF` before the light-shifted colormap add).
  `D_DrawSubdiv` sets `d_pcolormap` only after the backface cull (matches
  C; skips the store on culled triangles).
  `D_RasterizeAliasPolySmooth` reuses left-edge s/t base products for the
  extra-step path (`d_countextrastep = ubasestep + 1`).
  Live ASM `D_PolysetScanLeftEdge` keeps the package cursor in `%esi`,
  live `d_pdest`/`d_pz` in `%edi`/`%ebp`, and spills light/zi/aspancount
  on the stack (aspancount written back once on exit).  The discarded
  next-package cache pretouch `movb` is omitted; the first store after
  advancing `%esi` still touches the line.  `D_PolysetRecursiveTriangle`
  pixel leaf reuses live `new[1]`/`new[0]` in `%ecx`/`%ebp` from the Z
  setup (`movzbl` colormap index; no stack reloads).  Leading-edge nodraw
  loads `lp2[0]` only on the equal-`y` path.  Near-edge `|dy|` split checks
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
   (15.353497 FPS median, checksum `4154140932`,
   `out\dos-timedemo-20260915-153501`) before further edits.
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
