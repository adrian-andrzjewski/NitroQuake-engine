# General Z-span subtract-pair store with STOSL (2026-10-26)

Status: promoted in `src/d_draw.s` after exact framebuffer parity, a positive
strict mean, and the complete i486 ISA gate.

The `ZSPAN_SUB_PAIR` fallback subtracts the depth step before writing each
packed pair. Its i486 store now uses `STOSL` in place of `MOVL` plus `LEAL`,
while the `TARGET_I386` fallback retains the original sequence. `STOSL` writes
the packed pair to the destination and advances EDI by four without changing
flags.

The comparison used DOSBox-X 2026.08.31, `demo1`, three runs per variant,
CWSDPMI, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261026-211705/timedemo-result.json` | 16.107096 / 16.107107 / 16.107102 | 16.107101667 | 16.107102 |
| Strict candidate | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 | 16.107108 |

The strict mean increased by `0.000005` FPS. The candidate result records
`visualParityOnly=false` and `isaAuditStatus=PASS`. The full i486 proof passed:
314,317 relocated instructions, 529 startup code rows, and 9,207 provider
instructions, with zero above-i486, unknown, or exempt instructions. Source
mapping covered 435 contributions, 2,376 CODE ranges, and 35 DATA ranges.
