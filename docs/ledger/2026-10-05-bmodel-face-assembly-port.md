# B-model face assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of brush-model face setup; it does not close the software-renderer
conversion or its remaining render-time dependencies.

## `R_RenderBmodelFace` now has a selectable i486 assembly entry

`RenderBmodelFaceImplementation=c|asm` selects the brush-model face path. The
assembly entry owns capacity checks, clip-plane chain setup, bedge-list
traversal, synthetic left/right edge handling, and surface setup. Benchmark
builds retain `R_RenderBmodelFace_C` as the reference. The entry shares
`R_ClipEdge` and the existing surface-gradient selector.

Compile-time layout checks cover `bedge_t`, the surface, clip-plane, and posted
surface structures. The assembly selector passed DOS smoke and the pinned
969-frame timedemo with checksum `1047377823`. One assembly sample took
`59.167755 s`, against the preceding three-run C median of `59.170075 s`; that
single sample is not an alternating comparison and is not promotion evidence.
C remains the release default.

The BSP-walk, world-face, and B-model-face assembly selectors also passed one
combined 969-frame timedemo with the same framebuffer checksum. The combined
sample took `59.806364 s`, so the assembly selectors remain opt-in.

The selector table test passed with the default i486 and i386 flag lists still
golden-pinned. The B-model face selector now uses the descriptive
`bmodelasm` profile token. Long selector combinations use the deterministic
hashed object/output path fallback recorded in the efrag-store ledger.

## Remaining B-model renderer closure

`R_ClipEdge` and its edge projection/emission work are handwritten in legacy
`src/renderer/r_drawa.s` under `id386`; `R_EmitCachedEdge` now also has a selectable
assembly entry. The brush-model polygon clipping path, entity-fragment
traversal, active edge drawing, and remaining draw routines still need
conversion. `R_RenderPoly` belongs to the optional polygon-driver branch;
normal DOS span rendering leaves `r_drawpolys=0` and `D_DrawPoly()` is a
no-op. Keep the C references and exact framebuffer checksum gate for the
remaining active paths.
