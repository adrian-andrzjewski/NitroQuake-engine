# Reject `current_iv` load interleave in `TrailingEdge` (2026-10-26)

The parity-screen candidate moved the `current_iv` load to after the old
`last_u` had been stored into `espan_t_u`, using `%edx` before the span-count
store. This tested whether the load could overlap the count write in the
trailing-edge emit path. The change added no instructions.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
candidate used byte-for-byte copies of `pak0.pak` and `pak1.pak` because the
original PAK hardlink source had reached the filesystem link limit.

| Variant | Artifact | FPS samples | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-150012` | 15.948144 / 15.948137 / 15.948150 | 15.948143667 | 0.000013 |
| `TrailingEdge` interleave screen | `out/dos-timedemo-20261026-161855` | 15.948109 / 15.948132 / 15.948138 | 15.948126333 | 0.000029 |

Every run completed 969 frames with framebuffer checksum `1047377823`. The
candidate mean was **−0.000017333 FPS** against control, so the schedule is
rejected and the original load order is restored. This was a visual-parity
screen only (`isaAuditStatus=SKIPPED`), not an i486 promotion candidate.

Candidate source-tree fingerprint:
`1394F3B4EE07521FE5040088BA98BB547559DB07582E666D1671C6D1811D7AC7`.
The restored control source tree is
`93263CFB3C70E98579EAB64A825AF165175A8918225611ED82B8F8C6256EF3F0`.
