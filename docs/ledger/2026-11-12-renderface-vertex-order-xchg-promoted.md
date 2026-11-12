# R_RenderFace vertex-order register swap promoted (2026-11-12)

<!-- optimization-attempt: renderface-vertex-order-xchg accepted -->

## Candidate

The clipped world and submodel edge loops now load vertex indices in their
natural endpoint order, compare the signed surfedge in memory, and use
`xchgl %eax,%edx` only for reversed edges. This removes the positive-edge
path's unconditional jump while preserving the ordered endpoints passed to
`R_ClipEdge`.

## Exact rendering and i486 compatibility

Control and candidate used Build 874 and the pinned DOSBox-X 2026.08.31 i486
profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).
The fixed-clock `demo1` replay completed 969 frames with final framebuffer
checksum `1047377823`. All 970 color records, all 970 Z records, and the
frame-169 320x200 PCX matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 169 PCX | `28E8D79CE925D4ACA40EF1EC56B21292A624CF814C809A8E8E826A0D89CE1C01` |

The candidate passed complete strict i486 gates for both executables:

- qbench: 317,056 relocated instructions, 529 startup rows, and 9,207 DPMI
  provider instructions; zero above-i486, unknown, or exempt instructions.
- Release: 164,642 relocated instructions, 529 startup rows, and 9,207 DPMI
  provider instructions; zero above-i486, unknown, or exempt instructions.

## Matched timing

Three alternating uninstrumented `demo1` pairs used the same profile, scene,
969-frame count, and final-checksum gate. FPS collection and frame checksum
capture were off for these timing runs:

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.299774 / 16.911061 | 57.296017 / 16.912170 |
| 2 | 57.299773 / 16.911061 | 57.295937 / 16.912194 |
| 3 | 57.299708 / 16.911081 | 57.295955 / 16.912188 |

The candidate mean was **16.912184000 FPS** versus **16.911067667 FPS** for
control (**+0.001116333 FPS, +0.0066012%**). Candidate FPS exceeded control in
all three pairs. Control time spread was 0.000066 s; candidate spread was
0.000080 s. A trailing control at 57.299808 s was 0.000056 s slower than the
initial control mean, showing negligible drift. This is pinned DOSBox-X
evidence, not a physical-486 performance claim.

## Artifacts and host checks

- Control qbench: `workspace\quake\out\local-local-renderface-vertex-xchg-control2-20261112\qbench.exe`
- Candidate qbench and release: `D:\NitroQuake-renderface-vertex-xchg-20261112\out\local-local-renderface-vertex-xchg-candidate-20261112\qbench.exe` and `D:\NitroQuake-renderface-vertex-xchg-20261112\out\local-local-renderface-vertex-xchg-release-candidate-20261112\quake.exe`
- Parity handoffs and all seven timing JSON files: `workspace\benchmarks\out\renderface-vertex-xchg-*-20261112.json`
- Run logs, staged inputs, and raw checksum files remain under `workspace\benchmarks\out\dos-timedemo-20261112-*`.

The candidate checkout's host-only game suite reported 7 passes and 5 existing
failures: ledger heading counts, profile/build selector goldens, a sysinfo
source-pattern assertion, and the video harness's missing native host GCC.
These checks do not involve the changed assembly file and were left untouched.
