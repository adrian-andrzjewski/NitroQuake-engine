# Reject preloading the second edge-step successor

The legacy `R_StepActiveU` candidate moved `et_next(%esi)` before the second
probe's order check. This made the successor available on the continuing path,
but also loaded it when the edge was pushed back. Exact checksum parity and the
complete strict i486 audit passed. The negative pooled mean restores the
original post-branch load.

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
| Existing second-probe schedule | 15.600949, 15.600939, 15.600941 | 15.600943 | 0.000010 |
| Successor preload before order check | 15.600558, 15.600572, 15.600565 | 15.600565 | 0.000014 |

The candidate loses **0.000378 FPS (-0.00242293%)**. Every candidate sample is
slower than every control sample by at least **0.000367 FPS**, so this
preload is rejected.

The complete strict i486 audit passed: 313,319 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-064353/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-step-second-next-prefetch-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `0AB5F168E6226D72E89851C09D1D62D7031350B16A3809F89B8633B65DFDB4E4`
