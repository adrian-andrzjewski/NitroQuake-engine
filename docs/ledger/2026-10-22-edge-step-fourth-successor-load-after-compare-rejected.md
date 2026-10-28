# Reject moving the fourth edge-step successor load after the order compare

The legacy `R_StepActiveU` candidate moved the fourth probe's required
`et_next(%esi)` load from before the order check to between the compare and
`jnl LNextEdge`. `MOV` preserves the compare flags. Exact checksum parity and
the complete strict i486 audit passed. The negative pooled mean restores the
original load slot.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the same i486 assembly selector profile, including
`EdgeListMaintenanceImplementation=legacy`. Runs were uninstrumented with
per-frame FPS collection disabled. All six runs rendered 969 frames with
checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Existing fourth-probe schedule | 15.600949, 15.600939, 15.600941 | 15.600943 | 0.000010 |
| Successor load after compare | 15.600952, 15.600929, 15.600941 | 15.600940667 | 0.000023 |

The candidate loses **0.000002333 FPS (-0.00001496%)**. One candidate sample
beats every control sample, but the pooled mean is negative, so the candidate
is rejected under the any-positive-mean rule.

The complete strict i486 audit passed: 313,319 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-090228/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-step-fourth-load-after-compare-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `EABB76C4F93D9694A36F4FACC068C9712476DA82A81260052B60F14D1EFE35E4`
