# Dynamic-light bit-mask kept in EDI (2026-10-28)

Status: promote the register-held sparse-light scan. The loop now loads
`dl_surface_dlightbits` into `EDI` once, tests and clears the lowest set bit in
that register, and avoids reloading and writing the remaining mask through the
stack for each active light. The `BSF` and `mask &= mask - 1` behavior is
unchanged. The `-16(%ebp)` local remains unused to preserve the existing frame
layout. Both assembly callees preserve `EDI`; the C sample fallback follows the
i386 callee-saved register ABI.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. All renderer selector values matched exactly, including
`DynamicLightOrchestrationImplementation=asm` and
`LightMapBuildImplementation=c`. Every run rendered 969 frames with framebuffer
checksum `1047377823`.

| Variant | Per-run FPS | Mean FPS | Median FPS | Spread |
|---|---|---:|---:|---:|
| Control | 16.240114 / 16.240103 / 16.240111 | 16.240109333 | 16.240111 | 0.000011 |
| EDI mask | 16.240111 / 16.240118 / 16.240110 | 16.240113 | 16.240111 | 0.000008 |

The candidate mean increased **0.000003667 FPS (+0.00002258%)**. A fourth
control run measured 16.240116 FPS, a +0.000005 FPS drift from the control
median. The candidate and control medians tie, and the gain is smaller than the
sample spread and trailing-control drift. The current promotion rule accepts
any positive mean after three uninstrumented matched samples, so the change is
promoted with that measurement limitation recorded.

The strict candidate build passed the complete i486 gate: 313,519 relocated
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions;
zero above-i486, unknown, or exempt instructions. Exact selector manifests and
the DOSBox profile SHA matched the control. The source-tree fingerprint changed
only for the assembler edit.

Control runs:

- `out/dos-timedemo-20261028-100501/timedemo-result.json`
- `out/dos-timedemo-20261028-103555/timedemo-result.json`
- `out/dos-timedemo-20261028-103835/timedemo-result.json`
- trailing control: `out/dos-timedemo-20261028-104123/timedemo-result.json`

Candidate runs and full build evidence:

- `out/dlight-edi-candidate-20261028/out/dos-timedemo-20261028-103419/timedemo-result.json`
- `out/dlight-edi-candidate-20261028/out/dos-timedemo-20261028-103716/timedemo-result.json`
- `out/dlight-edi-candidate-20261028/out/dos-timedemo-20261028-103955/timedemo-result.json`
- strict audit: `out/dlight-edi-candidate-20261028/out/profile-fa28e7e4ae5f00c9/isa-qbench/`
