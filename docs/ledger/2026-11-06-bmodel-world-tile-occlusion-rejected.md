# Brush-model world-tile occlusion rejected (2026-11-06)

## Candidate and profile

The candidate projected each visible inline brush model's bounding sphere into
screen space, then reused the accepted 4-by-4 alias tile minimum-Z cache before
brush transforms, dynamic-light marking, and edge submission. It skipped a
model only when every tile in the expanded projected rectangle had a minimum
Z greater than the sphere's nearest-depth bound. The implementation added a
4-pixel screen margin and 8 units of reciprocal-depth headroom, and was wired
into both frame-control assembly bodies and the C oracle.

The instrumented 969-frame `demo1` replay at
`out/dos-timedemo-20261106-052440` recorded 2,310 queries, 894 model culls,
326,623 tile checks, and 2,726,888 Z samples. The matching pre-change control
is `out/dos-timedemo-20261106-012532`. Both used the same DOSBox-X 2026.08.31
486 profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`host_framerate 0.0783`, `-zchecksums`, and frame capture index 482.

## Exact-output gate

Both streams contain 971 rows, but 54 color rows and 52 Z rows differ. The
first mismatch is frame 56. The captured frame 482 PCX is byte-identical
(SHA-256 `82abcb38389d68e1c5c96658b66680c3ab52d50755c384f85ad1df772d760c8d`),
and both runs finish at framebuffer checksum `1047377823`; neither point
sample overrides the intermediate-frame mismatches.

The run used `-VisualParityOnly -Instrumentation`, so it is diagnostic output,
not release timing or an ISA promotion result. No uninstrumented A/B was run
after the exact-output failure.

## Disposition

Remove the brush-model query. Its projected sphere test is not proven
conservative for this renderer, and the observed color and Z stream changes
violate the pixel-exact requirement. The alias tile cache remains scoped to
the alias-model path that passed its own exact-output gate.
