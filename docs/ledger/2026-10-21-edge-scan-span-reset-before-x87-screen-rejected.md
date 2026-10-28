# Edge-scan span reset before x87 setup screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The original row
setup order remains active in `src/asm486_experiments.s`.

The experiment moved the independent surface span-state reset ahead of each
scanline's x87 coordinate setup in both the main-row and final-row paths.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Span reset before x87 | `out/dos-timedemo-20261021-084819/timedemo-result.json` | 15.537291 / 15.537304 / 15.537291 | 15.537295333 | 0.000013 |

The screen delta was **−0.000004667 FPS (−0.00003004%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. Exact output parity held,
but the negative pooled mean rejected the schedule; the original row setup
order was restored.
