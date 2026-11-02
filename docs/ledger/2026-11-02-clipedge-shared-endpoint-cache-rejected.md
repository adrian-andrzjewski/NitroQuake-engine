# ClipEdge shared-endpoint distance cache rejected (2026-11-02)

## Profile rationale

`R_ClipEdge` in `src/r_drawa.s` recomputes both endpoint-to-plane distances for
each edge. Consecutive surfedges in a face share an endpoint, suggesting that
the first active frustum-plane distance for the previous edge's end vertex
could be reused as the next edge's start distance. The initial profile counted
215,714 `R_RenderFace` calls and 637,588 active clip-plane flags, but reported
zero `clipedge_calls` because its counter was in the C reference clipper while
the selected DOS renderer uses the assembly clipper.

Profile-only counters were added to the assembly path and a corrected profile
was captured at `out/dos-timedemo-20261102-153152/quake/PROFILE.JSN`. Across
969 frames it measured 789,751 assembly clipper calls, 1,479,014 edge/plane
tests, 430,873 fully clipped pairs, and 130,706 crossings. The remaining
917,435 tests had both endpoints inside. Thus there were 1.873 plane tests per
call, and 8.84% of tests crossed a plane. The profile's final framebuffer
checksum was `1047377823`; its instrumented 12.093781 FPS is not a performance
benchmark because profiling counters and timers add overhead.

## Candidate and correctness condition

Two opt-in implementations cached only the first-plane distance for the
previous endpoint. The first checked the active plane pointer inside the
clipper's plane loop. The second moved that check to a first-plane entry path.
Both scoped cache state to one `R_RenderFace` edge loop, cleared it at face
entry, and disabled it before the synthetic left/right closing edges.

Surfedge ordering makes the previous edge's `pv1` equal to the next edge's
`pv0`. Reuse was allowed only when those pointers matched and the clip-plane
head was the same. The cached value was stored as a single-precision float from
the existing x87 dot-product sequence, then loaded into the same `Ld0` slot
used by the normal clipper. That preserves the sign-test input bit-for-bit;
crossing distances, later planes, and synthetic vertices still used the
original code.

## Benchmark and correctness evidence

The macro-off control samples were 16.458121, 16.458332, and 16.458223 FPS
(median 16.458223), using the pinned DOSBox-X 2026.08.31 `cputype=486` profile,
320x200 `demo1`, fixed `host_framerate 0.05`, and `con_notifytime 0`.

| Variant | FPS samples | Median | Change from control |
|---|---|---:|---:|
| Plane check in clip loop | 16.420513, 16.420531, 16.420527 | 16.420527 | -0.22904% |
| First-plane entry path | 16.402678, 16.402473, 16.402165 | 16.402473 | -0.33874% |

All six candidate runs completed 969 frames with framebuffer checksum
`1047377823` and matching event traces. No frame capture or complete per-frame
color/Z checksum comparison was made, so these results do not prove exact
pixel parity. The first variant passed the strict i486 audit (314,479 linked
instructions, 529 startup rows, 9,207 DPMI-provider instructions, and zero
above-i486, unknown, or exempt instructions). The second was an exploratory
`-VisualParityOnly` timing run and did not receive the renderer ISA audit.

Timing artifacts: first variant `out/dos-timedemo-20261102-151856`, second
variant `out/dos-timedemo-20261102-152503`; the matched control is
`out/dos-timedemo-20261102-134028`. The first variant's historical invocation
was:

```powershell
rtk proxy pwsh -NoProfile -Command '& { & .\tools\timedemo-dos.ps1 -CpuTarget i486 -RenderFaceImplementation asm -ClipEdgeSharedEndpointCache shared -Runs 3 -NoBootstrap -AutoexecCommandsJson ''["host_framerate 0.05","con_notifytime 0"]'' }'
```

The refined run added `-VisualParityOnly`. Both temporary assembly paths and
their selector plumbing were restored. Reusing one endpoint distance did not
save enough x87 work to offset cache checks and state traffic, so neither
variant is retained. The profile-only assembly counters are guarded by
`PROFILE486`; release builds do not execute their increments. A model-wide
eager cache is also unattractive: `maps/start.bsp` contains 7,757 vertices, so
evaluating four plane distances for all of them would require 31,028 dot
products per frame, versus about 3,053 endpoint distance dot products per
frame observed in the current clipper. This is a work estimate, not a measured
cache implementation. A lazy cache would need evidence that enough distinct
vertices are revisited within the same plane context to repay lookup and
invalidation costs.
