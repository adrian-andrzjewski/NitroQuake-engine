# World BSP assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of the recursive world-BSP traversal; it does not mark the software
renderer conversion complete.

## `R_RecursiveWorldNode` now has a selectable assembly walk

`BspWalkImplementation=c|asm` selects the recursive traversal. Assembly is
now the i486 release default; the original C routine remains explicitly
selectable as the reference, and i386 remains on C. The i386/i486 GNU assembly
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
selector remains available for reference builds.

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
assembly median is 0.8555% slower than the C median. This small regression is
accepted for the verified 486-compatible traversal; no speedup is claimed.

The final instrumented timedemo also completed 969 frames with checksum
`1047377823` in `80.428509 s`; it reported 375,707 BSP nodes, 59,096 leaves,
201,258 internal nodes, and 670,748 surface tests. The instrumentation run is
diagnostic, not a release timing.

The initial release ISA gate reported 168 enforced above-i486 instructions
against the 170-instruction baseline, with no unclassified instructions. The
initial C default passed smoke and the pinned checksum; its 104-artifact release
hash pin was refreshed and then verified.

## 2026-10-10 i486 release-default promotion

The i486 build now defaults `BspWalkImplementation` to assembly while explicit
C and the separate i386 C path remain available. The promotion follows the
three 969-frame checksum-matched timedemos and the byte-identical 320x200 C and
assembly PCX captures recorded above. The measured 0.8555% slowdown is accepted
because performance is secondary to verified target compatibility and
rendering parity.

The current selector contract is pinned by `tools/test-build-dos.py`; the full
normal i486 release executable was rebuilt and checked by the source-bound ISA
gate for the promoted selector. `tools/test-build-dos.py` passed with the
45/43 i486 flag lists; the separate i386 profile remains at 37/35. The release
image and report are `out/profile-d34ccbfb64f12b23/quake.exe` and
`out/profile-d34ccbfb64f12b23/isa-quake/isa-audit-linked.json`. The gate
verified 171,755 relocated instructions across 340 source-bound contributions,
529 startup rows, and 9,207 CWS DPMI-provider instructions, with zero
post-486, unknown, or exempt instructions.

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

## 2026-11-11 i486 default re-evaluation

The assembly walk remains selectable, but the i486 default now uses the C
reference. Three alternating current-source `demo1` pairs measured the C walk
0.024255% faster, and parity-clock runs matched every color and Z checksum plus
the captured frame. Both builds passed the complete strict i486 gate. The
timings are DOSBox-X measurements; they do not establish a physical-486 result.
See the [selector promotion ledger](2026-11-11-bsp-walk-c-default-promoted.md)
for the full samples and artifact paths.
