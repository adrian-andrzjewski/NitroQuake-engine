# Span16 base-store before `tfracf` reload screen rejected (2026-10-21)

Status: reverted after a negative three-pair parity screen. The original
`advancetable+4` store order remains active in both Span16 setup arms.

The experiment moved the `advancetable+4` base-address store ahead of the
`tfracf` reload in both the zero and nonzero T-step setup arms. The resulting
address arithmetic and per-pixel carry path were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Each run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-095134`, `095624`, `100055` | 15.537284 / 15.537299 / 15.537289 | 15.537290667 | 0.000015 |
| Store before `tfracf` reload | `out/dos-timedemo-20261021-095357`, `095833`, `100318` | 15.537294 / 15.537289 / 15.537282 | 15.537288333 | 0.000012 |

The paired screen delta was **−0.000002333 FPS (−0.0000150%)**. All six
samples preserved exact output parity. These were `VisualParityOnly` runs, so
the renderer ISA audit was skipped; the negative pooled mean did not qualify
for a strict promotion run, and the original instruction order was restored.
