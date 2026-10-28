# Reject the fourth-probe early-out branch layout

The legacy `R_InsertNewEdges` search was changed to test the fourth edge before
loading its successor. This saves the fifth-edge load when insertion stops at
the fourth probe, but long searches add an unconditional jump. Exact checksum
parity and the full strict i486 audit passed; the matched mean was negative, so
the original fourth-probe `JG` fallthrough is restored.

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
| Early-out before successor load | 15.599252, 15.599260, 15.488363 | 15.562291667 | 0.110897 |

The candidate loses **0.038651333 FPS (-0.24774998%)**. Every candidate sample
is slower than every control sample. The third run is an outlier, but no
separate cause was established, so it remains included in the mean. The
negative mean does not qualify under the any-positive promotion rule.

The complete strict i486 audit passed: 313,320 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-055023/timedemo-result.json`
- Candidate build and ISA reports: `out/local-scan-insert-probe4-earlyout-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `5EDD00638A66F4AF52F5D84D0842C9004A67676E7449D696983900C5BBBE52AB`
