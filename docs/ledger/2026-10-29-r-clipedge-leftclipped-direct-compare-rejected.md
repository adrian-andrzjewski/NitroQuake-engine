# `R_ClipEdge` left-clipped direct compare rejected (2026-10-29)

Status: rejected and restored after an uninstrumented three-run parity screen.

The both-clipped path replaced the `r_leftclipped` load into `%eax` plus register `test` with `cmpl $0,C(r_leftclipped)`. The condition and `jnz` branch were unchanged. The candidate source was fingerprinted as `B8D190A815191F3108F28B495E07A14B7D36E8CC3448F1B20DA15AA5E36FBEFA`.

The runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed parent strict control | `out/dos-timedemo-20261029-025046/timedemo-result.json` | 16.312509 / 16.312549 / 16.312500 | 0.000049 | 16.312519333 |
| Candidate parity screen | `out/dos-timedemo-20261029-025719/timedemo-result.json` | 16.316076 / 16.316083 / 16.190616 | 0.125467 | 16.274258333 |

The candidate mean was **0.038261 FPS slower (−0.23454991%)** than the committed parent. The third sample took 59.849484 seconds; the first two took 59.389280 and 59.389254 seconds. The pooled mean is negative, so the change was rejected and the original load/test sequence restored. The parity-only result records `isaAuditStatus=SKIPPED`; no strict run was made.
