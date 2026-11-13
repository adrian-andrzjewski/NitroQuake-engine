# Mip-1 fixed-block terminal branch removed (2026-11-13)

## Change

R_DrawSurfaceBlock8_mip1 emits eight statically expanded scanlines per mip-1
block. The final carry branch after those rows was removed: its 0x7 seed and
0xF step leave no carry after the eighth row, so it could not return to the
eight-row body. The block contents, light updates, texture reads, colormap
lookups, framebuffer stores and depth behavior are unchanged.

## Exact output parity

Control and candidate used DOSBox-X 2026.08.31, the pinned 320x200 i486 profile
(532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA),
demo1 and the same data. The fixed-clock replays completed 969 timed frames
with final framebuffer checksum 1047377823. All 970 color records, all 970
Z records and the frame-169 PCX matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksum stream | FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C |
| Z checksum stream | 4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37 |
| Frame-169 PCX | 28E8D79CE925D4ACA40EF1EC56B21292A624CF814C809A8E8E826A0D89CE1C01 |

## Strict i486 gates

The release and qbench executables passed their complete strict i486 gates:
165,058 and 317,486 relocated instructions, respectively. Each audit reported
zero above-i486, unknown, or exempt instructions; the 529-row startup and
9,207-instruction DPMI-provider proofs passed.

| Executable | SHA-256 |
| --- | --- |
| Release | BFEFFD88AD2115CA5D8DE8CE2874C5B293A11CA1E07CD9B6A6DA3036D5BD7491 |
| qbench | 0C16F3777D84D8C46514AC4C50E39E916754D81607A55F9AC7BCAEB157C47C6E |

## Matched timing

Three alternating uninstrumented demo1 pairs used the same 969-frame workload,
final checksum gate and pinned DOSBox-X profile. Checksum capture and per-frame
FPS instrumentation were disabled during timing.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.240578 / 16.928550 | 57.236841 / 16.929655 |
| 2 | 57.240503 / 16.928573 | 57.236791 / 16.929671 |
| 3 | 57.240573 / 16.928551 | 57.236790 / 16.929671 |

The mean increased from 16.928558 to 16.929665667 FPS
(+0.001107667 FPS, +0.0065432%). Every candidate sample beat its matched
control. This is a pinned DOSBox-X result, not a physical-486 performance
claim.

## Artifacts

- Fixed-clock parity results:
  benchmarks/out/dos-timedemo-20261112-222709/timedemo-result.json and
  benchmarks/out/dos-timedemo-20261112-222920/timedemo-result.json
- Timedemo result JSONs:
  benchmarks/out/dos-timedemo-20261112-223429/timedemo-result.json,
  benchmarks/out/dos-timedemo-20261112-223548/timedemo-result.json,
  benchmarks/out/dos-timedemo-20261112-223704/timedemo-result.json,
  benchmarks/out/dos-timedemo-20261112-223820/timedemo-result.json,
  benchmarks/out/dos-timedemo-20261112-223936/timedemo-result.json, and
  benchmarks/out/dos-timedemo-20261112-224052/timedemo-result.json
- Release executable:
  quake/out/local-surf8-mip1-terminalbranch-release-20261112/quake.exe
- qbench executable:
  quake/out/local-surf8-mip1-terminalbranch-qbench-20261112/qbench.exe
