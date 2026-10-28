# D_DrawZSpans nonnegative pointer increment with ADD (2026-10-24)

Status: rejected after the strict mean was below the committed LEA control;
the working source was restored to `leal 4(%edi),%edi`.

The candidate replaced pointer advancement in `ZSPAN_ADD_PAIR_NONNEGATIVE`
from `leal 4(%edi),%edi` to `addl $4,%edi`. Both variants used DOSBox-X
2026.08.31, the pinned 32 MB 486 profile `out/dosbox-x-486-high-32mb-profile.conf`
(SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and identical aggressive i486 selectors.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, LEA, cutoff 22 | `out/dos-timedemo-20261024-022300/timedemo-result.json` | 61.263778 / 61.263771 / 61.263744 | 15.816850 / 15.816852 / 15.816859 | 15.816853667 | 15.816852 | 969 / `1047377823` every run |
| Screen, ADD, cutoff 22 | `out/dos-timedemo-20261024-030052/timedemo-result.json` | 61.263742 / 61.263759 / 61.263776 | 15.816860 / 15.816855 / 15.816851 | 15.816855333 | 15.816855 | 969 / `1047377823` every run |
| Strict, ADD, cutoff 22 | `out/dos-timedemo-20261024-032320/timedemo-result.json` | 61.263749 / 61.263791 / 61.263796 | 15.816858 / 15.816847 / 15.816845 | 15.816850000 | 15.816847 | 969 / `1047377823` every run |

Although the screen was marginally positive, the strict mean decreased by
**0.000003667 FPS** (**0.000023%**) and the median decreased by 0.000005 FPS.
Exact frame and framebuffer-checksum parity held throughout.

The complete strict i486 gate passed: 314,024 relocated executable
instructions, 529 startup rows, and 9,207 DPMI provider instructions, with
zero instructions above i486, unclassified instructions, or exemptions. All
403 native/annotated object proofs and 435 source-bound executable
contributions passed.

Strict candidate source fingerprint:
`DF652C6617126FED2E3E2E0440F65E578C68A5727213C178D5ED4E37E2ECA3E1`; tree
fingerprint:
`68B3A5D37E039D57A716F7C037C3FB43B67AE1CB1922CFEA8548AFE5FD8138C6`.
