# R_ClipEdge world vertex projection cache (2026-11-03)

Status: promoted after a positive three-run uninstrumented 320x200 DOSBox-X mean, exact paired framebuffer and per-frame checksum parity for `demo1-vga-full`, and the complete strict i486 audit.

## Change

When both `R_RenderFace` and `R_RenderWorld` use the assembly implementation, world traversal now keeps a 128-slot direct-mapped cache of `LTransformAndProject` results for the two original endpoints of the current edge. The cache is cleared once per world traversal and is active only around `R_RecursiveWorldNode`. Clip-generated vertices and calls outside that traversal continue through the original calculation.

Cache entries are keyed by the exact vertex address and store `u`, `lzi`, and `v` as 80-bit x87 values. A hit reloads those values in the same x87 stack order as the original routine returns. This removes repeated projection work without changing the projection arithmetic. The code uses 486-compatible integer and x87 instructions.

## Benchmarks

Both variants used DOSBox-X 2026.08.31, the same pinned i486 profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, `demo1`, the `aggressive` optimization profile, assembly `R_RenderFace` and `R_RenderWorld`, and uninstrumented 320x200 runs. Each run rendered 969 frames, ended with checksum `1047377823`, and recorded identical gameplay event traces.

| Variant | FPS samples | Mean | Median | Range |
| --- | --- | ---: | ---: | ---: |
| Control | 16.458232 / 16.458232 / 16.458125 | 16.458196333 | 16.458232 | 0.000107 |
| Projection cache | 16.466967 / 16.466864 / 16.466865 | 16.466898667 | 16.466865 | 0.000103 |

The cache gained **0.008702333 FPS (+0.052875%)** over the matched control mean. This is a DOSBox-X result; no physical 486 measurement is claimed.

- Control: `out/dos-timedemo-20261103-043137/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261103-051417/timedemo-result.json`

## Pixel parity and i486 compatibility

The paired `demo1-vga-full` comparison ignored the first six warm-up checksums and matched all 964 remaining per-frame checksums in each of two runs. Both 320x200 frame captures matched exactly: 0 of 64,000 pixel indices differed, and all palette bytes matched. This validates the tested scene and does not claim coverage of every map or view.

The complete i486 gate passed: 314,467 linked instructions, exactly one i486 instruction, zero above-i486, unknown, exempt, or unaccounted instructions; 529 startup code rows; 9,207 provider instructions; and 403 exact source proofs.

- Paired parity: `out/render-parity-20261103-043640/render-parity-result.json`
- Build root: `out/local-projection-cache-candidate-20261103/`
- ISA report: `out/local-projection-cache-candidate-20261103/isa-qbench/isa-audit-linked.json`

## Reproduction

Run the uninstrumented candidate screen with:

```powershell
rtk proxy pwsh -NoProfile -File tools/timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -RenderFaceImplementation asm -RenderWorldImplementation asm -Runs 3 -NoBootstrap -AutoexecCommandsJson '["host_framerate 0.05","con_notifytime 0"]'
```
