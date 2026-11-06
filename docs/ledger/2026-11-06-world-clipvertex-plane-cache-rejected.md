# World clipvertex plane-distance cache rejected (2026-11-06)

## Candidate

The world edge clipper used a 64-slot direct-mapped distance cache for each of
the four view planes. Each entry paired an exact world-vertex address with the
binary32 clip distance, for 2 KiB of tag and distance storage. The cache was
active only while rendering the world model and handled endpoint hits
independently.

The preceding [capacity census](2026-11-06-clipvertex-plane-cache-capacity-census.md)
predicted 59.18% endpoint hits at this size, but those counts measured
opportunities rather than the cost of the runtime lookup path.

## Validation

The candidate qbench passed the strict i486 audit: 315,442 relocated
instructions, with no above-target, unknown, or exempt instructions. The
control was the clean renderer at 2b8be3a; both variants used the pinned
DOSBox-X 486 profile, 320x200 demo1, host_framerate 0.0783, frame checksums,
Z checksums, and a frame-482 capture.

Control runs were out/clipedge-distance-cache-rejected/control-170818 and
control-173715. Candidate runs were
out/dos-timedemo-20261106-172314 and 174053. Each run completed 969 timed
frames and ended at framebuffer checksum 1047377823. The captured frame 482
PCX was byte-identical.

Both candidate runs differed from both controls in framebuffer checksum rows
254, 458, 472, 655, 695, and 938. The control repeat varied at frames 727-730;
the candidate repeat varied at 729-731. Color and Z differences in that late
window therefore cannot establish exact parity. The remaining six recurring
framebuffer mismatches fail the all-frame parity gate despite the matching
final checksum and captured frame. Z checksum differences were limited to
that late variable window.

These checksum-enabled runs are diagnostic only. Their reported FPS is not
performance evidence, and no uninstrumented timing A/B was run after parity
failed.

## Disposition

Remove the runtime cache. Preserve the census as a hit-rate model, not proof
that the cache is profitable or output-exact. Retain the control evidence in
out/clipedge-distance-cache-rejected/ and the candidate timedemo outputs in
their original out/dos-timedemo-* directories.
