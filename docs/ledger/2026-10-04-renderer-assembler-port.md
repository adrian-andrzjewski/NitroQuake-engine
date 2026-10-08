# Pure-assembler renderer port: incremental progress

Status: ongoing. This entry records accepted incremental stages in the user-directed
port of NitroQuake's full DOS software renderer and its render-time dependencies.
The renderer is not yet fully ported.

## Renderer-port ISA correction (2026-10-06)

The later lightmap notes below say the C reference adds post-i486 multiply
instructions and report 167/168 above-i486 instructions. Those counts came from
the audit's incorrect classification of `IMUL r32,r/m32` (`0F AF`) as Pentium;
the Intel 80386 manual documents that form. The corrected audit reports zero
above-i486 instructions for the i486 release, benchmark, and instrumentation
objects. The cold-path `UD2` and dead `RDMSR`/`WRMSR` sites were also removed as
described in the corrected [ISA audit ledger](2026-10-03-isa-audit-and-i386-codepath.md).
The prior `-SkipIsaAudit` runs remain historical parity evidence, not current ISA
validation.

## `D_FillRect` is now an i486 assembly entry point

`src/asm486_experiments.s` now exports `D_FillRect` directly when
`FillRectImplementation=asm` is selected. The routine performs rectangle clipping,
destination calculation, and all row stores in 32-bit GNU assembler. It uses only
i486-safe instructions, including `MUL`, `REP STOSL`, and `REP STOSB`. Compile-time
layout assertions in `src/d_fill.c` protect the four `viddef_t` offsets used by the
assembly. The release build does not compile a C `D_FillRect` implementation in this
configuration; the C implementation remains available with `FillRectImplementation=c`
and as a benchmark oracle.

The benchmark parity mode compared C and assembly over eight full-buffer cases:
full-screen rows, negative-origin clipping, right/bottom clipping, aligned dword
rows, unaligned byte rows, the large-row path, and two no-op rectangles. All eight
checks passed. On five alternating samples of 256 full-screen fills at 320x200, the
C median was 0.178277 s and the assembly median was 0.155468 s, a 12.793% isolated
gain; both checksums were `40936960`.

The i486 build audit passed with no new above-target instructions. The assembly
configuration also passed DOS smoke and one full timedemo run: 969 frames,
framebuffer checksum `1047377823`, 59.160542 s. The single full-run timing is not a
repeatable end-to-end performance result; the isolated fill benchmark is the
evidence for this function. At present, `D_FillRect` is called only by the
`bench486` fill case, so this stage establishes the migration pattern and does not
claim a game-wide speedup.

## `D_DrawZPoint` is now an i486 assembly entry point

`src/asm486_experiments.s` now exports `D_DrawZPoint` when
`ZPointImplementation=asm` is selected. It reads the precomputed `zspantable`
row, performs the signed depth comparison, and writes the z value and palette
pixel. Its x87 conversion temporarily selects truncate-toward-zero for the C
float-to-int behavior, then restores the caller's control word. The C body is
still selectable with `ZPointImplementation=c` and remains available as the
benchmark oracle. Assembly is now the default after focused parity passed.

The DOSBox-X parity harness uses private scratch buffers because the benchmark
starts before a world view allocates renderer buffers. It checks nine depth and
comparison cases under all four x87 rounding modes, comparing both the z value
and pixel and verifying the control word is restored. All 36 cases passed. The
ISA gate passed with no new above-i486 instructions. No speed claim is recorded:
the source tree has no production call site for `D_DrawZPoint`.

## The active sky span pixel loop has a selectable i486 assembly path

`D_DrawSkyScans8` now calls `D_SkyDrawPixels_asm486` for its inner palette-sample
and store loop when `SkySpanImplementation=asm` is selected. The C span
projection, sky vector normalization, 32-pixel chunking, and interpolation
remain in C. The C loop remains selectable and is compiled as the benchmark
oracle when `BENCH486` is enabled.

The focused DOSBox-X benchmark compared 256 combinations of span length (1–32),
coordinates, and signed steps with zero pixel mismatches. Its five alternating
32-pixel measurements gave 0.214414 s for C and 0.213966 s for assembly (+0.209%
for this isolated helper). A full 969-frame assembly timedemo retained checksum
`1047377823` and ran in 59.160519 s. Compared with the previously recorded
59.160564 s single run, that difference is only 0.00008% and is not a
repeatable end-to-end performance result, so the C selector remains the
default. Both C and assembly release builds passed DOS smoke; the assembly
release ISA gate passed with 168 enforced above-i486 instructions, below the
170-instruction baseline.

## The sky scan span loop now has an i486 assembly path

`D_DrawSkyScans8_asm486` now handles espan traversal, 32-pixel chunking, fixed
point interpolation, destination addressing, and pixel sampling. The selectable
C core remains available as the reference. At this intermediate stage the
assembly loop called the shared C `D_Sky_uv_To_st_C` projection helper; the next
entry records completion of that remaining dependency.

The DOSBox-X harness compared the complete C and assembly scan paths using six
spans of lengths 1, 2, 31, 32, 33, and 65, eight view orientations, and all four
x87 rounding modes. All 32 framebuffer comparisons matched. Both release
selectors passed DOS smoke. The release assembly ISA audit passed with 167
enforced above-i486 instructions against the 170-instruction baseline. The
full timedemo produced 969 frames and checksum `1047377823` for both selectors;
C took 59.160532 s and assembly took 59.160688 s in the paired single samples.
That timing difference is below the promotion threshold, so C remains the
default while the conversion continues.

## `D_DrawSkyScans8` is now a complete i486 assembly entry point

`src/asm486_experiments.s` now owns the whole 8-bit sky scan: viewport and
sky-phase setup, span traversal, 32-pixel chunking, UV projection, x87 vector
normalization, fixed-point interpolation, destination addressing, and palette
sampling. The C scan and UV routines remain available under the C selector and
as benchmark references. The assembly path has no C projection or math helper
call.

The focused harness compared UV projection over 256 coordinate/rounding cases
and the complete scan over 32 viewport/orientation/rounding cases; all outputs
matched, and the x87 control word was preserved. C and assembly release smoke
passed. The full DOSBox-X `demo1` workload completed 969 frames with checksum
`1047377823` for both selectors: C 59.160580 s and assembly 59.160539 s. These
are single full-run samples and show no end-to-end timing change. The C selector
remains the default while conversion continues. The assembly release ISA gate
passed with 167 enforced above-i486 instructions against the 170-instruction
baseline.

## `D_WarpScreen` is now a selectable i486 assembly entry point

With `WarpScreenImplementation=asm`, the C `D_WarpScreen` body is omitted from
that build. `src/asm486_experiments.s` owns the routine's local lookup arrays,
ratio setup, x87 time-phase conversion, row and column table generation,
destination calculation, and four-pixel copy loop. The table and pixel helpers
use 486-safe integer instructions. `WarpScreenImplementation=c` retains the
complete original C function as the reference and default.

The focused DOSBox-X harness checked 1,024 row/column table cases across four
x87 rounding modes and 1,024 pixel-copy width/height cases, including padded
four-byte tail stores; all matched. Five alternating 320x200 measurements of
20 iterations gave a C pixel-loop median of 0.279925 s and an assembly median
of 0.240929 s (+13.931%). The table builder measured 0.003984 s in C and
0.004296 s in assembly (7.825% slower), so the isolated pixel-loop gain is not
a reason to change the default.

Both release selectors passed DOS smoke. The assembly release ISA audit passed
with 170 enforced above-i486 instructions against a 173-instruction gate
baseline; none came from the new WarpScreen assembly. On this revision's
full-run parity check, C completed 969 frames in 59.160583 s and assembly in
59.160565 s; both produced checksum `1047377823`. The earlier three-pair
median comparison also remained within 0.00006%, far below the 0.05% promotion
threshold. C therefore remains the default.

## `D_DrawSolidSurface` now has a selectable i486 assembly path

With `SolidSurfaceImplementation=asm`, `src/asm486_experiments.s` exports the
public `D_DrawSolidSurface` entry and traverses the surface's span list directly;
the ASM build omits the C body. It preserves the C routine's distinct short-span
dword pattern, byte tails, low-byte memset behavior for spans of 16 pixels or
more, and profiling span count. The C function remains selectable and is
compiled as the benchmark oracle.

The DOSBox-X harness compared the complete 8-row scratch framebuffer after
48 span operations covering lengths 1, 2, 7, 8, 9, 15, 16, 17, 31, 64, 0, and
-1, with four colors including values whose C dword pattern differs from a
repeated byte. It found zero mismatches. Five alternating samples of 100,000
calls over 12 spans measured a C median of 1.917079 s and assembly median of
1.818770 s (5.128% faster in this isolated workload). Both release selectors
passed DOS smoke and the pinned timedemo; each retained 969 frames and checksum
`1047377823` (C 59.160645 s, assembly 59.160535 s). The routine is used by the
optional `r_drawflat` path, so the timedemo does not exercise it. Keep C as the
default until a representative renderer workload measures the active path. The
release assembly ISA audit passed with 168 enforced above-i486 instructions
against the 170-instruction baseline.

## The `Turbulent8` scan setup and interpolation now have a selectable i486 assembly entry point

`TurbulentScanImplementation=c|asm` now selects the complete `Turbulent8`
scan path, with C remaining the default and reference. The direct assembly
entry handles phase selection from `cl.time`, projection setup, espan traversal,
destination addressing, 16-pixel chunking, fixed-point interpolation, and the
short final chunk. Its x87 conversions preserve C's truncation behavior and
restore the caller's control word. The selected turbulent pixel-store loop
remains independently controlled by `TurbulentImplementation`.

The focused DOSBox-X harness compared framebuffer output and changed renderer
state for 13 span counts (including zero and negative values), six positive,
negative, and boundary `cl.time` phases, and all four x87 rounding modes. All
cases passed with the default `stosb`, existing ASM, and C inner loops.
`D_DrawTurbulent8Span_asm486` also now uses signed `jg` after decrement, which
matches the C `while (--count > 0)` termination for zero and negative counts.

Both C and assembly release builds passed DOS smoke. The assembly release ISA
gate passed with 168 enforced above-i486 instructions against the 170-instruction
baseline; the new scan code added none. Three C timedemos completed 969 frames
with checksum `1047377823` in 59.160556, 59.160487, and 59.160559 s (median
59.160556 s). Three assembly timedemos retained the same frame count and
checksum in 59.126700, 59.126680, and 59.582721 s (median 59.126700 s). The
nominal median difference is 0.057%, but these were separate, unpaired runs and
the third assembly run is an outlier. Keep C as the default until alternating
timedemos establish a repeatable gain.

## `R_BuildLightMap` now has a selectable i486 assembly dispatcher

`LightMapBuildImplementation=c|asm` selects the complete surface-level
`R_BuildLightMap` dispatcher. The assembly entry calculates the lightmap bounds,
handles fullbright and missing-lightdata clears, rebuilds and consumes the cached
single-style invert/clamp table, selects the 2–4-style fused path or generic style
path, dispatches dynamic lights, and normalizes the accumulated values. The C
dispatcher remains the release default and is retained as `R_BuildLightMap_C` in
benchmark builds. The existing style, fused-style, dynamic-light, and normalization
selectors still independently choose their C or assembly helpers.

The DOSBox-X parity harness passed 11 scenarios: positive and negative fullbright,
missing world lightdata, ambient fill without samples, cold and warm single-style
cache, 2/3/4-style paths, an active frame with no dynamic-light bits, and a real
dynamic light. It passed with both the default assembly helpers and all four C
helper selectors. The C-helper comparison build used the report-only ISA option:
the preserved C reference adds post-i486 multiply instructions to that
benchmark-only profile, so it is parity evidence rather than a candidate build.
The default C and selected assembly release builds both passed DOS smoke; the
assembly release ISA gate passed with 167 enforced above-i486 instructions against
the 170-instruction baseline.

One pinned `demo1` run per dispatcher completed 969 frames with checksum
`1047377823`: C took 59.160698 s and assembly took 59.163269 s. These separate
single runs are not a performance comparison. C remains the default while the full
renderer port continues.

## `R_AddDynamicLights` orchestration and projection now have selectable i486 assembly

`DynamicLightOrchestrationImplementation=c|asm` selects the sparse
`surf->dlightbits` traversal and per-light dispatch. The assembly path uses `bsf`
to visit only set light bits, keeps surface extents and contribution state in a
small local frame, and dispatches to the independently selected C or assembly
sample loop. Its `R_AddDynamicLightProject_asm486` helper now handles the x87
plane and texture dot products, radius and minlight rejection, ceiling distance
limit, float-to-integer conversions, and nearest-surface cull. The C projection
and orchestration references remain in benchmark builds; C remains the release
default.

The direct projection harness compared float bit patterns, integer coordinates,
distance limits, and reject results across nine cases and all four x87 rounding
modes; all 36 comparisons passed. The 11-case lightmap harness passed with both
the assembly texel loop and its C reference. The C-sample profile is parity-only
and used `-SkipIsaAudit` because its C reference emits post-i486 multiply
instructions. The selected assembly release build passed DOS smoke and the i486
ISA gate with 168 enforced above-i486 instructions against the 170-instruction
baseline. The default C release build also passed DOS smoke.

One pinned `demo1` run for each orchestration completed 969 frames with checksum
`1047377823`: C took 59.160561 s and assembly took 59.160546 s. These separate
single samples are not a performance comparison; C remains the default.

## `R_DlightContributes` now has a selectable i486 assembly entry

`DlightContributesImplementation=c|asm` selects the sparse surface-light
predicate used by `D_CacheSurface`. The assembly path walks the set bits with
`bsf`, reuses the assembly x87 projection helper, clamps the nearest sample on
each texture axis, and applies the same integer distance threshold as the C
predicate. `R_DlightContributes_C` remains the benchmark reference, and C remains
the release default.

The direct harness compared the C and assembly projection outputs and predicate
results for nine light/surface cases under all four x87 rounding modes; all 36
cases passed. The accompanying 11-scenario lightmap dispatcher harness also
passed. Both the default C selector and the assembly selector passed DOS smoke;
the assembly build passed the i486 ISA gate with 168 enforced above-i486
instructions against the 170-instruction baseline. A pinned assembly timedemo
completed 969 frames in 59.163976 s with checksum `1047377823`. This is a single
correctness run, not evidence to promote the selector.

## The `D_CacheSurface` miss handoff now has i486 assembly paths

`SurfaceCacheImplementation=c|asm` selects the existing assembly cache-hit
predicate, key/setup/tag helpers, the allocator, and miss handoff.
`D_CacheSurfaceKeys_asm486` stages the animated texture pointer and resolves the
four light-style values into `r_drawsurf`; `D_CacheSurfaceSetup_asm486` sets the
miss-path mip, width, rowbytes, and height; and `D_CacheSurfaceStoreTags_asm486`
copies the texture and four style values into the cache entry. `D_SCAlloc_asm486`
owns allocator validation, rover wrap, owner invalidation, adjacent-block
reclamation, remainder splitting, and cache-thrash state; its C reference is
retained in benchmark builds. `D_CacheSurfaceAttach_asm486` attaches new blocks
and supplies `surfdat`; `D_CacheSurfaceDispatch_asm486` sets `drawsurf.surf`,
increments `c_surf`, and calls `R_DrawSurface`; and
`D_CacheSurfaceSetDlight_asm486` preserves the sticky contributed-light rule.
Compile-time C layout checks pin the structure offsets used by these entries,
and C references remain available in benchmark builds. At this helper-only
stage C still owned the public cache hit/miss flow; the following entry moves
that orchestration to assembly.

The focused surface-cache harness passed the existing cache hit/miss comparisons,
eight complete `drawsurf_t` parity cases across mip levels 0–3 and varied
extents, whole-cache tag parity, a seven-allocation sequence covering reclaim,
split, wrap, owner invalidation, and thrash, plus attachment/tag parity across
four mip slots and four dynamic-light states. Five-sample microbench medians at 500,000
iterations were 0.598076 s C / 0.568170 s ASM for a hit, 0.388750 s / 0.373801 s
for a texture miss, and 0.299038 s / 0.284088 s for a dirty-cache miss. These
time only the cache predicate and do not establish a full `D_CacheSurface`
speedup. The selected assembly release build passed DOS smoke and the i486 ISA
gate with 168 enforced above-i486 instructions against the 170-instruction
baseline. A pinned timedemo completed 969 frames in 59.257651 s with checksum
`1047377823`; this single run validates output but does not establish a speedup.

## `R_DrawSurface` now has a selectable i486 assembly entry point

`SurfaceDrawImplementation=c|asm` selects the full `R_DrawSurface` entry.
With `asm`, `src/asm486_experiments.s` owns the surface rebuild dispatch and
8-bit draw setup: it calls the independently selected `R_BuildLightMap`, sets
the surface row size, texture source and step limits, mip globals, and draw
dimensions, then handles POT and NPOT texture wrapping while walking the
surface columns. It selects the mip drawer once and directly calls the existing
`R_DrawSurfaceBlock8_mip0..3` assembly loops. C remains the release default;
the original body is retained as `R_DrawSurface_C` for benchmark comparisons.

The focused DOSBox-X parity harness compared complete output scratch data,
`blocklights`, and renderer scratch globals over 40 cases: four mip levels,
POT 64x64 and NPOT 60x44 textures, and five lightmap modes (fullbright,
missing lightdata, ambient, one style, and four styles). All cases matched.
The selected assembly release build passed DOS smoke and the blocking i486 ISA
gate with 166 enforced above-i486 instructions against the 170-instruction
baseline. The pinned `demo1` timedemo completed 969 frames with checksum
`1047377823` in 59.172592 s. This single sample validates output but does not
establish a speedup; C remains the default. The PROFILE486 assembly build also
passed its instruction gate at 177 against a 177 baseline.

## `D_CacheSurface` now has a full selectable i486 assembly entry

`SurfaceCacheImplementation=c|asm` now selects the public `D_CacheSurface`
entry as well as its cache helpers. The assembly owns the texture-animation
call guard, style-key staging, cache hit/miss decision, surface metadata setup,
allocation handoff, attachment, cache-tag writes, draw dispatch, and sticky
dynamic-light update. The selected `R_TextureAnimation` function still resolves
animation frames, and PROFILE486 timing/counter updates use C helpers. The C
entry is retained as `D_CacheSurface_C` in benchmark builds; `c` remains the
release default.

The focused DOSBox-X cache harness passed four complete public-entry cache hits
across mip levels 0–3, comparing return pointers, `r_drawsurf`, and cache/surface
state. The helper harness also passed eight setup/key cases, tag parity, seven
allocator operations, and attachment/light-tag parity. The full cache-miss and
draw path ran in the pinned `demo1` workload with both cache and surface-draw
selectors set to assembly: smoke passed, and the timedemo completed 969 frames
with checksum `1047377823` in 59.272887 s. This single sample validates output,
not a speedup. The release ISA gate passed at 165 enforced above-i486
instructions against the 170 baseline. The PROFILE486 combined build passed at
177 against its 177 baseline; its timedemo emitted profile data with 46,409
cache hits, 8,889 rebuilds, 2,710 allocations, and zero bad profile leaves.

## `R_TextureAnimation` now has a full selectable i486 assembly entry

`TextureAnimationImplementation=c|asm` now selects the public animation
wrapper. The assembly entry handles alternate-animation selection, the static
texture return, `cl.time * 10` conversion with truncation toward zero, signed
remainder, and frame interval traversal. It uses only i386/i486 integer and
x87 instructions, restores the caller's x87 control word, and keeps the C
wrapper and frame loop available as benchmark references. Compile-time layout
checks pin the texture, entity-frame, and client-time offsets used by assembly.

The focused DOSBox-X harness matched C across 25 time values for primary and
alternate animation plus the static fast path, under all four x87 rounding
modes; it also verified control-word preservation. The complete-entry median
was 1.121383 s for C and 1.091483 s for assembly over 500,000 calls, a 2.666%
microbenchmark improvement. The release build passed DOS smoke and the i486
ISA gate with 168 enforced above-i486 instructions against the 170 baseline.
The pinned `demo1` timedemo completed all 969 frames with checksum
`1047377823` in 59.160511 s. This single run confirms output parity and is not
a performance comparison. `asm` remains the configured selector default.

## `D_MipLevelForScale` now exports its public i486 assembly entry directly

With `MipLevelImplementation=asm`, `src/asm486_experiments.s` now exports
`D_MipLevelForScale` itself at the x87 threshold routine. The selected build no
longer keeps a C forwarding function around the assembly helper. The complete
C implementation remains selectable, and benchmark builds keep
`D_MipLevelForScale_C` as the reference. The `asm` selector also remains
independent of the other renderer selectors.

The focused DOSBox-X harness checked the public symbol against C for eight
threshold, between-threshold, and minimum-mip clamp scenarios; all matched.
The existing five-sample helper microbenchmark is mixed across branches, so C
remains the release default. The assembly release passed smoke and the i486
ISA gate with 168 enforced above-i486 instructions against the 170 baseline.
The pinned timedemo completed 969 frames with checksum `1047377823` in
59.168276 s. This single sample validates output, not a speedup.

## `R_SetSurfaceZGradients` now has a selectable i486 assembly entry

`SurfaceZGradientImplementation=c|asm` selects the per-face 1/z gradient
routine. The assembly entry keeps the plane/entity/frame cache, calls the
existing `TransformVector` assembly routine on misses, and calculates the three
gradients with the C compiler's x87 operation order and extended-precision
intermediates. The C function remains the release default and is available as
`R_SetSurfaceZGradients_C` in benchmark builds.

The focused DOSBox-X harness compared the full surface record across eight
plane/cache-key cases in all four x87 rounding modes. It covered cache hits,
plane changes, frame changes, and entity changes; all 32 cases matched, and
both paths preserved the control word. The assembly release passed smoke and
the i486 ISA gate with 168 enforced above-i486 instructions against the 170
baseline. The pinned `demo1` timedemo completed 969 frames with checksum
`1047377823` in `59.177824 s`. This single timing sample confirms output, not a
speedup. C remains the release default.

## `D_CalcGradients` and texture-axis caching now have an i486 assembly path

`SurfaceGradientImplementation=c|asm` selects the gradient routine. The
assembly path owns a separate texture-axis cache sized by
`TextureAxisCacheEntries` and the x87 math; it calls the existing
`TransformVector` assembly routine only on a cache miss. A separate
cache keeps the benchmark C reference independent, and benchmark builds retain
`D_CalcGradients_C`. The release default remains C.

The focused DOSBox-X harness matched every output float and fixed-point bound
for 20 cases across all four x87 rounding modes. It covered mip levels 0
through 3, a repeated-key hit, and texinfo/entity/frame key changes. It also
passed with the configured cache size set to 64 entries. The
assembly path preserves the caller's x87 control word and uses the same
temporary truncate mode as the C compiler's float-to-integer conversions.
Release smoke passed; the i486 ISA gate reported 168 enforced above-i486
instructions against the 170 baseline. The pinned `demo1` timedemo completed
969 frames with checksum `1047377823` in `59.120912 s`. This single timing
confirms output parity and is not a speed comparison.

A `PROFILE486` timedemo also completed all 969 frames with the same checksum.
It recorded 58,049 gradient calls, 46,884 texture-axis cache hits, and 11,165
misses. The 79.897272-second instrumented duration is attribution evidence,
not a release timing.

## `D_DrawSurfaces` now has a selectable i486 assembly dispatcher

`SurfaceDispatcherImplementation=c|asm` selects the full per-frame surface
dispatcher. The assembly path owns the surface-stack loop, mip-scale table
setup, draw-flat branch, sky/background/turbulent/textured selection, Z-gradient
loads, and brush-model/world-state transitions. Layout assertions in `d_edge.c`
guard the structure offsets used by the assembler. The existing C dispatcher is
still selectable and remains the benchmark reference; C remains the release
default.

The assembly dispatcher calls the existing independently selectable cache,
gradient, mip, sky, solid-surface, turbulence, texture-span, and Z-span routines.
This makes the dispatcher itself assembly while leaving the larger render-time
dependency closure and world/BSP traversal as open work.

The first DOSBox-X run exposed two pointer-value mistakes: the surface-cache
`data[0]` tail needs the cache address plus its compile-time offset, and
`transformed_modelorg` needs its array address when restoring world state. Both
assembly operands now use `LEA`. With those fixes, the release assembly build
passed the i486 ISA gate with 168 enforced above-i486 instructions against the
170 baseline, and DOS smoke passed. The pinned timedemo completed 969 frames
with checksum `1047377823` in 59.208935 s. This single timing validates output,
not a performance gain.

## The clipped alias vertex-preparation loop now has an i486 assembly selector

`AliasPrepareImplementation=control|local|asm` keeps both C loop variants and
adds an i486 assembly loop for `R_AliasPreparePoints`' clipped-vertex pass. The
assembly owns transform-helper dispatch, near-plane classification, projection
dispatch, viewport clip-flag accumulation, and publication of the advanced
`r_apverts` cursor. Transform and projection remain independently selectable;
the triangle clipping and draw loop still use C.

The selector contract passed, DOS smoke passed, and the selected build passed
the configured i486 ISA gate with 168 enforced above-i486 instructions against
the 170 baseline. Under the pinned DOSBox-X profile, the control and assembly
loops each completed 969 `demo1` frames with checksum `1047377823`. Their single
timings were `59.170288 s` and `59.196908 s`; this is not a repeatable
performance comparison, so C remains the default.

## Alias polygon clipping now has i486 assembly paths

`AliasClipImplementation=c|asm` selects the generic Sutherland-Hodgman pass
used by alias triangles and the triangle-level clipping orchestration. The
generic assembly pass classifies each edge, skips edges wholly outside the
active plane, calls the selected interpolation callback for crossings,
rebuilds viewport clip bits on generated vertices, and copies complete
`finalvert_t` records for inside points. The assembly triangle routine preserves
the C order for seam correction, auxiliary-vertex setup, Z/viewport passes,
final clamping, and clipped-fan dispatch. The C pass and triangle routine remain
available in benchmark builds as references. `AliasClipZImplementation=c|asm`
selects the Z-plane callback separately and requires `AliasClipImplementation=asm`;
the C callback remains available to the benchmark reference. `D_PolysetDraw`
remains its existing implementation. Compile-time layout checks pin the 32-bit
`finalvert_t`, `auxvert_t`, `mtriangle_t`,
`affinetridesc_t`, and `refdef_t` fields used by the assembly path.

The selector contract passed, the assembly release passed DOS smoke, and the
i486 ISA gate reported 168 enforced above-i486 instructions against the 170
release baseline. The benchmark build reported 172 against its 173 baseline.
Under the pinned DOSBox-X profile, three C runs and three assembly runs each
completed 969 `demo1` frames with checksum `1047377823`. The C times were
`59.170261`, `59.170324`, and `59.170302 s`; assembly times were `59.373774`,
`59.373909`, and `59.373939 s`. Since these were grouped by selector, the timings
are not a paired performance comparison; C remains the default. The supplied
missing-wall and vertex-artifact report is still unresolved. The prior exact-frame
display-page comparison covered the wall selectors before this triangle-level
change and did not reproduce the screenshot, so visual acceptance remains open.

The first Z-callback attempt exited without Quake writing `timedemo.txt`
(`out\dos-timedemo-20261005-161028`). Its object disassembly showed that the
assembly callback called the C projection routine even though the selected
alias-project implementation was assembly. The selector table now passes
`ASM486_ALIAS_PROJECT` to assembler sources, and the Z callback has its own
opt-in selector. The selector contract passed; the release passed smoke and its
i486 ISA audit reported 168 enforced above-i486 instructions against the 170
baseline. The benchmark audit reported 172 against 173. With both alias clip
selectors set to assembly, `demo1` completed 969 frames in `60.371758 s` with
checksum `1047377823`. This single sample is slower than the C Z-callback
fallback sample, so C remains the default. The supplied missing-wall and vertex
artifact report still needs matched-frame visual acceptance.

## Next work

Continue through the remaining render-time dependency closure, including alias
gradient setup. The generic alias clip pass, triangle orchestration, and
Z-plane intersection callback now have selectable assembly paths. The surface
dispatcher, world
walk, world-render setup, brush-model paths, and edge orchestration now have
selectable assembly entries, but the complete renderer still contains C paths.
Keep C references selectable and retain exact output, smoke, and the i486
instruction gate as acceptance requirements for each stage.
