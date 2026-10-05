# Brush-model polygon clipping assembly port

Status: ongoing renderer port. This entry records the selectable conversion of
`R_RecursiveClipBPoly`; it does not close the software-renderer conversion or
establish that the user-reported wall leak is fixed.

## `R_RecursiveClipBPoly` now has a selectable i486 assembly entry

`BmodelPolygonClipImplementation=c|asm` selects the recursive brush-model BSP
polygon clipper. The C routine remains the default and benchmark reference. The
assembly path transforms each splitter plane into model space, classifies and
splits linked edges, creates intersection vertices and opposite-winding clip
boundary edges, visits visible BSP children, and dispatches visible leaf faces.
The selected C build asserts the 32-bit pointer size and every vertex, edge,
plane, node, leaf, and surface offset read by assembly. The benchmark C copy
recurses through itself, so the reference does not silently enter the assembly
path. Review caught and corrected a reversed stack layout for the temporary
plane-normal vector before the final assembly run; its components now occupy
the three consecutive addresses read by the x87 dot product.

The selector is wired through build, smoke, benchmark, and timedemo manifests.
`tools/test-build-dos.py` passed with the i486 and i386 golden flags unchanged.
The i486 assembly build linked and passed the ISA gate, and its release binary
passed DOS smoke. Under the pinned DOSBox-X 2026.08.31 profile, the corrected
assembly candidate completed 969 `demo1` frames in `59.233076 s` with checksum
`1047377823`. The C selector, rebuilt from the same source tree, completed the
same frame count in `59.170256 s` with the same checksum. These are single
samples, not an alternating benchmark; no speedup is claimed and C remains the
release default.

## `demo1` wall leak traced to the split fraction and fixed

Matched intermediate captures reproduced the user's missing wall and streak
artifacts in the assembly clipper. Its x87 sequence divided in the wrong
direction: for `lastdist = 2` and `dist = -2` it produced `2.0`, while the C
expression requires `0.5`. The off-plane intersection vertices multiplied the
edge list until `Out of edges for bmodel` aborted clipping. Switching the
sequence to `fdivrp` computes `lastdist / (lastdist - dist)` correctly.

The same `demo1` capture point now shows the wall and floor intact. The C
reference log had zero edge overflows, the pre-fix assembly log had 17, and the
corrected assembly log has zero. The corrected candidate also passes the
pinned 969-frame timedemo with checksum `1047377823` (one run: `59.449346 s`,
`16.299591 fps`). The broader assembler port remains ongoing; C remains the
release default, and this timedemo sample is not an alternating performance
comparison.
