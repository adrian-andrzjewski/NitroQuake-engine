# Span16 common store before `sfracf` reload screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
`sfracf`-then-store order remains active in `src/d_draw16.s`.

The experiment moved the `advancetable` store ahead of the `sfracf` reload in
`LSetUpCommon`, keeping it before the T-step fractional shift. The address
value and subsequent arithmetic were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted control | `out/dos-timedemo-20261021-103344/timedemo-result.json` | 15.537290 / 15.537300 / 15.537308 | 15.537299333 | 0.000018 |
| Store before `sfracf` reload | `out/dos-timedemo-20261021-105519/timedemo-result.json` | 15.537293 / 15.537283 / 15.537289 | 15.537288333 | 0.000010 |

The parity-screen delta was **−0.000011000 FPS (−0.00007080%)**. All six
runs matched the expected frame count and checksum. The candidate was
`VisualParityOnly`, so its ISA audit was skipped; the negative mean did not
qualify for strict validation, and the promoted instruction order was restored.
