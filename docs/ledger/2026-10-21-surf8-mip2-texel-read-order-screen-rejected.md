# Mip-2 texel-read order screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted order
that loads texel 2 before texel 3 remains active in `src/surf8.s`.

This screen swapped the two independent source-byte loads at the start of the
general mip-2 surface-block loop, keeping both ahead of the light-delta save
and shift. No other instruction order changed.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted load order (texel 2, then 3) | `out/dos-timedemo-20261021-065729/timedemo-result.json` | 15.537297 / 15.537297 / 15.537306 | 15.537300000 | 0.000009 |
| Swapped load order (texel 3, then 2) | `out/dos-timedemo-20261021-081159/timedemo-result.json` | 15.537298 / 15.537287 / 15.537296 | 15.537293667 | 0.000011 |

The screen delta was **−0.000006333 FPS (−0.00004076%)**. This was a
`VisualParityOnly` run, so its ISA audit was skipped. The negative mean did not
qualify for a strict promotion build; the original promoted load order was
restored.
