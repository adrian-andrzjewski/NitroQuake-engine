# Pure-Assembler Conversion Candidates

Date: 2026-09-28, updated 2026-09-29
Scope: i486 DOS NitroQuake software renderer

## Conclusion

The highest-value parts to convert to pure 32-bit assembler are tight,
integer-heavy raster loops. The renderer does not benefit from converting the
entire engine or every C function. High-level orchestration, floating-point
setup, recursion, and pointer-heavy control flow should remain in C unless a
profile identifies a very specific hot path.

**This survey is now closed as an optimization roadmap.** The alias-model path
was subsequently instrumented down to the source level and the remaining C
(`linescan-setup`, `edge-setup`, `span-package`, `step-math`, `SetEdgeTable`)
looked converged. **That convergence verdict was withdrawn on 2026-10-01**: the
per-call figures behind it (253-304 cycles/call) were measured with a profiler
whose own timer reads cost ~193 cycles, so 62-76% of each number was the clock.
Re-measured with the scope amortized to one per triangle, the C glue costs
1.83 s, a 3.1x overstatement — still thin, but now measured rather than assumed.
See `ledger/2026-10-01-attribution-corrections.md`, under "Alias attribution corrected".

The two large regions that measurement *does* trust, and that had never been
decomposed, are `world-bsp` (10.2% of frame, `R_RecursiveWorldNode` plus the
~800-line `R_RenderFace`, `R_ClipEdge` and `R_EmitCachedEdge`) and `edge-scan`
(8.0%, 1,373 cycles per scanline). Further work should not be chosen from this
list. Before spending a timedemo on any 486-specific idea, read "What this
harness can and cannot measure" in `ledger/2026-09-29-harness-and-cost-model.md`: DOSBox-X does not model
x87 latency, fetch boundaries, write-buffer occupancy, or 4 KB aliasing, so a
measured null for those is weak evidence. Optimization effort belongs with ideas
paid for in instruction count, memory traffic, or arithmetic.

> **Both of those regions were decomposed on 2026-10-02, and the answer was no.**
> Eleven dead-scratch probes priced them:
>
> - **`edge-scan`** is now **78% mapped, 159.2x the gate** against the profiler's
>   203.9x, as sixteen named blocks. The largest, `LNextEdge`, is 23.2x; the
>   smallest 0.9x. The four loops this file previously called "the edge routines"
>   turned out to be only 52x of a 204x bucket — most of the bucket was
>   per-edge dispatch that had never been looked at.
> - **`renderface`** is **priced at ~15.8x the gate** of C scaffolding, not the
>   70-90x an earlier estimate suggested. Its remainder is `R_ClipEdge` /
>   `R_EmitCachedEdge`, which is the essential x87 edge emit.
>
> So the "consider only a measured inner loop" advice in the Face/edge row below
> has been carried out and returned nothing. **Read the two map entries in
> `../ASM486-HANDOFF.md` and `ledger/INDEX.md` before choosing anything from this table.**

> ### 2026-10-03 — and a third region, which is now the largest open pool
>
> The two above were the *last two unexamined* closures, not the only ones left
> on an argument. A twelfth probe re-opened the biggest bucket in the renderer:
>
> - **`texture-spans`** is the largest pool in the renderer at ~24% of frame, and
>   it was closed on the claim that its per-segment setup is *"dominated by two x87
>   stores — a blind axis"*. **That is measured false.** `d_draw16.s` carries 125
>   x87 instructions out of 619, and they are in the entry divide, the
>   `LNotLastSegment` advance and the tail path — **none in the setup**. Six
>   instructions of that setup cost 0.6186% of frame, so the ~23-instruction
>   integer setup is **2.37% of frame, 47x the promotion gate**.
>
>   No candidate yet. Four reductions are recorded dead in `ledger/INDEX.md`.
>
> ### 2026-10-03, later — the clamp fusion was built, and it measured **0.0000%**
>
> The most promising of those four was the clamp fusion, nominally 0.206% and 4.1x
> the gate. The rejection said it fails because the scratch-register copy costs what
> the fusion saves, "worth revisiting if a register can be freed elsewhere first."
> **That was wrong by one instruction** — `leal -4096(%ebp),%eax` computes into the
> scratch register directly — so the candidate was buildable, and was built. It then
> measured **0.0000%**: at least 4,118,036 instructions removed, 0.206% predicted, 12
> microseconds gained, checksum-clean.
>
> **And the probe that explains it corrects the pricing rule for the whole file.**
> Four instructions of the identical shape *added* to the identical path cost
> +0.4112% at 0.988 cycles each. Every probe behind every number in the table below
> measured the cost of *adding* work; none measured what a *removal* is worth, and a
> region can charge full price for one and nothing for the other. So **the
> `edge-scan` and `renderface` prices above are additions-side prices**, they remain
> the right way to decide where to look, and **they must not be used to close
> anything.** The `texture-spans` setup is dependency-bound and is not reachable by
> instruction removal at all — only by shortening its loop-carried carry chain,
> which is a different question with no hypothesis yet.
>
> **This changes what this table is for.** The table below lists candidate *areas*
> for assembler conversion. After 2026-10-03 the best-evidenced optimisation target
> in the renderer is not on it, and is not a conversion at all — it is the
> loop-carried dependency chain of existing hand-written DDA assembly in
> `d_draw16.s`. **Read the `texture-spans` entries in `ledger/INDEX.md` before
> choosing anything from this table.**

## Candidate areas

The lightmap-combination candidate is now implemented as the selectable
R_BuildLightMapStyles_asm486 helper and has been promoted after checksum-
preserving focused and end-to-end timedemo validation.

| Area | Location | Feasibility | Recommended boundary |
|---|---|---:|---|
| Lightmap combination | `src/r_surf.c:R_BuildLightMap` | High | Keep surface bounds and light-style selection in C. Move the per-texel style-combination loop to assembler. |
| Dynamic-light accumulation | `src/r_surf.c:R_AddDynamicLights` | High | Keep light projection and floating-point setup in C. Move the fixed/integer sample traversal and accumulation loop to assembler. |
| Alias setup | `src/r_alias.c:R_AliasPreparePoints`, alias clipping, gradient setup | Medium/high | Operate on compact vertex/clip arrays with explicit counts. Preserve the existing projection and clipping conventions exactly. |
| Surface-cache checks | `src/d_surf.c:D_CacheSurface`, `src/r_surf.c:R_DlightContributes` | Medium | Convert only the small predicates or copy/check loops; leave cache allocation and policy in C. |
| BSP traversal | `src/r_bsp.c:R_RecursiveWorldNode` | Possible, low priority | Keep the recursive walk in C. Specialized plane-dot and clip-flag helpers are better assembler seams. |
| Face/edge setup | `src/r_bsp.c:R_RenderFace`, `R_RenderBmodelFace` | **Closed by measurement** | **Measured 2026-10-02: ~15.8x the gate, and `-O3` has already taken the available CSE.** The duplicated `edge_p - r_edges` across 29 sites is one `sub` (0.9x); the two obvious hoists are logged as reverted. Do not retry. |

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

- ordinary texture spans in `src/d_draw16.s`;
- Z spans in `src/d_draw.s`;
- alias span and raster loops in `src/d_polysa.s`;
- alias projection and clipped-transform helpers in `src/r_aliasa.s`;
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
- current pinned framebuffer checksum `1047377823` on every matched run;
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

## Measured surface-block loop follow-up (2026-09-28)

The mip-0 surface-block assembly loop now processes four 16-pixel rows per
loop branch. The row operation order and palette patching remain unchanged.
The two-row variant retained parity but measured only a 0.0387% median gain,
below the 0.05% promotion gate, so the four-row variant was selected instead.

Pinned DOSBox-X 2026.08.31, `cputype=486`, 33445 cycles, CWSDPMI, Steam Quake
data root, and `demo1` timedemo results:

| Build | Runs (seconds) | Median | Frames/checksum |
|---|---|---:|---|
| Control | 59.408192, 59.408224, 59.408267, 59.408144, 59.408194 | 59.408194 | 969 / `1047377823` |
| Mip-0 four-row unroll | 59.374140, 59.374155, 59.374076 | 59.374140 | 969 / `1047377823` |

The four-row build is 0.0573% faster by median. It passed the DOS smoke
startup/exit check and full `bench486` correctness suite (600-second harness
limit). Keep `control` selectable with `-SurfaceBlockMip0Rows control` for
future comparisons.

## Mip-1 eight-row loop follow-up (2026-09-28)

The mip-1 surface-block loop now performs eight 8-pixel rows before testing
the row-carry branch. The operation order and palette patching are unchanged.
This is enabled by default together with the mip-0 four-row loop above.

Pinned DOSBox-X 2026.08.31, `cputype=486`, 33445 cycles, CWSDPMI, Steam Quake
data root, and `demo1` timedemo results:

| Build | Runs (seconds) | Median | Frames/checksum |
|---|---|---:|---|
| Mip-0 four-row default, mip-1 control | 59.374140, 59.374155, 59.374076, 59.374145, 59.374089 | 59.374140 | 969 / `1047377823` |
| Mip-0 four-row plus mip-1 eight-row | 59.344208, 59.344257, 59.344203 | 59.344208 | 969 / `1047377823` |

The mip-1 unroll is 0.0504% faster by median than the five-run mip-0-only
control, just above the 0.05% promotion gate. All runs retained the exact
framebuffer checksum. The candidate passed DOS smoke startup/exit and the full
`bench486` correctness suite (`486 benchmark correctness PASS`, end checksum
`2378409472`). Keep the control selectable with
`-SurfaceBlockMip1Rows control` for future comparisons.

## Mip-0 eight-row loop follow-up (2026-09-28)

An opt-in mip-0 variant repeats eight 16-pixel rows before testing the carry
branch. It keeps the same row operation order and palette patching as the
four-row default. Both executables were rebuilt from the same source before
the five alternating pairs. The comparison used the pinned DOSBox-X
2026.08.31 profile, `cputype=486`, 33445 cycles, CWSDPMI, Steam Quake data
root, and `demo1` timedemo:

| Build | Runs (seconds) | Median | Frames/checksum |
|---|---|---:|---|
| Mip-0 four-row default, mip-1 eight-row | 59.344287, 59.344243, 59.344181, 59.344242, 59.344184 | 59.344242 | 969 / `1047377823` |
| Mip-0 eight-row, mip-1 eight-row | 59.338662, 59.338650, 59.338575, 59.338649, 59.338664 | 59.338650 | 969 / `1047377823` |

The candidate is 0.0094% faster by median, below the 0.05% promotion gate.
Every run completed 969 frames with checksum `1047377823`. The candidate
passed DOS smoke and full `bench486` correctness (`486 benchmark correctness
PASS`, end checksum `2378409472`), ~~but the release default stays at mip-0
unroll4. `-SurfaceBlockMip0Rows unroll8` remains available for further A/B
work.~~
**(Superseded 2026-10-02: the release default is `unroll16`, and `unroll8` is
obsolete as a candidate** — it is a strictly worse variant of a change that was
subsequently promoted, so there is nothing left to bundle it with.
`SurfaceBlockMip0Rows=unroll16` cleared the gate at 0.0620% inside the `surf8`
bundle with `SurfaceBlockMip1IndexHoist=hoist` and a fully-flat mip-1 body. The
measurements below stand. `tools\build-dos.ps1:36` is the authority.

The measured binaries were 791,040-byte control SHA-256
`C5EEA1917851E674BC3DC5716B4EA7DBDB231DAD8EFF7CD095FF879BB2E4A098` and
792,576-byte candidate SHA-256
`1950674B7090971BAE6E4F45754F566775582D38BD7ECAB8E5769032F612782D`. Raw
run reports are in `out\dos-timedemo-20260928-205001`,
`out\dos-timedemo-20260928-205114`, `out\dos-timedemo-20260928-205232`,
`out\dos-timedemo-20260928-205345`, `out\dos-timedemo-20260928-205458`,
`out\dos-timedemo-20260928-205614`, `out\dos-timedemo-20260928-205725`,
`out\dos-timedemo-20260928-205839`, `out\dos-timedemo-20260928-205952`,
and `out\dos-timedemo-20260928-210109` (control first, then candidate,
alternating). All reports used profile SHA-256
`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` and
CWSDPMI SHA-256
`0A890815DF6CBDC052915A856C16944CEDEC825267E7B6E453C351A0CDC695F2`. The
build manifests retain the matching row selectors.

## Mip-0 sixteen-row loop follow-up (2026-09-28)

The opt-in `unroll16` variant runs one straight-line body for all sixteen
mip-0 rows before testing the row-carry branch. It keeps the same row
operations and colormap patching as the four-row default. Both executables
were rebuilt from the same source before five alternating pairs. The runs
used pinned DOSBox-X 2026.08.31, `cputype=486`, 33445 cycles, CWSDPMI, the
Steam Quake `id1` data root, and the `demo1` timedemo:

| Build | Runs (seconds) | Median | Spread | Frames/checksum |
|---|---|---:|---:|---|
| Mip-0 four-row default, mip-1 eight-row | 59.344260, 59.344296, 59.344220, 59.344213, 59.344214 | 59.344220 | 0.000083 | 969 / `1047377823` |
| Mip-0 sixteen-row, mip-1 eight-row | 59.335715, 59.335860, 59.335689, 59.335845, 59.335846 | 59.335845 | 0.000171 | 969 / `1047377823` |

The candidate is 0.008375 seconds (0.0141%) faster by median, below the
0.05% promotion gate. Every run completed all 969 frames with the exact
framebuffer checksum. Candidate smoke exited cleanly (DOSBox-X and Quake exit
codes `0`), and the full `bench486` correctness suite reported
`486 benchmark correctness PASS` with end checksum `2378409472`. ~~The release
default remains `SurfaceBlockMip0Rows=unroll4`; `unroll16` remains selectable
for further matched A/B runs.~~
**(Superseded 2026-10-02: `unroll16` IS the release default**, promoted at
0.0620% inside the `surf8` bundle. This entry is the measurement that made it
promotable. See `ledger/2026-10-02-surf8-bundle-and-promotion.md`, under "`surf8` flat axis: three measured wins
bundled and **PROMOTED, 0.0620%**".)

The control `qbench.exe` was 791,040 bytes with SHA-256
`38286C3720BFD4F7F65CD57E268015E8E4DA2490DBFB5D94864F37356080B82C`; the
candidate `qbench.exe` was 795,648 bytes with SHA-256
`91F8CFC20E2E2F0B6BF8FB40D43FA28DC6245546E693DC041C3D36684C08A557`. The
smoke `quake.exe` was 723,456 bytes with SHA-256
`AE8D3CC50DE9B2E678C30C53DB4A1B1B72985E9213D8B99235BC37D0B5E95D4F`.
The correctness report is
`out\dos-bench-20260928-212255\bench-result.json`; smoke details are in
`out\dos-smoke\smoke-result.json`. Timedemo reports are in
`out\dos-timedemo-20260928-213132`, `out\dos-timedemo-20260928-213244`,
`out\dos-timedemo-20260928-213358`, `out\dos-timedemo-20260928-213510`,
`out\dos-timedemo-20260928-213624`, `out\dos-timedemo-20260928-213736`,
`out\dos-timedemo-20260928-213847`, `out\dos-timedemo-20260928-213959`,
`out\dos-timedemo-20260928-214110`, and
`out\dos-timedemo-20260928-214223` (control first, then candidate,
alternating). All reports used profile SHA-256
`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45` and
CWSDPMI SHA-256
`0A890815DF6CBDC052915A856C16944CEDEC825267E7B6E453C351A0CDC695F2`; build
manifests record each row selector.
