# Texture-span `loadfirst` recheck (2026-10-20)

Status: measured; not promoted because the current matched samples show no
repeatable gain. `TextureSpanLoadOrder=control` remains the default.

`loadfirst` starts the current texel load before the independent fixed-point S/T
accumulator updates. The sample order, carry-producing updates, and packed
destination stores remain unchanged. This selector was remeasured after the
promotion policy removed the 0.05% floor because its earlier result was inside
run variation.

All runs used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and uninstrumented timedemos. Every run completed 969 frames
with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Current control, first six | `out/dos-timedemo-20261020-190238/timedemo-result.json` | 62.390208 / 62.390171 / 62.390172 / 62.390210 / 62.390211 / 62.390168 | 15.531283 / 15.531293 / 15.531293 / 15.531283 / 15.531282 / 15.531294 | 15.531288000 |
| `loadfirst`, first six | `out/dos-timedemo-20261020-194038/timedemo-result.json` | 62.390273 / 62.390203 / 62.390182 / 62.390150 / 62.390200 / 62.390168 | 15.531267 / 15.531285 / 15.531290 / 15.531297 / 15.531285 / 15.531294 | 15.531286333 |
| Current control, follow-up three | `out/dos-timedemo-20261020-194834/timedemo-result.json` | 62.390258 / 62.390204 / 62.390213 | 15.531271 / 15.531284 / 15.531282 | 15.531279000 |
| `loadfirst`, follow-up three | `out/dos-timedemo-20261020-195223/timedemo-result.json` | 62.390267 / 62.390188 / 62.390225 | 15.531269 / 15.531289 / 15.531279 | 15.531279000 |
| Trailing current control | `out/dos-timedemo-20261020-195609/timedemo-result.json` | 62.390240 | 15.531275 | 15.531275000 |

Across all samples, ten control runs averaged **15.531284 FPS** and nine
`loadfirst` runs averaged **15.531283889 FPS**. Their medians were 15.531283
and 15.531285 FPS, respectively; this tiny median difference is inside the
observed ranges. The fresh three-run blocks had identical means, and the
trailing control was slower than the preceding control block, consistent with
small host drift rather than a repeatable selector gain.

The six initial `loadfirst` runs and follow-up runs used `-VisualParityOnly`, so
the renderer ISA audit was skipped. The current control executable in the first
six-run artifact has a passing strict audit. Since `loadfirst` produced no
repeatable performance gain, it was not rebuilt as a strict promotion
candidate. The existing selector remains available for later remeasurement.
