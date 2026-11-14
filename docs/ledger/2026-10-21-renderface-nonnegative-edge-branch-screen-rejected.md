# RenderFace nonnegative-edge branch screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
positive-edge branch layout remains active in `src/renderer/asm486_experiments.s`.

The experiment changed both regular and submodel surfedge loops from a
strict-positive branch to a nonnegative branch. A zero surfedge therefore
reached the same direct address calculation as a positive surfedge, preserving
the edge address while bypassing the negate-and-fallback path.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Nonnegative branch | `out/dos-timedemo-20261021-084200/timedemo-result.json` | 15.537291 / 15.537295 / 15.537291 | 15.537292333 | 0.000004 |

The screen delta was **−0.000007667 FPS (−0.00004935%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. Exact output parity held,
but the negative pooled mean rejected the branch condition; the original
strict-positive branch was restored.
