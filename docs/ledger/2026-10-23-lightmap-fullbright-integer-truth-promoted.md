# Promote integer truth checking in the i486 lightmap builder

`R_BuildLightMap` now tests `r_fullbright.value` with an integer shift. Shifting
the IEEE-754 word left discards its sign bit and sets ZF only for positive or
negative zero. All nonzero values, including subnormals and NaNs, remain true,
matching C float truth without the x87 status-word sequence.

The candidate was measured against the x87 control in the same aggressive i486
selector profile, with `TurbulentImplementation=fourteen`. Both used the pinned
32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`7BAFA8C2F2521B94967F73C5D7663076DC31B934C7EBFE0E5F1C841416E2DE52`; the
candidate fingerprint was
`2334123C4A1F796B65CF809A1E9905D1EA73881565AFFC75741526BC32F8DE85`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| x87 control | 15.607060 / 15.607061 / 15.607049 | 15.607056667 | 0.000012 |
| integer shift | 15.607463 / 15.607446 / 15.607448 | 15.607452333 | 0.000017 |

The candidate gains **0.000395667 FPS (+0.00253518%)**. Every candidate run
exceeded every control run. All six runs rendered 969 frames with framebuffer
checksum `1047377823`.

The source-bound i486 ISA gate passed: 313,928 relocated executable
instructions, 529 startup code rows, and 9,207 external DPMI-provider
instructions were verified with zero exemptions or above-i486 instructions.

Artifacts:

- Strict candidate build: `out/local-i486-lightmap-truth-shift-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-092836/`
- Matched control runs and baseline: see
  `2026-10-23-turbulent-span-fourteen-loop-release-default.md`
