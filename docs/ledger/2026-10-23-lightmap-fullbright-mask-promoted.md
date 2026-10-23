# Promote direct magnitude-mask testing in the i486 lightmap builder

The `r_fullbright.value` truth test in `R_BuildLightMap` now uses one
`testl` against the float word with the sign bit masked out. ZF is set only for
positive or negative zero; every nonzero value, including subnormals and NaNs,
remains true.

The candidate was measured against the previously committed integer-shift
version in the same aggressive i486 selector profile, with
`TurbulentImplementation=fourteen`. Both used the pinned 32 MB DOSBox-X
profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
shift control mean was `15.607452333 FPS`; its source-tree fingerprint was
`2334123C4A1F796B65CF809A1E9905D1EA73881565AFFC75741526BC32F8DE85`. The
mask measurement used source-tree fingerprint
`DBA93D6460B0F1EAA01BF247E858DA4AB761A30E43A952B5FA4BBB25432F0B86`. After
measurement, the two explanatory comment lines were clarified; the assembled
instructions were unchanged.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| integer shift | 15.607463 / 15.607446 / 15.607448 | 15.607452333 | 0.000017 |
| immediate mask | 15.607526 / 15.607526 / 15.607528 | 15.607526667 | 0.000002 |

The mask gains **0.000074333 FPS (+0.00047627%)**. Every mask run exceeded
every shift run. All six runs rendered 969 frames with framebuffer checksum
`1047377823`.

The source-bound i486 ISA gate passed: 313,926 relocated executable
instructions, 529 startup code rows, and 9,207 external DPMI-provider
instructions were verified with zero exemptions or above-i486 instructions.

Artifacts:

- Strict candidate build: `out/local-i486-lightmap-truth-mask-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-100243/`
- Shift control and measurement: see
  `2026-10-23-lightmap-fullbright-integer-truth-promoted.md`
