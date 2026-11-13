# `R_ClipEdgeRegs` stack-base store hoisted across each face (2026-11-12)

## Change

`R_RenderFace_asm486` now computes and stores the private clipper stack base
once before entering either world or submodel edge loop. `R_ClipEdgeRegs` keeps
its existing register saves but no longer writes the same stack pointer on
every call. The public cdecl `R_ClipEdge` entry still records its own stack
base for C callers. The shared epilogue continues to discard temporary clipper
locals and restore the saved registers.

The detailed `demo1` profile recorded 789,805 clipper calls across 969 frames.
The profile is diagnostic evidence; its instrumented frame rate was not used
for the performance comparison.

## Exact output parity

Control and candidate used the pinned DOSBox-X 2026.08.31 i486 profile. Both
completed 969 timed frames and ended at framebuffer checksum `1047377823`. All
969 color and Z records and the captured frame-169 PCX matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksum stream | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksum stream | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 169 PCX | `28E8D79CE925D4ACA40EF1EC56B21292A624CF814C809A8E8E826A0D89CE1C01` |

## Strict i486 gates

The qbench executable passed the complete strict i486 audit with 317,426
linked instructions, 529 startup rows, and 9,207 DPMI-provider instructions.
The release executable passed with 165,012 linked instructions and the same
startup/provider counts. Both audits reported zero above-i486, unknown, or
exempt instructions.

## Matched timing

Three alternating uninstrumented `demo1` pairs used the same 320x200 workload,
969 timed frames, final checksum gate, and pinned DOSBox-X profile. Frame and Z
checksum instrumentation was disabled during timing.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.254537 / 16.924423 | 57.245891 / 16.926979 |
| 2 | 57.254456 / 16.924447 | 57.245881 / 16.926982 |
| 3 | 57.257385 / 16.923581 | 57.245928 / 16.926969 |

The mean increased from 16.924150333 to 16.926976667 FPS (**+0.002826333 FPS,
+0.0167000%**). Every candidate sample exceeded its matched control. This is
pinned DOSBox-X evidence, not a physical-486 performance claim.

## Artifacts

- Fixed-clock parity result:
  `benchmarks/out/dos-timedemo-20261112-125854/timedemo-result.json`
- Control timing results:
  `benchmarks/out/dos-timedemo-20261112-130335/`,
  `.../dos-timedemo-20261112-130612/`, and
  `.../dos-timedemo-20261112-130845/`
- Candidate timing results:
  `benchmarks/out/dos-timedemo-20261112-130453/`,
  `.../dos-timedemo-20261112-130728/`, and
  `.../dos-timedemo-20261112-131003/`
