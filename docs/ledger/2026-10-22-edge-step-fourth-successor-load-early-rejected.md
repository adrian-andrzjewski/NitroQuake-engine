# Reject moving the fourth edge-step successor load earlier

The legacy `R_StepActiveU` candidate moved the fourth probe's required
`et_next(%esi)` load ahead of the U fetch and add. The load remains before the
order check, so the continuation path still needs no extra jump. Exact checksum
parity and the complete strict i486 audit passed. The slightly negative pooled
mean restores the original location after the U addition.

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
| Successor load before U fetch/add | 15.600937, 15.600936, 15.600930 | 15.600934333 | 0.000007 |

The candidate loses **0.000008667 FPS (-0.00005555%)**. Its negative pooled
mean rejects the earlier placement.

The complete strict i486 audit passed: 313,319 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-073923/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-step-fourth-load-early-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `EAD684850FF089813B92CF9061A46720594EC968B034AC812DC27CEE3091AFEA`
