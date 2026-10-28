# Negative-depth subtract-pair STOSL parity screen (2026-10-26)

Status: rejected at the parity screen; the original `MOVL` plus `LEAL` store
is restored in `src/d_draw.s`.

The experiment replaced the store in `ZSPAN_SUB_NEGATIVE_PAIR` with `STOSL`
for the i486 path while retaining the `TARGET_I386` sequence. The comparison
used DOSBox-X 2026.08.31, `demo1`, the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, 969
frames, and framebuffer checksum `1047377823` for every sample.

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Promoted strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 |
| Candidate parity screen 1 | `out/dos-timedemo-20261026-215647/timedemo-result.json` | 16.107085 / 16.107105 / 15.984032 | 16.066074000 |
| Candidate parity screen 2 | `out/dos-timedemo-20261026-220038/timedemo-result.json` | 16.107092 / 16.107105 / 16.107096 | 16.107097667 |

The repeat screen averaged `0.000009` FPS below the promoted control, so the
candidate was not sent to the full strict audit. Both candidate artifacts
record `visualParityOnly=true` and `isaAuditStatus=SKIPPED`; they prove frame
and checksum parity only.
