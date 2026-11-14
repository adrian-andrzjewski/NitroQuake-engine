# Span16 high-byte load before T-carry capture rejected (2026-10-26)

Status: rejected at the parity screen; the six source-byte loads are restored
to their promoted positions in `src/renderer/d_draw16.s`.

The experiment moved six later high-byte texel loads in the default Span16
word-store path to immediately after `addl tstep,%edx` and before
`sbbl %ecx,%ecx`. The intervening `MOVB` preserves the T-step carry; the S-step
addition and indexed `ADC` remained in their original order. The already
promoted first A-half high-byte fetch was unchanged.

The comparison used DOSBox-X 2026.08.31, `demo1`, the pinned i486 profile
SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, 969
frames, and framebuffer checksum `1047377823` for every sample.

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Promoted strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 |
| Candidate parity screen 1 | `out/dos-timedemo-20261026-221104/timedemo-result.json` | 16.107083 / 16.107106 / 16.107100 | 16.107096333 |
| Candidate parity screen 2 | `out/dos-timedemo-20261026-221451/timedemo-result.json` | 16.107083 / 16.107107 / 16.107088 | 16.107092667 |

The repeat screen remained `0.000014` FPS below the promoted control, so the
candidate was not sent to the full strict audit. Both candidate artifacts
record `visualParityOnly=true` and `isaAuditStatus=SKIPPED`; they prove frame
and checksum parity only.
