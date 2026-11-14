# RenderFace signed-surfedge register reuse rejected (2026-11-11)

<!-- optimization-attempt: renderface-signed-surfedge-register-reuse rejected -->

## Candidate

The world-edge and submodel loops in `R_RenderFace_asm486` reload each signed
surfedge from `-4(%esi)` on the clipping path, then test it to select vertex
order. The candidate copied the signed value from `EAX` to `EDX` after `LODSL`
and reused it at that test. The regular edge-cache check used `EAX` for its
temporary edge pointer and refreshed the current cache offset on a miss so
`EDX` remained live on every path into clipping.

That adds one register move to every edge iteration to remove a memory reload
from clipping paths. The experiment changed only `src/renderer/asm486_experiments.s`;
the candidate source was restored after measurement.

### Exact rendering and i486 compatibility

Control and candidate used Build 867, the selectable i486 assembly profile,
`demo1`, and the pinned DOSBox-X 2026.08.31 486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Both
used `host_framerate 0.0783` and `d_subdiv16 1` for the deterministic replay.

Both builds passed the complete strict i486 gate. The control had 316,137
relocated instructions; the candidate had 316,138. The candidate also passed
the 529-row startup and 9,207-instruction DPMI-provider checks, with zero
above-i486, unknown, or exempt instructions. Both replays passed the committed
frame-169 image tolerance with 12 changed pixels.

Each replay completed 969 timedemo frames with final framebuffer checksum
`1047377823`. All 970 color-checksum records, all 970 Z-checksum records, and
the captured 320x200 frame-169 PCX matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `E00B1C297ACCFB4C161DBB8F2448CBAF48CFABCCD3AC1DA98EBC836515B8F8CA` |
| Z checksums | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 169 PCX | `D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96` |

### Matched timing

Three uninstrumented runs per variant used the same deterministic commands,
DOSBox-X profile, frame count, and final-checksum gate:

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.931061 / 16.931061 / 16.931061 | 16.931061000 |
| Candidate | 16.925579 / 16.925583 / 16.925579 | 16.925580333 |

The candidate mean was **0.005480667 FPS lower (-0.0323705%)**. Control spread
was zero, candidate spread was 0.000004 FPS, and the trailing control returned
to 16.931061 FPS with zero drift. The register-reuse change is rejected. These
DOSBox-X timings do not establish physical-486 performance.

### Artifacts and disposition

- Control build: `D:\NitroQuake-render-audit-20261111\out\profile-00a02b679118056f\`
- Candidate build: `D:\NitroQuake-renderface-signed-reuse-20261111\out\profile-9d388e64f1e9a6e0\`
- Parity, timing samples, summary, and candidate patch: `workspace\benchmarks\out\renderface-signed-reuse-20261111\`

The candidate worktree is back at the control source revision. Its generated
build and the benchmark artifacts remain available for review.
