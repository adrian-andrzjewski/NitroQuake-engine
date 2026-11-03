# R_ClipEdge world vertex projection cache (withdrawn 2026-11-03)

Status: removed from the active renderer. The original speed result used the explicit `nofxch` Z-span schedule. Requalification against the restored `control` schedule found a repeatable checksum mismatch in one paired run set, but a later fixed-cadence rerun matched exactly. This unresolved cross-run disagreement fails the renderer's exact-parity gate.

## Change

The withdrawn change added a 128-slot direct-mapped cache of `LTransformAndProject` results for the two original endpoints of the current world edge when both `R_RenderFace` and `R_RenderWorld` used assembly. It was cleared once per world traversal and active only around `R_RecursiveWorldNode`. The cache code has been removed from `src/r_drawa.s` and `src/asm486_experiments.s`; those files now match the no-cache parent `a364e0a`.

Cache entries are keyed by the exact vertex address and store `u`, `lzi`, and `v` as 80-bit x87 values. A hit reloads those values in the same x87 stack order as the original routine returns. This removes repeated projection work without changing the projection arithmetic. The code uses 486-compatible integer and x87 instructions.

## Benchmarks

The original speed screen used DOSBox-X 2026.08.31, the pinned i486 profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, `demo1`, the `aggressive` optimization profile, assembly `R_RenderFace` and `R_RenderWorld`, explicit `ZSpanStartSchedule=nofxch`, and uninstrumented 320x200 runs. Each run rendered 969 frames and ended with checksum `1047377823`.

| Variant | FPS samples | Mean | Median | Range |
| --- | --- | ---: | ---: | ---: |
| No cache (`nofxch`) | 16.458232 / 16.458232 / 16.458125 | 16.458196333 | 16.458232 | 0.000107 |
| Projection cache (`nofxch`) | 16.466967 / 16.466864 / 16.466865 | 16.466898667 | 16.466865 | 0.000103 |

The cache gained **0.008702333 FPS (+0.052875%)** over the matched no-FXCH mean. This is a DOSBox-X result; no physical 486 measurement is claimed. The gain is not accepted because it was measured with a schedule that is no longer the default and exact parity did not remain consistent during requalification.

- Control: `out/dos-timedemo-20261103-043137/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261103-051417/timedemo-result.json`

## Pixel parity and i486 compatibility

The original paired `demo1-vga-full` comparison ignored the first six warm-up checksums and matched all 964 remaining checksums in each of two runs under explicit `nofxch`. Both VGA captures had 0 of 64,000 changed pixels and matching palettes.

During later requalification against `control`, two paired run sets differed at checksum index 412: candidate `542392344`, no-cache baseline `3788779729`. Each build repeated its own stream exactly. A subsequent fixed-cadence rerun produced exact full-stream parity (964 of 964 compared frames) and 0 of 64,000 changed pixels in the captured frame. The conflicting results are unresolved, so the cache is rejected rather than treated as pixel-exact.

The historical cache build passed the complete i486 gate: 314,467 linked instructions, exactly one i486 instruction, zero above-i486, unknown, exempt, or unaccounted instructions; 529 startup code rows; 9,207 provider instructions; and 403 exact source proofs. The later visual-parity replays used `-VisualParityOnly` and skipped ISA auditing; the active renderer source was restored to the no-cache parent implementation.

- Paired parity: `out/render-parity-20261103-043640/render-parity-result.json`
- Requalification mismatch: `out/projection-cache-baseline-evidence-20261103/control-mismatch-run-01-comparison.json` and `control-mismatch-run-02-comparison.json`
- Later cache rerun: `out/projection-cache-baseline-evidence-20261103/cache-rerun-run-01-checksums.json`, `cache-rerun-run-02-checksums.json`, and the corresponding `cache-rerun-run-01-image.json` / `cache-rerun-run-02-image.json`
- Restored no-cache renderer verification: `out/projection-cache-baseline-evidence-20261103/restored-run-01-checksums.json`, `restored-run-02-checksums.json`, and the corresponding image comparisons; both post-warmup streams match all 964 frames and both frame-412 PCXs match all 64,000 pixels
- Build root: `out/local-projection-cache-candidate-20261103/`
- ISA report: `out/local-projection-cache-candidate-20261103/isa-qbench/isa-audit-linked.json`

## Reproduction

The original uninstrumented `nofxch` candidate screen was run with:

```powershell
rtk proxy pwsh -NoProfile -File tools/timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -RenderFaceImplementation asm -RenderWorldImplementation asm -ZSpanStartSchedule nofxch -Runs 3 -NoBootstrap -AutoexecCommandsJson '["host_framerate 0.05","con_notifytime 0"]'
```
