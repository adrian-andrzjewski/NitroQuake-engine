# Alias depth store before texel load screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
depth-store position after the texture load remains active in `src/d_polysa.s`.

The experiment moved each passing pixel's Z-buffer store immediately after its
depth comparison and before loading the texture byte. It covered the sixteen
unrolled pixels and the one-pixel span path. Color lookup, pixel order, and the
Z-test condition were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted control | `out/dos-timedemo-20261021-103344/timedemo-result.json` | 15.537290 / 15.537300 / 15.537308 | 15.537299333 | 0.000018 |
| Depth store before texel load | `out/dos-timedemo-20261021-104440/timedemo-result.json` | 15.537280 / 15.537290 / 15.537289 | 15.537286333 | 0.000010 |

The parity-screen delta was **−0.000013000 FPS (−0.00008367%)**. The output
checksum matched on all six runs. The candidate screen was `VisualParityOnly`,
so its ISA audit was skipped; its negative mean did not qualify for strict
validation, and the promoted source ordering was restored.
