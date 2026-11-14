# Span16 `sfracf` reload before S-step shift screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
S-step-shift then `sfracf` reload order remains active in `src/renderer/d_draw16.s`.

The experiment moved the `sfracf` reload before the independent S-step shift
in `LSetUpCommon`. The `advancetable` store remained between the reload and
T-step shift; all fixed-point arithmetic was unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted control | `out/dos-timedemo-20261021-103344/timedemo-result.json` | 15.537290 / 15.537300 / 15.537308 | 15.537299333 | 0.000018 |
| Reload before S-step shift | `out/dos-timedemo-20261021-110023/timedemo-result.json` | 15.537280 / 15.537289 / 15.537290 | 15.537286333 | 0.000010 |

The parity-screen delta was **−0.000013000 FPS (−0.00008367%)**. All six
runs retained exact frame/checksum parity. The candidate was `VisualParityOnly`,
so its ISA audit was skipped; the negative mean did not qualify for strict
validation, and the promoted ordering was restored.
