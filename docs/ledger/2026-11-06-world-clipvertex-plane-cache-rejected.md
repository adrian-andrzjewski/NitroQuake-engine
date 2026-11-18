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
control was the clean renderer at 19088c5f65cd; both variants used the pinned
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

## Sign-only world side-cache follow-up (2026-11-06)

### Candidate

The follow-up stored one exact sign bit per world-vertex/view-plane pair in a
64-slot direct-mapped table. It skipped the original paired x87 distance work
only when both original world endpoints were present and had the same cached
sign. Misses and opposite-sign pairs ran the original distance sequence, so
crossing interpolation stayed unchanged. The tables used 1,280 bytes total
(1,024 bytes of vertex tags and 256 bytes of signs).

### Build and i486 proof

The strict `-Benchmark -CpuTarget i486` build passed at
`out/local-clip-side-sign-cache-20261106b/`. Its linked audit verified 315,424
instructions across 403 source-proven objects and 435 executable code ranges,
plus 529 startup rows and 9,207 DPMI-provider instructions. There were no
above-i486, unknown, or exempt instructions.

### Parity evidence

Two checksum runs used the pinned DOSBox-X 2026.08.31 486 profile, `demo1`, no
autoexec commands, `-framechecksums`, `-zchecksums`, and a frame-482 PCX capture.
Both candidate runs completed 969 timed frames with final framebuffer checksum
`1047377823`. Candidate color streams matched each other except at frames
727-731, the late variability window also seen in the controls. Against both
control repeats, the candidate color stream differed at
`254, 458, 472, 655, 695, 727-731, 938`; the six rows outside the known late
window were stable mismatches. Both candidate Z streams matched each other and
both controls outside frames 727-731. The frame-482 PCX hash matched all four
runs: `82ABCB38389D68E1C5C96658B66680C3AB52D50755C384F85AD1DF772D760C8D`.

The final runs are in `out/dos-timedemo-20261106-185635/`; controls are in
`out/clipedge-distance-cache-rejected/control-170818/` and
`control-173715/`. The timedemo runner now retains each requested Z stream as
`runs/run-*/framezchecksums.txt`; the report confirms 970 checksum rows per run.

### Disposition

Reject and remove the sign-only cache because of the six stable framebuffer
mismatches. The Z stream and selected capture do not waive the all-frame color
parity requirement. No uninstrumented A/B timing was run, and the
checksum-enabled FPS values are not performance evidence.
