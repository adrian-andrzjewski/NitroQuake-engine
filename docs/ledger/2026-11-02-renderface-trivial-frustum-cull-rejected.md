# RenderFace trivial frustum-face cull rejected (2026-11-02)

## Profile rationale

An instrumented 320x200 `demo1` profile recorded 215,714 `R_RenderFace`
calls and 104,618 emitted surfaces, making it reasonable to test whether some
faces could be rejected before edge traversal. The report's corrected
instrumented self-time attributed 8.05% to `renderface` and 7.78% to
`edge-scan`; these are profiling proportions, not uninstrumented timing
results. The profile is retained at
`out/dos-timedemo-20261102-141635/quake/PROFILE.JSN`.

Other leading corrected self-time shares were texture spans 22.79%, surface
cache 8.85%, Z spans 8.54%, and alias rasterization 3.96%. The profiler's
timer-read cost was 5.779 microseconds (193.3 emulated cycles), so use its
relative hotspot report to choose experiments, not its inflated FPS.

## Candidate and rejection condition

The temporary `R_RenderFaceTrivialCull` check inspected every surfedge start
vertex. For each active frustum plane, it rejected a face when every vertex
was farther outside that same plane than a conservative floating-point error
margin. A half-space is convex, so if all polygon vertices are outside one
plane, the polygon edges and their convex hull are outside it as well. The
assembly `R_RenderFace` path called this C precheck before edge clipping.

The condition was conservative by design, but the precheck repeated surfedge
and vertex loads and plane-distance arithmetic before the normal edge walk.
It did not amortize those distances across faces.

## Correctness and compatibility evidence

All timedemo runs completed 969 frames with final framebuffer checksum
`1047377823` and matching event traces. The candidate's complete per-frame
Z-checksum stream matched the reference stream (SHA-256
`ADD0639C313F2C5C5C86677FA927724F67D9ED20468874306AC045B3E47B77DD`).
However, exact color parity was not established: candidate and the later
control diagnostic differed in 61 of 971 per-frame color-checksum records,
while repeated controls also differed. Candidate frame 137's PCX hash was
`5ED1442F205B16B8FFF70860F8F2AB79642D6DFD1C6B65EDA3CC631BB53527D8`; a
later control capture produced
`31EB09D434D6DF22F8DB5A569C33C104856DD6EB6D71CF16FB254429BB48F705`,
although the candidate capture matches earlier control captures. This
run-to-run discrepancy leaves color parity unresolved; it is not evidence of
a candidate-specific visual change.

The candidate passed the strict linked i486 audit: 314,584 linked
instructions, 529 startup rows, and 9,207 DPMI-provider instructions, with
zero above-i486, unknown, or exempt instructions. DOSBox-X compatibility is
verified; no physical 486 measurement was made.

## Benchmark and disposition

The three-run timing used DOSBox-X 2026.08.31, `cputype=486`, the pinned
`tools/dosbox-x-486-high.conf` profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, `host_framerate 0.05`, and `con_notifytime 0`.

| Variant | FPS samples | Median |
|---|---|---:|
| Control | 16.458121, 16.458332, 16.458223 | 16.458223 |
| Trivial face cull | 16.371065, 16.370862, 16.370966 | 16.370966 |

The candidate lost 0.087257 FPS (-0.53017%). Its timing result is
`out/dos-timedemo-20261102-144100/timedemo-result.json`; the frame/Z diagnostic
is `out/dos-timedemo-20261102-144624`, and the comparison control diagnostic is
`out/dos-timedemo-20261102-145117`. The historical candidate invocation was:

```powershell
rtk proxy pwsh -NoProfile -Command '& { & .\tools\timedemo-dos.ps1 -RenderFaceImplementation asm -RenderFaceTrivialCull trivial -Runs 3 -NoBootstrap -AutoexecCommandsJson ''["host_framerate 0.05","con_notifytime 0"]'' }'
```

The candidate code and temporary selector were restored. No optimization is
retained. A more promising follow-up, still untested, is to compute per-frame
vertex clip outcodes once at the point where transformed vertices are made,
then reject a face when all of its vertices share an outside-plane bit. This
could amortize plane-distance work across neighboring faces, but needs a
verified vertex/plane lifetime and a measured reduction in total work before
it can be considered.
