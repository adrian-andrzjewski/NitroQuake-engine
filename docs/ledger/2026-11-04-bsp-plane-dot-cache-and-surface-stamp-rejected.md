# BSP plane-dot cache and surface-stamp store suppression rejected (2026-11-04)

These two candidates tried to reuse per-frame BSP work while preserving the
existing traversal and draw order. Both passed the strict i486 gate, but neither
improved the matched uninstrumented timedemo mean. Their source changes were
removed.

## Shared-surface frame-stamp store suppression

The leaf-marking loop now conditionally wrote `msurface_t.visframe` only when
that surface did not already carry the current frame stamp. The test did not
change leaf order, frustum filtering, surface selection, or face drawing.

The instrumented 969-frame replay matched all 970 color and Z records and the
frame-695 PCX exactly. The strict source, linked-object, relocated-executable,
startup, and provider audits passed with zero exemptions. Its diagnostic
profile was neutral in edge scanning and slightly slower in world BSP work:
world-BSP inclusive time was 14.454332 seconds versus 14.434817 seconds, with
identical 215,751 `R_RenderFace` calls.

The three-run uninstrumented control averaged 109.211993 seconds and
8.872651667 FPS. The candidate averaged 109.231318 seconds and 8.871082 FPS,
for a negative 0.001569667 FPS mean delta. The candidate also added a compare
to every leaf surface mark, so it was removed.

In the uninstrumented outputs, all three saved color streams and the final-run
Z stream differed from control only at frames 727-731. The control's own color
runs also varied in that window; the instrumented exact-parity replay is the
available deterministic result.

## Per-frame BSP plane-dot cache

The demo's `e1m3.bsp` has 2,942 BSP nodes referring to 1,615 distinct plane
records; 1,327 node references repeat a plane index. The prototype cached each
plane's exact 64-bit view dot and frame stamp in the second plane-sized region
already reserved by `Mod_LoadPlanes`. The loaded plane's unused padding bytes
held its index and a validity bit. The `model_t` layout remained unchanged,
and non-map or unindexed planes fell back to the original dot calculation.

The candidate passed the complete i486 audit: 168 source objects and 403 linked
objects, with 314,782 relocated instructions, 529 loader rows, and 9,207
provider instructions; there were no above-i486 or unclassified opcodes and no
exemptions.

The control mean was 109.211993 seconds and 8.872651667 FPS. The plane-cache
candidate averaged 109.229657 seconds and 8.871216667 FPS, a negative
0.001435 FPS mean delta. Its three captured frame-695 PCX files matched the
control byte-for-byte. Color and Z streams differed only at frames 727-731;
the saved color streams and final-run Z stream matched on every other recorded
frame. Control color runs also varied in that short window, so those records
are not a deterministic parity signal.
The negative mean disqualified the cache regardless.

## Evidence and disposition

The shared-stamp runs are in `out/dos-timedemo-20261104-194409` (control) and
`out/dos-timedemo-20261104-200209` (candidate); its instrumented profile is in
`out/dos-timedemo-20261104-193002`. The plane-dot runs are in
`out/dos-timedemo-20261104-194409` (control) and
`out/dos-timedemo-20261104-203600` (candidate). The pinned DOSBox-X 2026.08.31
profile hash was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Both candidates are rejected for measured slowdown. The DOSBox timing evidence
does not establish physical-486 performance. No source implementation from
these experiments is retained.
