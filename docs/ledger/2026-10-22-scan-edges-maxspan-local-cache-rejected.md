# Reject caching `max_span_p` in a scan-loop local

The `R_ScanEdges_asm486` candidate copied the computed span-buffer limit into
`-36(%ebp)` and compared against that short frame-local operand on every row.
It passed exact checksum parity and the full strict i486 audit, but its pooled
mean was below the cached-surface-base control, so the global comparison stays
active.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the same i486 assembly selector profile. The runs were
uninstrumented with per-frame FPS collection disabled. All six runs rendered
969 frames with checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Cached surface-base control | 15.600949, 15.600939, 15.600941 | 15.600943 | 0.000010 |
| Local `max_span_p` limit | 15.600934, 15.600940, 15.600925 | 15.600933 | 0.000015 |

The candidate loses **0.000010 FPS (-0.00006410%)**. Its negative pooled mean
does not qualify under the any-positive promotion rule.

The complete strict i486 audit passed: 313,320 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-051956/timedemo-result.json`
- Candidate build and ISA reports: `out/local-scan-maxspan-local-cache-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `D847ED7CE1DD2C6E3CB7EFF17CABD6796473F2A085FC0250E7A243DFE28C6730`
