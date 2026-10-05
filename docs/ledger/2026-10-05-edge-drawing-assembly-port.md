# Edge-drawing orchestration assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of `R_EdgeDrawing`; it does not close the software-renderer
conversion or its render-time dependency closure.

## `R_EdgeDrawing` now has a selectable i486 assembly entry

`EdgeDrawingImplementation=c|asm` selects the frame-level edge-drawing
orchestration. The C implementation remains the release default and benchmark
reference. The assembly entry chooses the caller-provided or aligned stack
edge buffer, installs the optional stack surface buffer, begins the edge frame,
runs the selected world renderer, performs culled/world edge scans, enables Z
testing before brush entities, preserves the `r_dspeeds` timestamps and extra
sound update, and closes the edge-drawing profile scope. Compile-time checks
pin `edge_t` and `surf_t` sizes, stack counts, cache alignment, and the cvar
value offset used by assembly.

The selector contract passed with the i486 and i386 default flag lists still
golden-pinned. C and assembly DOS smoke both passed. The assembly build passed
the i486 ISA gate at 168 enforced above-i486 instructions versus the 170
baseline. Its PROFILE486 qbench build also passed the ISA gate at 176 versus
the 177-instruction instrumented baseline.

The pinned `demo1` timedemo completed 969 frames with checksum `1047377823` in
`59.171652 s`. The matching C candidate completed with the same checksum in
`59.170319 s`. These single samples do not establish a speed gain; C remains
the release default.

Live playdemo captures from both paths showed the same room and camera
framing, with no frame trails or persistent smear. The captures were taken
after fixed `wait` counts and therefore landed at slightly different moving
entity/demo states: the second PCX pair differed in 14,927 of 64,000 decoded
pixels. This is not exact-frame parity evidence. The supplied page fault was
not reproduced, and its exact staged executable remains unidentified.

## Remaining edge-drawing closure

`R_ScanEdges`, brush-entity polygon clipping, and other active render-time
setup and draw dependencies remain to be converted. Keep the C reference
selectable, retain the pinned framebuffer checksum, and compare matched demo
frames for visual acceptance.
