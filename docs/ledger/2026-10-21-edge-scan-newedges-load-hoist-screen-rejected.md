# Edge-scan newedges-load hoist screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The original row
setup order remains active in `src/asm486_experiments.s`.

The experiment hoisted the current row's `newedges` pointer load ahead of the
x87 coordinate conversion, then used `%edx` for the independent surface
span-state reset. The pointer value and row data were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Newedges load hoist | `out/dos-timedemo-20261021-085458/timedemo-result.json` | 15.537297 / 15.537283 / 15.537298 | 15.537292667 | 0.000015 |

The screen delta was **−0.000007333 FPS (−0.00004720%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. Exact output parity held,
but the negative pooled mean rejected the load hoist; the original row setup
order was restored.
