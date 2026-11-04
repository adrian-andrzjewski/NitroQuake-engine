# World-span depth hierarchy for alias occlusion rejected (2026-11-04)

Status: rejected. Both tile layouts failed exact per-frame color parity, so no
implementation or timing claim is retained.

## Candidate

The prototype built a coarse depth-and-coverage map after drawing opaque world
and brush spans. It reused the span lists and inverse-depth gradients already
produced by the renderer, then queried projected alias-model bounds before
alias rasterization. The existing BSP/PVS visibility path remained in place;
the prototype only attempted whole-model entity rejection. Models smaller
than 64 triangles, clipped bounds, and bounds touching the screen edge bypassed
the query.

The first layout used 8x8 tiles. The refinement used 32x4 tiles with a larger
screen-bound expansion and depth safety margin. Both variants ran through the
assembly-owned renderer path and passed the complete strict i486 audit with no
above-i486, unknown, or exempt instructions.

## Deterministic parity results

The control and candidates used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, 320x200 output, and 970 fixed-step frame-checksum records. All three
ended at framebuffer checksum `1047377823`.

| Run | HZB layout | Span fragments | Queries | Tile tests | Model rejects | Color frames differing | Z frames differing | Instrumented FPS |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Control `out/dos-timedemo-20261104-155958` | disabled | — | — | — | 0 | 0 | 0 | 7.208912 |
| Candidate `out/dos-timedemo-20261104-161651` | 8x8 | 7,072,007 | 2,974 | 9,408 | 997 | 51 | 0 | 6.150634 |
| Candidate `out/dos-timedemo-20261104-163922` | 32x4 | 2,780,865 | 2,974 | 3,067 | 12 | 27 | 0 | 6.628082 |

The refined candidate's frame stream differs from control beginning at frame
25. Its Z stream is byte-identical to control. Both candidates therefore fail
the pixel-exact gate despite matching the final checksum. The instrumented FPS
values are diagnostic only, not valid timing comparisons; their lower values
also provide no reason to schedule uninstrumented runs after the parity
failure.

## Disposition and evidence

The prototype source was removed. Its hierarchy bookkeeping added substantial
span-fragment work, while the refined layout reduced useful rejection to 12
models across 2,974 queries. The experiment does not justify a follow-up
implementation; BSP/PVS remains the renderer's spatial visibility structure.

The ignored `out` results listed above are retained, including each timedemo
report, frame color and Z checksums, captured frame, build manifest, and strict
ISA reports. The source-object audit for the refined build covered 285,012
instructions; the linked executable audit covered 323,309 relocated
instructions, plus 529 startup code rows and 9,207 provider instructions, all
with zero above-i486, unknown, or exempt instructions.
