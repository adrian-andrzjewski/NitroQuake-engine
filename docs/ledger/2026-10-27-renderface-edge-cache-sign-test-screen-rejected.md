# R_RenderFace edge-cache sentinel sign-test screen rejected (2026-10-27)

Status: rejected and restored after an uninstrumented three-run parity screen.

In the hot `R_RenderFace` edge loop, the candidate replaced the immediate mask
test `testl $0x80000000,%eax` with the shorter `testl %eax,%eax` and changed
the following `je` to `jns`. The sign test observes the same high bit without
modifying `%eax`, but the measured screen regressed, so the original test is
restored. No strict ISA run or commit was warranted.

The matched runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI SHA-256
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, and the
pinned 32 MB i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |
| Sign-test parity screen | `out/dos-timedemo-20261027-003113/timedemo-result.json` | 16.107077 / 16.107088 / 16.107093 | 16.107086000 | 16.107088 |

The screen mean was 0.000020667 FPS below control (0.0001283%). All runs
retained the exact checksum. The result records `visualParityOnly=true` and
`isaAuditStatus=SKIPPED`; the negative screen means the candidate did not
proceed to the strict i486 gate.
