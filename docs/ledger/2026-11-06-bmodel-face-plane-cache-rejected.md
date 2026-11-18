# Brush surface-facing cache rejected (2026-11-06)

## Candidate

The `R_DrawSolidClippedSubmodelPolygons` loop recomputes the same plane dot
product when a brush model has multiple surfaces sharing one BSP plane. The
prototype cached each plane's side-specific visibility result in the two
reserved `mplane_t::pad` bytes, tagged by a generation advanced once per model
draw. It retained the original floating-point comparisons, epsilon thresholds,
and NaN behavior.

## Exact-output and i486 gates

The control and candidate used the pinned DOSBox-X 2026.08.31 i486 profile
(SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, `host_framerate 0.0783`, per-frame framebuffer checksums, and
Z checksums. The control was built from source commit `4bc0d1dd6134`; it has the same
renderer sources as the current base because the intervening source commit
records documentation only.

The Z-buffer streams matched across 970 frames (971 file rows including the
summary), as did the frame-482 PCX. The final framebuffer checksum also matched
at `1047377823`. The framebuffer stream differed only at frame 254:

| Output | Control | Candidate |
| --- | --- | --- |
| Frame 254 checksum | `3473345858` | `2662957370` |
| Framebuffer stream SHA-256 | `e00b1c297accfb4c161dbb8f2448cbaf48cfabccd3ac1da98ebc836515b8f8ca` | `2a90e4975dc608ae226da623748292ebb910a2382ef6298dd4d2993a4baded95` |
| Z-buffer stream SHA-256 | `1b41d2ab5b0fc99fcca5158c51e4d7b9028cbf4c3ec8dfdf32c6ab96c2db85e8` | same |
| Frame 482 PCX SHA-256 | `82abcb38389d68e1c5c96658b66680c3ab52d50755c384f85ad1df772d760c8d` | same |

The candidate passed the complete strict i486 gate: 315,249 relocated
instructions, 529 startup code rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions.

## Conclusion

Reject the cache because the intermediate framebuffer stream is not pixel
exact. The final checksum and one captured frame do not cover the frame-254
color difference. No uninstrumented timing comparison was run after the parity
failure. The prototype source was reverted; diagnostic builds and captures
remain under the ignored `out` directory.
