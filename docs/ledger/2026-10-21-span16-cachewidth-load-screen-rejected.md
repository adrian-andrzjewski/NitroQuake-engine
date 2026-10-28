# D_DrawSpans16 cachewidth-load screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The original
nonzero-T-step setup order remains active in `src/d_draw16.s`.

The experiment moved the independent `cachewidth` load ahead of the S-step
shift in `LNonZeroSetup`, aiming to overlap the memory load with the shift.
The arithmetic and texture-address carry order were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Cachewidth load before shift | `out/dos-timedemo-20261021-082133/timedemo-result.json` | 15.537288 / 15.537297 / 15.537290 | 15.537291667 | 0.000009 |

The screen delta was **−0.000008333 FPS (−0.00005363%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. Exact output parity held,
but the negative pooled mean did not qualify for a strict promotion build; the
original instruction order was restored.
