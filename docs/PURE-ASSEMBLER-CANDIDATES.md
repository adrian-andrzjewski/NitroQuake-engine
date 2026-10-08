# Pure-Assembler Conversion Candidates

Date: 2026-09-28, updated 2026-10-07
Scope: i486 DOS NitroQuake software renderer

> **Scope update (2026-10-04):** this document records the earlier performance
> survey and its recommendations about which conversions are likely to improve the
> timedemo. The current user-directed work is broader: port the full software
> renderer and render-time dependency closure to hand-written i486 assembler while
> retaining C references during migration. The survey is still useful for choosing
> order and measuring performance; its recommendation against a full conversion no
> longer limits the requested scope. Track implementation state in
> renderer-port ledgers under `docs/ledger/`.
> Current source and coverage gaps are recorded in
> [Renderer completion gaps](RENDERER-COMPLETION-GAPS.md).

> **Objective clarification (2026-10-06):** the requested move to assembly is
> primarily to establish i486 CPU compatibility while preserving the reference
> renderer's behavior. Timing remains useful diagnostic evidence, but a slower
> assembly path is not a reason to reject a correct i486 implementation.

> **Implementation update (2026-10-04):** `D_DrawSkyScans8` now has a complete
> selectable i486 assembly path, including viewport/time setup, UV projection,
> vector normalization, span interpolation, and pixel sampling. Direct UV and
> framebuffer parity pass; C remains selectable. `D_WarpScreen` is also a
> selectable full assembly entry point, including ratio setup, lookup tables,
> time phase, and pixel copy. Table generation is slower in isolation, so C
> remains the default. `D_DrawSolidSurface` now has a selectable assembly span
> fill; its isolated benchmark is 5.128% faster, but the pinned demo does not
> exercise the optional `r_drawflat` path, so C remains the default. See
> `docs/ledger/2026-10-04-renderer-assembler-port.md`.

> **Turbulent scan update (2026-10-04):** `Turbulent8` now has a selectable
> full i486 assembly entry for phase/setup, span traversal, projection,
> interpolation, and chunk handling. Direct parity passed across 13 span counts,
> six phases, and four x87 rounding modes with the `stosb`, ASM, and C inner
> loop choices.
> C remains the default because the separate timedemo samples were not paired
> and included an outlier; see the renderer-port ledger for the measurements.

> **Dynamic-light update (2026-10-04):** `R_AddDynamicLights` now has selectable
> i486 assembly for sparse light-bit traversal, x87 projection, surface culling,
> and sample-helper dispatch. `R_DlightContributes` also has a selectable
> assembly predicate using the shared projector. The 36-case projection and
> predicate harness, 11-case lightmap harness, release smoke, ISA gate, and
> pinned checksum passed; C remains the default. `D_CacheSurface` now has
> assembly cache-hit, key-load, miss-path metadata, texture/style tag, rover
> allocator, attachment, dispatch, and dynamic-light tag paths. Texture animation,
> high-level hit/miss policy, and profile accounting remain in C at this earlier
> helper-only stage. The complete public cache entry is covered below.
> See the renderer-port ledger.

> **Surface draw update (2026-10-04):** `R_DrawSurface` now has a selectable
> complete i486 assembly entry. Its 40-case parity harness covers four mips,
> POT and NPOT textures, five lightmap modes, output scratch, `blocklights`,
> and renderer globals. Smoke, the i486 gate, and a pinned 969-frame checksum
> passed; the single timedemo sample is not performance evidence. C remains
> the release default. The render-time dependency closure remains open; see
> the renderer-port ledger.

> **Alias-frame setup update (2026-10-07):** `R_AliasSetupFrame` now has a
> selectable i486 assembly helper for single and grouped model-frame
> resolution. Fifty-six direct comparisons passed across four x87 rounding
> modes. A two-repeat Demo 2 pair matched all 980 post-warmup checksums per
> run and both complete indexed captures and palettes. Selected-object and
> linked-runtime audits passed; C remains the release default. Alias skin
> selection and gradient setup have since received focused implementations;
> see the renderer-port ledgers.

> **Alias-skin setup update (2026-10-07):** `R_AliasSetupSkin` now has a
> selectable i486 assembly helper for single and grouped skin resolution.
> Fifty-six direct comparisons passed across four x87 rounding modes. A
> two-repeat Demo 2 pair matched all 980 post-warmup checksums per run and
> both complete indexed captures and palettes. Selected-object and linked
> runtime audits passed; C remains the release default. See the
> renderer-port ledger.

> **Alias-gradient setup update (2026-10-07):** `D_PolysetCalcGradients` now
> has an explicit C-reference/assembly selector around the existing i486 x87
> routine. Eight direct cases matched eleven gradient outputs, including the
> determinant-versus-reciprocal handoff and x87 control-word behavior. A
> two-repeat Demo 2 pair matched all 980 post-warmup checksums and complete
> indexed captures and palettes on both repeats. Object and linked-runtime
> i486 audits passed. Assembly remains the i486 default, preserving the
> existing path; see the renderer-port ledger.

> **Alias line-scan setup update (2026-10-07):**
> `D_PolysetSetUpForLineScan` now has a selectable i486 assembly path for
> small-table lookup and larger positive-edge division. The 16,416-case
> direct fixture passed across all table pairs, long edges, extreme signed
> coordinates, and four x87 rounding modes. A two-repeat Demo 2 pair matched
> every post-warmup checksum and complete indexed capture and palette on both
> repeats. Object and linked-runtime ISA audits passed; assembly is the i486
> default. Large invalid heights retain the C error path. See the
> renderer-port ledger.

> **Surface-cache entry update (2026-10-04):** `D_CacheSurface` now has a full
> selectable i486 assembly entry for texture call guarding, cache hit/miss flow,
> metadata setup, allocation handoff, tag writes, draw dispatch, and sticky
> dynamic-light state. The four-mip public-entry hit harness and helper suite
> passed. The combined cache/draw assembly selectors passed smoke and a pinned
> 969-frame checksum; one timing sample is not a speed claim. The C entry remains
> the release default. `R_TextureAnimation` frame resolution and PROFILE486
> accounting still use C helpers; the remaining render-time dependency closure
> is open.

> **Texture-animation entry update (2026-10-04):** `R_TextureAnimation` now
> has a full selectable i486 assembly entry for alternate textures, the static
> fast path, x87 time conversion, signed phase remainder, and frame lookup. The
> C/assembly harness passed 25 time values across primary, alternate, and static
> paths in all four x87 rounding modes. The complete-entry microbenchmark was
> 2.666% faster for assembly; smoke, the 168-instruction ISA gate, and a pinned
> 969-frame checksum passed. One timedemo sample is not a performance comparison.
> Assembly remains the selector default; the renderer dependency closure is open.

> **Mip-selector entry update (2026-10-04):** the selected assembly build now
> exports `D_MipLevelForScale` directly from the x87 threshold routine, with no
> C forwarding entry. Eight threshold and clamp cases matched C, release smoke
> and the pinned 969-frame checksum passed, and the ISA gate remained at 168
> enforced above-i486 instructions. The helper microbenchmarks are mixed, so C
> remains the release default.

> **Face-depth update (2026-10-05):** `R_SetSurfaceZGradients` now has a
> selectable i486 assembly entry with the same plane/entity/frame cache and
> x87 operation order as the C reference. Its 32-case parity harness passed
> across cache-key changes and all four x87 rounding modes; release smoke, the
> 168-instruction ISA gate, and the pinned 969-frame checksum also passed. The
> single timedemo run is not a speed comparison, so C remains the release
> default; see the renderer-port ledger.

> **Texture-gradient update (2026-10-05):** `D_CalcGradients` now has a
> selectable i486 assembly path that owns the x87 gradient arithmetic and a
> separate texture-axis cache. Its 20-case harness passed across mip levels,
> cache hits and key changes, and all four x87 rounding modes. Release smoke,
> the 168-instruction ISA gate, and the pinned 969-frame checksum passed; the
> single timedemo sample is not a speed comparison, so C remains the default.
> `D_DrawSurfaces` now has a selectable assembly dispatcher; the world walk has
> since gained a selectable assembly entry, while shared callees and the
> remaining helper closure stay open. See the ledger.

> **Surface-dispatch update (2026-10-05):** `D_DrawSurfaces` now has a
> selectable i486 assembly dispatcher for surface traversal, mip-scale setup,
> draw-mode selection, Z-gradient loads, and brush-model/world-state changes.
> Its release build passed smoke and the ISA gate; the pinned 969-frame timedemo
> matched checksum `1047377823`. The 59.208935-second single sample is not
> performance evidence, so C remains the default. Cache, gradient, mip, and
> span-drawing helpers remain independently selectable; shared render-time
> callees and the full dependency closure remain open.

> **World-BSP update (2026-10-05):** `R_RecursiveWorldNode` now has a selectable
> assembly walk for culling, recursion, leaf marking, BSP keys, face selection,
> and polygon ordering. The pinned 969-frame checksum, smoke, and instrumented
> timedemo passed. Three assembly runs were 0.856% slower than the C median, so
> C remains the release default. `R_RenderFace`, `R_RenderBmodelFace`, and
> `R_StoreEfrags` now also have selectable assembly entries. The combined
> selectors passed smoke and the pinned framebuffer checksum; a single timedemo
> sample is not a performance comparison. `R_ClipEdge` and edge
> projection/emission already use legacy handwritten assembly under `id386`,
> and `R_EmitCachedEdge` now has a separate selector. `R_RenderPoly` belongs to
> the optional polygon-driver branch; normal DOS span rendering leaves
> `r_drawpolys=0` and `D_DrawPoly()` is a no-op. See the renderer-port ledgers.

> **Brush-model clipping update (2026-10-05):** `R_RecursiveClipBPoly` now has
> a selectable i486 assembly implementation with its C reference retained.
> The i486 build and selector contract passed; C and assembly each completed
> the pinned 969-frame demo with checksum `1047377823`. Matched intermediate
> captures reproduced the wall leak: the wrong x87 divide direction produced
> off-plane vertices and 17 edge overflows. The corrected `fdivrp` path has an
> intact wall and zero overflows. The single timings are not comparative
> evidence; see the brush-model clipping ledger.

> **Alias vertex-preparation update (2026-10-05):** `R_AliasPreparePoints` now
> selects a hand-written i486 loop for transform dispatch, near-plane
> classification, projection dispatch, and viewport clip flags. The control
> and local C loops remain selectable; the triangle clipping/draw loop is still
> C. Smoke and the selector contract passed, and C-control and assembly timedemo
> runs both produced 969 frames with checksum `1047377823`. The single timings
> do not justify promotion; see the renderer-port ledger.

> **World-render orchestration update (2026-10-05):** `R_RenderWorld` now has
> a selectable i486 assembly entry for render-state setup, the frame-local
> polygon queue, BSP dispatch, and optional back-to-front polygon replay. C
> remains the release default. The assembly run passed smoke and the pinned
> 969-frame checksum. C and assembly frame captures were byte-identical, but
> the user-reported live-display smear remains under investigation because a
> buffer capture does not validate the DOSBox-X window presentation.

> **Sprite-draw orchestration update (2026-10-07):** `D_DrawSprite` now has a
> selectable i486 assembly entry for vertex bounds, scan rounding, local span
> storage, cache setup, closing-vertex copy, and dispatch to its independently
> selectable sprite stages. The direct C/assembly fixture matched color and
> depth buffers in all three cases; the two-repeat Demo 2 pair matched all 980
> post-warmup frame checksums and every captured palette index and palette
> byte. `D_SpriteDrawSpans` is the preexisting `id386` 8-bit assembly
> rasterizer. C remains selectable; see the renderer-port ledger.

> **Sprite-setup orchestration update (2026-10-07):** `R_SetupAndDrawSprite`
> now has a selectable i486 assembly entry for poster construction, world
> frustum clipping, view transformation, near-plane handling, projection, and
> dispatch. Five direct C/assembly fixtures match clip vertices, projected
> vertices, `nearzi`, color, and depth exactly. A two-repeat Demo 2 pair matched
> all 980 post-warmup frame checksums and the complete captured indexed frame
> and palette on both repeats. The focused object and linked-runtime i486 audits
> passed. Assembly is now the i486 default; C remains selectable and i386 remains C. See the renderer-port ledger.

> **Alias-lighting setup update (2026-10-07):** `R_AliasSetupLighting` now
> has a selectable i486 assembly entry for ambient and shade setup plus light
> vector rotation. Its 24 direct cases passed exact comparison across all four
> x87 rounding modes, and object and linked-runtime audits passed. A focused
> two-repeat Demo 2 pair matched all 980 post-warmup checksums per run and both
> complete indexed captures and palettes. C remains the release default; see
> the renderer-port ledger.

> **Alias matrix-setup update (2026-10-07):** the `asm` setting for
> `AliasMatrixCompositionImplementation` now selects assembly for view-basis
> setup and both matrix products in `R_AliasSetUpTransform`. Three view-basis
> fixtures and the fractional and translation-order matrix fixtures matched
> exactly. Two repeated Demo 2 runs matched all 980 post-warmup checksums plus
> both complete indexed captures and palettes. The selected and linked i486
> audits passed; assembly is now the i486 default while both C choices remain
> selectable. See the renderer-port ledger.

> **Lightmap dispatcher update (2026-10-04):** `R_BuildLightMap` now has a
> selectable full i486 assembly dispatcher, with the C dispatcher retained as
> the release default and benchmark reference. Eleven focused scenarios passed
> with assembly helpers and C helper variants. Both release selectors passed
> smoke and retained the pinned 969-frame checksum; the single timing pair was
> inconclusive. At that point `R_AddDynamicLights` orchestration was the next
> open entry; it has since gained a selectable assembly path, followed by cache
> miss-path work. `R_DrawSurface` now has a selectable assembly entry; current
> next work is the remaining rendering-time dependency closure;
> see the renderer-port ledger.

## Historical optimization survey conclusion

The earlier performance survey identified the highest-value parts to convert
to pure 32-bit assembler as tight,
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

The lightmap-combination helper is implemented as the selectable
`R_BuildLightMapStyles_asm486` path. The full `R_BuildLightMap` dispatcher and
the dynamic-light orchestration and projection now have selectable assembly
entries. Their C references remain available; parity and the i486 ISA gate
determine promotion, while timing is used to catch material regressions.

| Area | Location | Feasibility | Recommended boundary |
|---|---|---:|---|
| Active dynamic-light enumeration | `src/r_light.c:R_PushDlights` | **Implemented and promoted for i486** | `DynamicLightPushImplementation=c|asm` selects the 32-slot active-light loop and dispatch to `R_MarkLights`. Five direct fixture cases passed; six scenes, two repeats each, had exact frame checksums and exact 320x200 framebuffer/palette captures. Assembly is the i486 default; C remains selectable and i386 remains C. See the R_PushDlights ledger. The four-path combined profile also passed six-scene exact parity. |
| Lightmap combination | `src/r_surf.c:R_BuildLightMap` | Implemented | The assembly dispatcher owns bounds, cache, path selection, dynamic-light dispatch, and normalization calls; C remains the release default. |
| Dynamic-light accumulation | `src/r_surf.c:R_AddDynamicLights` | Implemented | Assembly owns sparse light-bit traversal, x87 projection, culling, and dispatch; the texel sample loop remains independently selectable. |
| BSP dynamic-light marking | `src/r_light.c:R_MarkLights` | **Implemented and promoted for i486** | `MarkLightsImplementation=c|asm` selects the recursive i486 BSP walk. The 128-case x87 fixture, exact Demo 1 comparison, and six-scene paired comparison with transient notices disabled passed. With notices enabled, the only captured differences were expiring console text in rows 1–23; all other framebuffer pixels and palettes matched. Assembly is the i486 default, C remains selectable, and the separate i386 default remains C. See the renderer-port ledger. The four-path combined profile also passed six-scene exact parity. |
| Alias setup | `src/r_alias.c:R_AliasPreparePoints`, `R_AliasSetViewMatrix`, `R_AliasSetUpTransform`, `R_AliasSetupLighting`, `R_AliasSetupFrame`, `R_AliasSetupSkin`, `src/asm486_experiments.s:R_AliasSetViewMatrix_asm486`, `R_ConcatTransforms_asm486`, `src/r_aclip.c` clipping, `src/d_polyse.c:D_PolysetCalcGradients`, `D_PolysetSetUpForLineScan`, `D_PolysetSetEdgeTable`, `D_PolysetUpdateTables`, and `D_RasterizeAliasPolySmooth` | **Partial, not promoted** | `AliasPrepareImplementation=control|local|asm` selects the C control reference, a local C-loop variant, or the i486 clipped-vertex assembly loop; `asm` is now the i486 default and passed two-repeat exact Demo 2 parity. `AliasMatrixCompositionImplementation=c|special|asm` selects generic C, the specialized diagonal C path, or assembly view-basis setup plus both `R_ConcatTransforms_asm486` products; three view-basis fixtures, two matrix fixtures, and two-repeat exact Demo 2 parity passed, and assembly is now the i486 default. `AliasClipImplementation=c|asm` selects the generic clip pass and triangle-level clipping orchestration; `AliasClipZImplementation=c|asm` independently selects the Z-plane intersection callback and requires `AliasClipImplementation=asm`. `AliasSetupLightingImplementation=c|asm` selects ambient/shade and light-vector setup; 24 direct cases and a two-repeat Demo 2 pair passed exact comparison. `AliasSetupFrameImplementation=c|asm` selects single/group alias model animation frame resolution; 56 direct cases and a two-repeat Demo 2 pair passed exact comparison. `AliasSetupSkinImplementation=c|asm` selects single/group skin resolution; 56 direct cases and a two-repeat Demo 2 pair passed exact comparison. `AliasGradientImplementation=c|asm` selects the existing x87 gradient routine; eight direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasLineScanImplementation=c|asm` selects table lookup and large-edge setup; 16,416 direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasEdgeTableImplementation=c|asm` selects the original 12-way signed-Y table lookup; 1,372 direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasSkinTableImplementation=c|asm` selects the cache-key comparison and 480 byte-stride skin-row pointers; 64 direct cases and a two-repeat Demo 2 pair passed exact comparison, and assembly remains the i486 default. `AliasRasterizeImplementation=c|asm` selects the triangle rasterization orchestration and span-package setup; the focused Demo 2 pair matched exactly on both repeats, and assembly remains the i486 default. Preserve projection, clipping, and triangle order exactly. |
| Surface-cache checks | `src/d_surf.c:D_CacheSurface`, `src/r_surf.c:R_DlightContributes` | Medium | `R_DlightContributes`, the public `D_CacheSurface` hit/miss flow, cache key/setup/tag work, `D_SCAlloc`, cache attachment, draw dispatch, dynamic-light tag updates, and the `R_DrawSurface` entry have assembly paths; animation-frame resolution and PROFILE486 accounting still call C helpers. |
| Surface dispatch | `src/d_edge.c:D_DrawSurfaces` | Implemented | The selectable assembly dispatcher owns the per-frame surface loop; cache, gradient, mip, and drawing callees remain independent selectors. The world walk has its own assembly selector; shared render callees remain open. |
| BSP traversal | `src/r_bsp.c:R_RecursiveWorldNode` | Implemented | `BspWalkImplementation=c|asm` selects the recursive assembly walk; C remains the release default. The assembly path preserves traversal and face order, calls the selectable face renderer and efrag walk, and still calls the shared polygon renderer. |
| World-render orchestration | `src/r_bsp.c:R_RenderWorld` | **Implemented, not promoted** | `RenderWorldImplementation=c|asm` selects the assembly setup, frame-local polygon queue, BSP dispatch, and optional polygon replay; C remains the release default. C and assembly timedemo PCX captures matched byte-for-byte. |
| Face/edge setup | `src/r_draw.c:R_RenderFace`, `R_RenderBmodelFace`, `R_EmitCachedEdge` | **Implemented, not promoted** | Selectable i486 assembly is available for both face paths and cached-edge insertion, with C references retained. The face paths and combined BSP configuration passed the exact framebuffer checksum; `R_EmitCachedEdge` also passed the pinned checksum and instrumented call-count check. Single samples are not comparative performance evidence; C remains the release default. `R_ClipEdge` and edge projection/emission are legacy handwritten assembly under `id386`. |
| Entity efrags | `src/r_efrag.c:R_StoreEfrags` | **Implemented, not promoted** | `EfragStoreImplementation=c|asm` selects the list walk; compile-time layout checks protect its 32-bit field offsets. Combined renderer selectors passed the pinned checksum; C remains the release default. |
| Particle simulation | `src/r_part.c:R_DrawParticles` | Implemented | `ParticleUpdateImplementation=c|asm` selects dead-list maintenance, draw order, position, velocity, and ramp updates. The C wrapper retains lifecycle and PROFILE486 glue; `D_DrawParticle` remains the existing driver rasterizer. The all-assembly i486 profile passed six repeated reference-scene checks; C remains independently selectable. |
| Submodel polygon surfaces | `src/r_bsp.c:R_DrawSubmodelPolygons` | **Implemented, not promoted** | `SubmodelPolygonsImplementation=c|asm` selects the surface loop, x87 backface test, render-key update, and face dispatch. The assembly smoke and both C/ASM combined candidates passed the pinned checksum; their live captures landed at different demo times, so visual frame parity remains open. |
| Brush-model polygon clipping | `src/r_bsp.c:R_RecursiveClipBPoly` | **Implemented, not promoted** | `BmodelPolygonClipImplementation=c|asm` selects the recursive BSP edge clipper, intersection-vertex construction, clip-boundary edges, and visible-leaf dispatch. C and assembly passed the pinned checksum; matched `demo1` captures reproduced and then cleared the wall leak, with zero edge overflows after the x87 divide fix. |
| Animated sprite-frame selection | `src/r_sprite.c:R_GetSpriteframe` | **Implemented and promoted for i486** | `SpriteFrameImplementation=c|asm` selects single/group frame resolution with the original interval boundary and x87 conversion behavior. Twelve direct cases and a two-repeat Demo 2 comparison passed exactly; focused linked ISA audit passed. Assembly is now the i486 default; C remains selectable and i386 remains C. |
| Sprite draw orchestration | `src/d_sprite.c:D_DrawSprite` | **Implemented and promoted for i486** | `SpriteDrawImplementation=c|asm` selects vertex bounds/rounding, span storage, sprite cache setup, vertex closure, and stage dispatch, with C retained. Direct color/depth fixtures and a two-repeat Demo 2 pair passed exact comparison; sprite sub-stages remain independently selectable. Assembly is now the i486 default; C remains selectable and i386 remains C. It also passed the combined four-path, six-scene exact comparison. |
| Sprite setup orchestration | `src/r_sprite.c:R_SetupAndDrawSprite` | **Implemented and promoted for i486** | `SpriteSetupImplementation=c|asm` selects backface culling, poster construction, four-plane clipping, transform, near-plane clamp, perspective projection, `nearzi`, and draw dispatch. Five direct fixtures and a two-repeat Demo 2 pair passed exact frame/checksum comparisons; focused i486 object and linked-runtime audits passed. Assembly is now the i486 default; C remains selectable and i386 remains C. |
| Edge-drawing orchestration | `src/r_main.c:R_EdgeDrawing` | **Implemented, not promoted** | `EdgeDrawingImplementation=c|asm` selects stack-buffer setup, world dispatch, scans, Z-enable, brush-entity dispatch, and update flow. C and ASM passed smoke and the pinned checksum; live captures were coherent but landed at slightly different demo states. |
| Edge scanline loop | `src/r_edge.c:R_ScanEdges` | **Implemented, not promoted** | `ScanEdgesImplementation=c|asm` selects the aligned span buffer, row loop, edge updates, span flushes, and final draw. C and ASM passed smoke and the pinned 969-frame checksum. Single runs showed no speed gain, and matched-frame visual acceptance remains open. |
| Active-edge maintenance | `src/r_edge.c:R_InsertNewEdges`, `R_RemoveEdges`, `R_StepActiveU` | **Implemented, not promoted** | `EdgeListMaintenanceImplementation=legacy|c|asm` preserves the original `id386` assembly as the default, exposes the true C reference, and adds replacement i486 assembly. C and ASM matched the pinned checksum, with no gain in single samples; visual acceptance remains open. |

### 1. `R_BuildLightMap`

This was the cleanest remaining candidate when the survey was written. The
complete dispatcher is now selectable in assembly, while its C implementation
and each style, fused-style, dynamic-light, and normalization helper remain
available through their own references and selectors.

The C selector keeps the original full dispatcher. The assembly selector moves
surface bounds, cache decisions, fullbright and ambient branches, helper
selection, dynamic-light dispatch, and normalization orchestration to assembler.
The single-style cached table and ambient clear/fill loops also run in assembly.
Style accumulation, fused accumulation, dynamic-light sampling, and
normalization remain independently selectable helpers. The C dispatcher is
retained as the benchmark reference, and C remains the release default pending
repeatable performance evidence.

### 2. `R_AddDynamicLights` orchestration

The sparse `dlightbits` traversal, x87 surface projection, culling, and helper
dispatch now have a selectable i486 assembly entry. The texel sample loop
remains independently controlled by `DynamicLightImplementation`; the C
orchestration and projection remain available for benchmark parity.

The assembler projection must preserve the existing dot-product order, plane
distance, radius/minlight rejects, `ceil`-based distance limit, texture-space
coordinates, surface-edge cull, and x87 rounding behavior. The pixel helper must
continue to preserve the exact sample predicates, signed rounding,
light-distance calculation, and accumulation order.

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

`R_DlightContributes`, the public cache hit/miss flow, key loading, miss-path
metadata, texture/style tag writes, the rover allocator, cache attachment, draw
dispatch, dynamic-light tag updates, `R_DrawSurface` setup, and the full
`R_TextureAnimation` entry now have assembly paths. PROFILE486 accounting and
the remaining render-time dependency closure stay open; keep the C path as the
reference while continuing those parts.

## Already covered by assembler

The checkout already contains substantial assembler for the hottest low-level
paths, including:

- ordinary texture spans in `src/d_draw16.s`;
- Z spans in `src/d_draw.s`;
- alias span and raster loops in `src/d_polysa.s`;
- alias projection and clipped-transform helpers in `src/r_aliasa.s`;
- turbulent span stores and the `Turbulent8` scan setup/interpolation entry;
- the complete `R_BuildLightMap` dispatcher around selectable light/style helpers;
- direct assembly entries for `D_MipLevelForScale` and `R_TextureAnimation`;
- memory, surface-cache, texture-animation, lightmap-normalization, and BSP
  micro-helpers in the existing 486 support sources.

This means the remaining opportunity is concentrated in orchestration around
those loops and in a few lightmap/alias setup loops, rather than in replacing
the basic pixel writers.

## Poor candidates for a full conversion

These areas are technically convertible but are unlikely to repay their
complexity:

- complete face and brush-model setup functions;
- file I/O, command parsing, and host/platform code;
- code dominated by floating-point setup or calls into many unrelated
  subsystems;
- code whose only benefit would be a smaller instruction count without a
  measured timedemo improvement.

Whole-function rewrites in these areas increase code size, branch pressure,
and parity risk while making later maintenance more difficult.

## Current implementation rules

1. Add a narrow assembler helper beside an unchanged C reference helper.
2. Keep the C/assembler ABI explicit: pointers, counts, strides, and scalar
   parameters should be visible at the call site.
3. Preserve operation width, signedness, rounding, accumulation order, and
   store order unless a deliberate parity change is approved.
4. Do not introduce MMX, SSE, or assumptions beyond the target i486.
5. Keep global-state reads at the C boundary where possible.
6. Integrate an assembly path only after exact reference comparisons and
   mechanical i486 ISA validation pass. Record matched timing measurements
   to detect significant regressions; a speed improvement is not required.

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
Promote a correct, auditable i486 assembly path after its correctness and ISA
gates pass, provided measurements show no unacceptable performance regression.
Retain the C implementation as a selectable reference. Small slowdowns do not
prevent promotion and do not justify repeated optimization of correct assembly.

## Practical decision

The lightmap-combination helper, complete `R_BuildLightMap` dispatcher,
`R_AddDynamicLights` orchestration, `R_DrawSurface` entry, `D_CacheSurface`
entry, BSP traversal, and `R_RenderWorld` orchestration now have selectable
assembly paths, with C references retained. Continue through the remaining
render-time dependency closure and software-renderer code while retaining
exact-output gates.

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
