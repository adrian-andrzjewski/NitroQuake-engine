# World BSP assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of the recursive world-BSP traversal; it does not mark the software
renderer conversion complete.

## `R_RecursiveWorldNode` now has a selectable assembly walk

`BspWalkImplementation=c|asm` selects the recursive traversal. The default C
path retains the original routine as a reference. The i386/i486 GNU assembly
entry uses the existing `regparm(2)` interface and owns visibility and solid
culls, frustum-mask application, front/back recursion, leaf mark-surface
updates, efrag dispatch, BSP keys, visible-face selection, render ordering, and
back-to-front polygon queueing. It uses the existing assembly plane-dot and
frustum-clip helpers. `R_RenderFace` now has its own selectable assembly path;
`R_RenderPoly` remains a shared C callee. `R_StoreEfrags` now has a separate
assembly selector recorded in the efrag-store ledger.

Compile-time offset checks in `src/r_bsp.c` protect the node, leaf, surface,
client-state, model, and polygon layouts read by the assembly. PROFILE486 builds
retain the BSP node counters and the `R_RenderFace` timing scope through small C
callbacks. The original C traversal remains separately selectable and the C
selector remains the release default.

The first full run produced checksum `184024924` instead of the reference
`1047377823`. The x87 `FTST` used to choose the front child left its operand on
the FPU stack at every internal node. Popping it before recursion restored the
stack discipline. A register pass then kept the current node and child side in
callee-saved registers across recursion and drawing calls. The final assembly
release passed DOS smoke and three timedemo runs:

| Selector | Run times (s) | Median (s) | Checksum |
|---|---:|---:|---:|
| C | 59.170035, 59.170075, 59.170075 | 59.170075 | `1047377823` each |
| Assembly | 59.676273, 59.676296, 59.676288 | 59.676288 | `1047377823` each |

The C samples were collected in an alternating comparison before the
assembly-only register pass; that pass does not change the C build. The final
assembly median is 0.8555% slower than the C median, so the assembly selector
stays opt-in and C remains the release default.

The final instrumented timedemo also completed 969 frames with checksum
`1047377823` in `80.428509 s`; it reported 375,707 BSP nodes, 59,096 leaves,
201,258 internal nodes, and 670,748 surface tests. The instrumentation run is
diagnostic, not a release timing.

The release ISA gate reported 168 enforced above-i486 instructions against the
170-instruction baseline, with no unclassified instructions. The selector
manifest test passed without changing the default i486/i386 flag lists. The C
default passed smoke and the pinned checksum; its 104-artifact release hash
pin was refreshed and then verified.

## Remaining world-BSP closure

Continue the renderer port through the remaining active render-time closure.
`R_RenderWorld` now has its own selectable i486 assembly entry, with C still
the release default; its framebuffer capture matches the C selector byte for
byte for the pinned demo. The user-reported live-display smear has not been
reproduced by that buffer capture and remains open for visual investigation.
`R_ClipEdge` is already handwritten in legacy `src/r_drawa.s` under `id386`,
and the polygon renderer belongs to the optional polygon-driver branch. Normal
DOS span rendering leaves `r_drawpolys=0` and `D_DrawPoly()` is a no-op. The
active C closure still includes `R_DrawSubmodelPolygons`, `R_EdgeDrawing`,
edge scanning, and other renderer setup and draw dependencies. Keep the C
references and exact framebuffer checksum gate while adding each assembly
entry.
