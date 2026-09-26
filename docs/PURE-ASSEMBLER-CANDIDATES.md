# Pure-Assembler Conversion Candidates

Date: 2026-09-26
Scope: i486 DOS WinQuake software renderer

## Conclusion

The highest-value parts to convert to pure 32-bit assembler are tight,
integer-heavy raster loops. The renderer does not benefit from converting the
entire engine or every C function. High-level orchestration, floating-point
setup, recursion, and pointer-heavy control flow should remain in C unless a
profile identifies a very specific hot path.

Recommended order:

1. The inner lightmap-combination loops in `R_BuildLightMap`.
2. The integer per-texel accumulation loop in `R_AddDynamicLights`.
3. Alias-model preparation, clipping, and gradient helpers.
4. Small surface-cache and dynamic-light predicate helpers.
5. Only then consider a larger BSP or face-setup conversion, and only if a
   pinned profile shows that one narrow helper is still dominant.

## Candidate areas

| Area | Location | Feasibility | Recommended boundary |
|---|---|---:|---|
| Lightmap combination | `WinQuake/r_surf.c:R_BuildLightMap` | High | Keep surface bounds and light-style selection in C. Move the per-texel style-combination loop to assembler. |
| Dynamic-light accumulation | `WinQuake/r_surf.c:R_AddDynamicLights` | High | Keep light projection and floating-point setup in C. Move the fixed/integer sample traversal and accumulation loop to assembler. |
| Alias setup | `WinQuake/r_alias.c:R_AliasPreparePoints`, alias clipping, gradient setup | Medium/high | Operate on compact vertex/clip arrays with explicit counts. Preserve the existing projection and clipping conventions exactly. |
| Surface-cache checks | `WinQuake/d_surf.c:D_CacheSurface`, `WinQuake/r_surf.c:R_DlightContributes` | Medium | Convert only the small predicates or copy/check loops; leave cache allocation and policy in C. |
| BSP traversal | `WinQuake/r_bsp.c:R_RecursiveWorldNode` | Possible, low priority | Keep the recursive walk in C. Specialized plane-dot and clip-flag helpers are better assembler seams. |
| Face/edge setup | `WinQuake/r_bsp.c:R_RenderFace`, `R_RenderBmodelFace` | Possible, risky | Consider only a measured inner loop; the surrounding pointer and clipping state should remain in C. |

### 1. `R_BuildLightMap`

This is the cleanest remaining candidate. Once the surface dimensions,
style values, and destination are known, the hot portion is a predictable
per-texel integer loop. The existing normalization helper already provides an
assembler seam; the next opportunity is the style-combination work before
normalization.

Keep in C:

- surface extents and cache addressing;
- light-style lookup and animation state;
- dynamic-light dispatch;
- destination selection and final store policy.

Move to assembler:

- repeated light-style accumulation;
- clamping or saturation that is already defined by the C reference;
- the sequential per-texel loop over `blocklights`.

The assembler version must retain the C version as a reference implementation
until framebuffer parity has been established.

### 2. `R_AddDynamicLights`

The floating-point light projection and surface-level decisions are poor
targets for a wholesale rewrite. The discrete sample traversal is a much
better target: it is repetitive, integer-heavy, and runs once per affected
lightmap texel.

The assembler helper must preserve the exact sample predicates, signed
rounding, light-distance calculation, and accumulation order. A faster
approximation is not an acceptable replacement for a preservation renderer.

### 3. Alias preparation and clipping

Alias rendering remains a substantial cost and already has assembler support
for projection, clipping, and raster spans. The next useful conversion would
be a bounded helper for vertex preparation or gradient setup rather than a
rewrite of the complete alias pipeline.

Use explicit array pointers and vertex counts at the C/assembler boundary.
Avoid making the assembler routine depend on a large set of mutable renderer
globals; that makes register pressure, calling conventions, and parity audits
harder.

### 4. Surface-cache helpers

`D_CacheSurface` and `R_DlightContributes` contain useful small helpers, but
their complete functions mix hot checks with cache policy and allocation. The
best return comes from converting a predicate, tag comparison, or tightly
bounded copy loop, not from translating the whole function line for line.

## Already covered by assembler

The checkout already contains substantial assembler for the hottest low-level
paths, including:

- ordinary texture spans in `WinQuake/d_draw16.s`;
- Z spans in `WinQuake/d_draw.s`;
- alias span and raster loops in `WinQuake/d_polysa.s`;
- alias projection and clipped-transform helpers in `WinQuake/r_aliasa.s`;
- turbulent span stores and related scan helpers;
- memory, surface-cache, texture-animation, lightmap-normalization, and BSP
  micro-helpers in the existing 486 support sources.

This means the remaining opportunity is concentrated in orchestration around
those loops and in a few lightmap/alias setup loops, rather than in replacing
the basic pixel writers.

## Poor candidates for a full conversion

These areas are technically convertible but are unlikely to repay their
complexity:

- the complete `R_RecursiveWorldNode` walk;
- complete face and brush-model setup functions;
- file I/O, command parsing, and host/platform code;
- code dominated by floating-point setup or calls into many unrelated
  subsystems;
- code whose only benefit would be a smaller instruction count without a
  measured timedemo improvement.

Whole-function rewrites in these areas increase code size, branch pressure,
and parity risk while making later maintenance more difficult.

## Implementation rules

1. Add a narrow assembler helper beside an unchanged C reference helper.
2. Keep the C/assembler ABI explicit: pointers, counts, strides, and scalar
   parameters should be visible at the call site.
3. Preserve operation width, signedness, rounding, accumulation order, and
   store order unless a deliberate parity change is approved.
4. Do not introduce MMX, SSE, or assumptions beyond the target i486.
5. Keep global-state reads at the C boundary where possible.
6. Remove or promote an experiment only after a matched benchmark and
   correctness result.

## Validation gate

Every new assembler path should be compared with its C reference and then
validated in the pinned DOSBox-X environment:

- same `demo1` timedemo and 969-frame run;
- framebuffer checksum `4154140932` on every matched run;
- smoke startup and clean exit;
- correctness harness pass;
- repeated timing measurements using the same `cputype=486`, dynamic core,
  fixed-cycle profile and data root.

A timing improvement without exact framebuffer parity is a rejected result.
Conversely, parity alone does not establish a performance win; retain the C
path until the improvement is repeated across matched runs.

## Practical decision

If only one conversion is attempted, convert the inner lightmap-combination
loop and leave the rest of `R_BuildLightMap` in C. If a second conversion is
worthwhile, target the integer inner loop of `R_AddDynamicLights`. After that,
profile alias preparation again before touching BSP traversal.
