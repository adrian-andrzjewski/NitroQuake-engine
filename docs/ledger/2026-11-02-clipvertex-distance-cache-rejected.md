# World vertex-plane distance cache rejected (2026-11-02)

## Profile measurement

To test whether a lazy cache could reuse the exact x87 distance for a map
vertex, `PROFILE486` instrumentation counted the world-model vertex IDs passed
to assembly `R_ClipEdge`. It counted only `R_RenderFace` edges with an active
clip-plane chain and reset its 65,536-bit seen set at each host frame. Across
969 frames, the run recorded 1,290,294 endpoint uses and 416,492 distinct
vertex IDs within their respective frames: 3.10 endpoint uses per distinct
vertex ID. The corrected clipper counters in the same profile were 789,751
calls, 1,479,014 plane tests, 430,873 full rejects, and 130,706 crossings.

The profile was `out/dos-timedemo-20261102-173844/quake/PROFILE.JSN`, under the
pinned DOSBox-X 2026.08.31 `cputype=486` profile, `demo1`, 320x200, and fixed
`host_framerate 0.05`. Its 12.009041 FPS is instrumented and is not a timing
result. The vertex-only reuse ratio does not count repeated `(vertex, plane)`
pairs, so it does not establish a cache hit rate or justify the cache cost.

## Cache trial and rollback

A prototype cached the original single-precision endpoint distances by map
vertex, clip-plane slot, and `r_framecount`, leaving synthetic clipped vertices
on the original x87 path. The first build exposed an unsupported three-operand
`.comm` form in the DJGPP COFF assembler; after switching the storage to aligned
BSS, the candidate built. The timedemo then stopped at frame 372 without
producing its required `TIMEDEMO.TXT`. The user also reported visible rendering
artifacts. The cache implementation and its call-site state were removed. The
cause of the mismatch was not isolated, and no candidate FPS result is valid.

## Restoration evidence and decision

With the cache removed, the pinned visual-parity timedemo completed all 969
frames, ended at framebuffer checksum `1047377823`, and reported the expected
event trace. Its independent per-frame checksum stream differed from the
earlier baseline in 17 frames; the reason for that cross-run variation was not
established, so this is not a per-frame pixel-equivalence claim. The separate
three-run uninstrumented control remained 16.458229 FPS median. The restoration
run used `-VisualParityOnly`, which skips the linked i486 ISA audit.

Keep the profile-only endpoint and unique-vertex counters for future
measurements. Do not retain or promote the cache. A retry first needs an
isolated per-vertex/per-plane hit profile and a completed pixel-parity run.
