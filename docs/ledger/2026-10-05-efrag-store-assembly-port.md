# Efrag-store assembly port

Status: ongoing renderer port. This entry records a selectable assembly
conversion of the visible-entity efrag walk; it does not close the software
renderer conversion or its remaining render-time dependencies.

## `R_StoreEfrags` now has a selectable i486 assembly entry

`EfragStoreImplementation=c|asm` selects the implementation. The assembly
walk reads the model type, skips entities already marked for the current frame,
appends unseen entities while `cl_numvisedicts` is below `MAX_VISEDICTS`, marks
them with `r_framecount`, and advances through each efrag's `leafnext` link.
The C implementation remains available through the `c` selector. The invalid
model-type path reports through the existing `Sys_Error` routine.

Compile-time checks pin the i386 pointer size and the `efrag_t`, `entity_t`, and
`model_t` offsets read by the assembly. `test-build-dos.py` passed with the
golden i486/i386 flag lists unchanged. The combined BSP-walk, world-face,
B-model-face, and efrag-store assembly selectors passed smoke and the pinned
timedemo: 969 frames, checksum `1047377823`, `59.807619 s` (`16.201949 FPS`).
This is one sample, not an alternating comparison; C remains the release
default.

Descriptive selector suffixes can produce object or executable paths beyond
Windows' legacy 259-character limit. `build-dos.ps1 -DumpFlags` now resolves
long object caches to deterministic hashed siblings under `out\`, and hashes a
profile output directory when the executable path itself is too long. The
default release paths remain unchanged.

## Remaining world-renderer closure

The legacy `src/r_drawa.s` path already provides handwritten `R_ClipEdge` and
edge projection/emission code under `id386`; `R_EmitCachedEdge` also has a
selectable assembly entry. `R_RenderPoly` belongs to the optional polygon-driver
branch, while normal DOS span rendering leaves `r_drawpolys=0` and
`D_DrawPoly()` is a no-op. The active C `R_RenderWorld` orchestration, edge
drawing, and remaining setup and draw dependencies still need assembly entries.
Keep their C references selectable and retain the pinned framebuffer checksum
gate through each stage.
