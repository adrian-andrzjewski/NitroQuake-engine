# Reject removing the edge-drawing final-scan `TEST`

The final-scan decision in `R_EdgeDrawing_asm486` loads `r_drawpolys`, ORs in
`r_drawculledpolys`, tests the result, then branches. Removing the explicit
`TEST` would use the flags already set by `OR`; output parity and the strict ISA
gate both passed, but the three-run mean was negative, so the instruction stays.

## Matched timedemo

The control and candidate used the same pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and i486 assembly selectors. Both were uninstrumented with per-frame
FPS collection disabled. All six runs rendered 969 frames with checksum
`1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Current branch control | 15.598746, 15.598730, 15.598740 | 15.598738667 | 0.000016 |
| `TEST` removed | 15.598742, 15.598744, 15.483285 | 15.560257 | 0.115459 |

The candidate mean is **−0.038481667 FPS (−0.24669730%)**. Its third sample
took 62.583616 seconds; the first two took 62.120396 and 62.120385 seconds.
No separate cause for the slow sample was established, so it remains part of
the measured mean.

The candidate passed the full linked strict i486 audit: 313,318 relocated
opcodes, 529 startup instructions, and 9,207 DPMI-provider instructions, with
zero above-i486 opcodes, unknown opcodes, or exemptions. Exact checksum parity
also passed. The negative mean rejects the change, and the explicit `TEST` has
been restored.

Artifacts:

- Control: `out/dos-timedemo-20261022-033027/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-035650/timedemo-result.json`
- Candidate build and ISA reports: `out/local-dos-timedemo-dspeeds-finalscan-20261022/`

Source-tree fingerprints:

- Control: `808865633E2841F1A8D31E41B07CD381AAEB6343A2CB95317941989FDA3FAE09`
- Candidate: `FCAAA314A98600DD77C2F500C7213D95E4956D811021B30D3690FA91AA2223E2`
