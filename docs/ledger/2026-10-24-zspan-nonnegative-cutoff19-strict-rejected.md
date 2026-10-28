# D_DrawZSpans nonnegative fast-path cutoff 19 (2026-10-24)

Status: rejected after the full strict three-run gate.

The 19-pixel visual-parity screen was faster than the accepted 18-pixel
control. The strict three-run set retained exact output and passed the full
i486 audit, but its second timing sample was substantially slower and pulled
the pooled mean below control. The source was restored to the 18-pixel cutoff;
this candidate was not promoted.

All runs used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, 18-pixel cutoff | `out/dos-timedemo-20261024-002538/timedemo-result.json` | 61.313929 / 61.314009 / 61.313947 | 15.803913 / 15.803892 / 15.803909 | 15.803904667 | 15.803909 | 969 / `1047377823` every run |
| Screen, 19-pixel cutoff | `out/dos-timedemo-20261024-003522/timedemo-result.json` | 61.313191 / 61.313062 / 61.313045 | 15.804103 / 15.804137 / 15.804141 | 15.804127000 | 15.804137 | 969 / `1047377823` every run |
| Strict, 19-pixel cutoff | `out/dos-timedemo-20261024-005744/timedemo-result.json` | 61.313193 / 61.776293 / 61.313006 | 15.804102 / 15.685628 / 15.804151 | 15.764627000 | 15.804102 | 969 / `1047377823` every run |

The strict candidate mean was **0.039277667 FPS slower** (**0.24853%**) than
control, despite a higher median. The screen mean was 0.000222333 FPS higher.
The strict linked i486 audit passed: 314,024 relocated instructions, 529
startup code rows, and 9,207 DPMI provider instructions, with zero instructions
above i486, unclassified instructions, or exemptions. The strict result's
source fingerprints were source
`F40513F1B7B32C08CB198E1FB002F8054F877584D7E12FA55C5B5FA6BC31A133`, tree
`786BA4952A98C28780C282C3499CB833F7AB1DAD78E407620E9CB1820CA08182`.
