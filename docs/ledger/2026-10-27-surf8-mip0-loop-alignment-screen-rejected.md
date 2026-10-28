# `surf8` mip-0 16-row loop alignment screen rejected (2026-10-27)

Status: rejected and restored after an uninstrumented three-run parity screen.

The candidate aligned `Lblockloop8_mip0_rows16` to a 16-byte boundary with
`.p2align 4,,15` for the pinned i486 build. The screen preserved the exact
framebuffer, but its mean regressed; the alignment directive was removed. The
candidate did not proceed to the strict ISA gate.

The matched runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI SHA-256
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, and the
pinned 32 MB i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |
| Mip-0 alignment parity screen | `out/dos-timedemo-20261027-003826/timedemo-result.json` | 16.105743 / 16.105753 / 16.105741 | 16.105745667 | 16.105743 |

The screen mean was 0.001361 FPS below control (0.0084497%). The result records
`visualParityOnly=true` and `isaAuditStatus=SKIPPED`; no optimization commit was
made.
