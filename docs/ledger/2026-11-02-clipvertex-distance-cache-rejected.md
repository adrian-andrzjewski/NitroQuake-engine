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

## Per-vertex/per-plane reuse profile

A follow-up `PROFILE486` probe counted exact `(world vertex ID, clip-plane
slot)` pairs in the assembly clipper, with a per-frame seen bitset for each
plane. Synthetic vertices were excluded. The capture is
`out/dos-timedemo-20261102-225644/quake/PROFILE.JSN`, using DOSBox-X
2026.08.31, `cputype=486`, 320x200 `demo1`, and 969 timedemo frames. It counted:

| Plane slot | Endpoint uses | Unique pairs | Repeated hits | Hit rate |
|---:|---:|---:|---:|---:|
| 0 | 959,660 | 323,697 | 635,963 | 66.27% |
| 1 | 762,944 | 253,496 | 509,448 | 66.77% |
| 2 | 519,644 | 166,006 | 353,638 | 68.05% |
| 3 | 393,207 | 130,641 | 262,566 | 66.78% |
| Total | 2,635,455 | 873,840 | 1,761,615 | 66.84% |

The profile run reported 9.439039 FPS; this is instrumentation-heavy and is
not a performance result. The final framebuffer checksum matched the pinned
`1047377823` gate, but 37 intermediate checksum records differed from the
earlier independently-run profile stream at
`out/dos-timedemo-20261102-195029`. Cross-run intermediate pixel parity is
therefore unproven; the equal final checksum does not resolve those
differences. The instrumentation build passed the strict i486 audit: 321,846
relocated instructions, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions.

Repeated pairs are common, but this does not overturn the rejected cache
trials: the measured cache variants were slower, and no new cache
implementation or uninstrumented timing was tested. Keep the per-plane
profile counters as diagnostic-only `PROFILE486` instrumentation; do not
promote a distance cache without a separate completed pixel-parity run and
repeatable 320x200 timing gain.

## One-entry-per-plane locality probe

A second profile pass simulated a one-entry last-world-endpoint cache for each
plane. It visited the clipper's endpoints in order (`pv0`, then `pv1`) and
counted a hit only when the current world vertex matched that plane's most
recent world endpoint. Synthetic vertices remained excluded. The capture is
`out/dos-timedemo-20261102-231726/quake/PROFILE.JSN`:

| Plane slot | Endpoint uses | One-entry hits | Hit rate |
|---:|---:|---:|---:|
| 0 | 959,660 | 283,804 | 29.57% |
| 1 | 762,942 | 224,746 | 29.46% |
| 2 | 519,642 | 152,794 | 29.40% |
| 3 | 393,207 | 116,349 | 29.59% |
| Total | 2,635,451 | 777,693 | 29.51% |

This is a tag-only locality simulation, not a timed cache implementation. The
9.383819 FPS profile is instrumentation-heavy. Its final framebuffer checksum
matched `1047377823`, while 10 checksum records differed from the immediately
prior profile run and 38 differed from the earlier control stream; this is
not cross-run pixel-parity evidence. The linked executable's i486 audit passed
321,491 instructions with zero opcode mismatches, above-i486 instructions,
unknown instructions, or exempt sites.

The one-entry model's hit rate does not overturn the measured first-plane
cache regressions above, which were -0.22904% and -0.33874%. No multi-entry
cache or shared-vector cache was implemented or timed. Keep the probe as
diagnostic-only `PROFILE486` data; do not promote the simple last-endpoint
cache based on hit rate alone.
