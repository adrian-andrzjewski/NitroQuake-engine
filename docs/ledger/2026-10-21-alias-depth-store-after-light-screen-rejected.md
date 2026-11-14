# Alias depth store after light-byte load screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
depth-store position immediately after the texture load remains active in
`src/renderer/d_polysa.s`.

The experiment moved each passing pixel's Z-buffer store after the light-byte
move and before the colormap lookup. It covered the sixteen unrolled pixels
and the one-pixel span path. Z comparison, texture load, color lookup, and pixel
order were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted control | `out/dos-timedemo-20261021-103344/timedemo-result.json` | 15.537290 / 15.537300 / 15.537308 | 15.537299333 | 0.000018 |
| Store after light-byte load | `out/dos-timedemo-20261021-105001/timedemo-result.json` | 15.537296 / 15.537287 / 15.537283 | 15.537288667 | 0.000013 |

The parity-screen delta was **−0.000010667 FPS (−0.00006865%)**. The checksum
matched on all six runs. The candidate was `VisualParityOnly`, so its ISA audit
was skipped; its negative mean did not qualify for strict validation, and the
promoted store ordering was restored.
