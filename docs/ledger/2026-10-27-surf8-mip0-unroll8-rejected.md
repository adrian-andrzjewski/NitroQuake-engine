# Mip-0 surface-block unroll8 rejected (2026-10-27)

Status: rejected after a strict three-run timedemo; `SurfaceBlockMip0Rows=unroll16` remains the default.

The candidate selected `-SurfaceBlockMip0Rows unroll8` against the current renderer sources. It passed the pinned DOSBox-X i486 ISA and parity gates, but its pooled mean was lower than the accepted control.

## Evidence

- Build root: `out/local-dos-timedemo-20261027-surf8-mip0-unroll8-strict`
- Timedemo result: `out/dos-timedemo-20261027-015949/timedemo-result.json`
- Workload: DOSBox-X 2026.08.31, `demo1`, three uninstrumented runs, pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`
- Candidate samples: `15.984376`, `16.106421`, and `16.106432` FPS; pooled mean `16.065743000` FPS and median `16.106421` FPS.
- Accepted control samples: `16.107101`, `16.107111`, and `16.107108` FPS; pooled mean `16.107106667` FPS and median `16.107108` FPS.
- Difference: `-0.041363667` FPS (`-0.256804%`) in pooled mean.
- Every run rendered 969 frames with framebuffer checksum `1047377823`.
- ISA audit passed: 313,676 linked renderer instructions, 403 source proofs, 529 startup instructions, and 9,207 DPMI-provider instructions; no above-i486, unknown, or exempted instructions.

The current source remains unchanged and the default remains `unroll16`. No commit was made because this candidate did not increase FPS.
