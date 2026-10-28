# D_DrawZSpans nonnegative fast-path cutoff 17 (2026-10-24)

Status: rejected by the three-run visual-parity performance screen.

This screen lowered the accepted i486-only nonnegative-span fast-path cutoff
from 18 pixels to 17. It retained exact frame output, but its mean was below
the current 18-pixel strict control, so the source was restored to 18 without
running the full ISA audit.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and uninstrumented timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 18-pixel cutoff | `out/dos-timedemo-20261024-002538/timedemo-result.json` | 61.313929 / 61.314009 / 61.313947 | 15.803913 / 15.803892 / 15.803909 | 15.803904667 | 969 / `1047377823` every run |
| Screen, 17-pixel cutoff | `out/dos-timedemo-20261024-003042/timedemo-result.json` | 61.315142 / 61.314982 / 61.315090 | 15.803601 / 15.803641 / 15.803614 | 15.803618667 | 969 / `1047377823` every run |

The candidate mean was **0.000286 FPS slower** (**0.00181%**); its median was
0.000295 FPS lower. The screen reports `visualParityOnly=true` and
`isaAuditStatus=SKIPPED`; the negative result ended the experiment before the
strict audit. Candidate source fingerprints: source
`98EA3FA2EE9495FC656A90D83F7A33962F76A3BE04E3B19DC4523313AA946D19`, tree
`A455158171BFA9988F26BDACB4827926CDA5E5F535F23CB8B124FC9C30347043`.
