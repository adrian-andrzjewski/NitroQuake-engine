# RenderFace assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of the world `R_RenderFace` path; it does not close the renderer
conversion or its render-time C dependency closure.

## `R_RenderFace` now has a selectable i486 assembly entry

`RenderFaceImplementation=c|asm` selects the world-face path. The assembly
entry owns clip-chain setup, surfedge and vertex traversal, edge-cache reuse,
clipping flags, surface allocation and initialization, and the render-face
counters. Benchmark builds retain `R_RenderFace_C` as the C reference. The
assembly path continues to use the legacy `R_ClipEdge` routine in
`src/r_drawa.s` and dispatches surface gradients through the existing gradient
selector. The adjacent
`R_RenderBmodelFace` entry has since received its own selector; see
[`2026-10-05-bmodel-face-assembly-port.md`](2026-10-05-bmodel-face-assembly-port.md)
under "`R_RenderBmodelFace` now has a selectable i486 assembly entry".

The DOSBox-X page fault initially surfaced after the edge cache had been
corrupted. `edge_t.surfs` contains two 16-bit surface indices at offsets 16 and
18; `nextremove` is a pointer at offset 20. Writing the second surface as a
dword overwrote `nextremove`. The assembly now loads and stores each surface
index as a word, compares `nearzi` with the same x87 float ordering as C, and
has compile-time layout checks for these fields and the surface, edge, vertex,
and clipping structures.

The selector passed DOS smoke and completed the pinned 969-frame timedemo with
the reference framebuffer checksum `1047377823`. The original single assembly
sample below was not promotion evidence. A current matched comparison now
shows a **+0.39763%** mean improvement over C across three uninstrumented runs;
the full strict i486 audit passed, and `RenderFaceImplementation=asm` is
promoted for i486. See the [2026-10-22 promotion ledger](2026-10-22-renderface-assembly-promoted.md)
for samples and run metadata. C remains available explicitly and remains the
i386 default.

The earlier single assembly sample took `59.302341 s` (`16.339996 FPS`). The
preceding three-run C median was `59.170075 s`; this single,
non-alternating result measured about 0.22% slower and was correctly not used
as promotion evidence at the time.

The release ISA gate reported 172 enforced above-i486 instructions against a
173-instruction baseline, with no unclassified instructions. The smoke build
reported 168 against 170, also with no unclassified instructions. The selector
manifest test and default i486 release hash guard passed.

## `R_EmitCachedEdge` now has a selectable i486 assembly entry

`EmitCachedEdgeImplementation=c|asm` selects the cached-edge helper used by
the C world-face and B-model-face paths. Its assembly entry computes the edge
from `r_pedge->cachededgeoffset`, installs the surface index in the first empty
16-bit `surfs[]` slot, compares `nearzi` with `r_nearzi` using ordered x87
comparison, and sets `r_emitted`. Layout assertions pin the edge, surface and
medge fields read by the routine. Benchmark builds retain
`R_EmitCachedEdge_C`; C remains the release default.

The selector manifest test passed with default i486/i386 flags unchanged. The
release timedemo completed 969 frames with checksum `1047377823`; its single
`59.179677 s` sample is not comparative performance evidence. The instrumented
timedemo also matched the checksum and reported 121,467 calls to the assembly
entry. The release ISA gate reported 172 enforced above-i486 instructions
against the 173-instruction baseline, with no unclassified instructions.

## Remaining active renderer closure

`R_ClipEdge` and its edge projection/emission work are handwritten in the
legacy `src/r_drawa.s` path under `id386`; they are not remaining C callees.
`R_RenderWorld`, `R_RenderFace`, `R_RenderBmodelFace`, `R_StoreEfrags`, and
`R_EmitCachedEdge` each have selectable assembly entries, with C retained as
the release default. `R_RenderPoly` belongs to the optional polygon-driver
branch; normal DOS span rendering leaves `r_drawpolys=0` and `D_DrawPoly()` is
a no-op. The active C closure still includes `R_DrawSubmodelPolygons`,
`R_EdgeDrawing`, edge scanning, and other render-time setup and draw
dependencies. Keep each C reference selectable and retain the exact framebuffer
checksum gate while porting those paths. A C/assembly timedemo capture pair was
byte-for-byte identical, but the reported live-display smear remains open
because the capture checks `vid.buffer`, not DOSBox-X's presented window.
