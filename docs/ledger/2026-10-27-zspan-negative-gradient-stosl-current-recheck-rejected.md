# Negative-gradient Z-span nonnegative-pair STOSL current-source recheck (2026-10-27)

Status: rejected and restored after exact framebuffer parity and a complete
strict i486 audit, because the three-run mean was below the matched control.

In `ZSPAN_SUB_PAIR_NONNEGATIVE`, the candidate used `STOSL` for the packed-pair
store on the i486 path while preserving the MOV and LEA sequence for the i386
fallback. This recheck used the current source after the related Z-span store
optimizations had landed. The strict mean regressed, so MOV and LEA are restored.

The matched runs used DOSBox-X 2026.08.31, `demo1`, three uninstrumented runs,
CWSDPMI SHA-256
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, and the
pinned 32 MB i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |
| Strict candidate | `out/dos-timedemo-20261027-001931/timedemo-result.json` | 16.107093 / 16.107107 / 16.107106 | 16.107102000 | 16.107106 |

The candidate mean was 0.000004667 FPS below control (0.0000290%). All three
candidate runs retained the exact 969-frame checksum. The complete strict
i486 gate passed: 314,298 relocated instructions, 529 startup code rows, and
9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions. Source mapping covered 435 source-bound contributions, 2,376
CODE ranges, and 35 DATA ranges. The result records `visualParityOnly=false`
and `isaAuditStatus=PASS`. No optimization commit was made because the measured
FPS did not increase.
