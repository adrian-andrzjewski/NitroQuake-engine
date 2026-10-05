# Submodel polygon assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of `R_DrawSubmodelPolygons`; it does not close the software-renderer
conversion or its render-time dependency closure.

## `R_DrawSubmodelPolygons` now has a selectable i486 assembly entry

`SubmodelPolygonsImplementation=c|asm` selects the brush-model surface loop.
The C implementation remains the release default and benchmark reference. The
assembly loop walks `model->surfaces` from `firstmodelsurface`, evaluates the
model-origin/plane dot product with x87, applies `BACKFACE_EPSILON` and
`SURF_PLANEBACK`, updates `r_currentkey`, and calls the selected
`R_RenderFace`. Compile-time layout checks pin the 32-bit model, surface, plane,
entity, and leaf fields used by the assembly routine.

The selector contract passed with the i486 and i386 default build flags still
golden-pinned. DOS smoke passed with the assembly selector. The combined
renderer candidate completed the pinned 969-frame `demo1` timedemo with
checksum `1047377823` in `58.258137 s`. A matching build with only this
selector changed to C completed the same 969 frames with the same checksum in
`59.170319 s`. These are single samples rather than an alternating comparison;
they do not establish a speedup, and C remains the release default.

The first live-capture pair used a fixed number of `wait` commands. The C and
assembly screenshots landed at different demo moments, so their image
difference is not a renderer parity result. Both captured scenes were coherent
and neither reproduced the reported smear or page fault. The exact executable
from the supplied fault screenshot is not identified; visual acceptance for
this selector remains pending a matched-frame capture of that reproduction.

## Remaining submodel-polygon closure

`R_EdgeDrawing`, edge scanning, B-model polygon traversal, and other active
render-time setup and draw dependencies remain to be converted. Keep the C
reference selectable and use the pinned framebuffer checksum while porting
those paths.
