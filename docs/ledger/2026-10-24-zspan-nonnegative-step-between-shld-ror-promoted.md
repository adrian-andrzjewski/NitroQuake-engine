# D_DrawZSpans nonnegative step scheduling (2026-10-24)

Status: promoted for the i486 path after a positive strict three-run mean. The
i386 packing path retains its prior instruction order.

In `ZSPAN_ADD_PAIR_NONNEGATIVE`, the i486 sequence now advances the second
fixed-point sample between `SHLD` and `ROR`. `SHLD` has already copied the
needed next sample into the packed value in `%eax`; the following `ROR` only
reorders `%eax`, so the `%edx` step can execute in that slot and shorten the
accumulator dependency chain. The i386 path still uses `ZPACK16` followed by
the original step.

Both builds used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, `testdata/id1`, and the pinned 32 MB DOSBox-X profile with
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, prior i486 pair schedule | `out/dos-timedemo-20261024-065047/timedemo-result.json` | 61.232839 / 61.232896 / 61.232860 | 15.824842 / 15.824828 / 15.824836 | 15.824835333 | 969 / `1047377823` every run |
| Candidate, step between `SHLD` and `ROR` | `out/dos-timedemo-20261024-071331/timedemo-result.json` | 61.232812 / 61.232845 / 61.232851 | 15.824849 / 15.824840 / 15.824838 | 15.824842333 | 969 / `1047377823` every run |

The candidate mean is **0.000007000 FPS higher** (**+0.00004423%**); each
same-index candidate sample was faster than its control sample. The gain is
smaller than the run-to-run spread but is positive across the matched
three-run means. The full strict i486 gate passed: 314,158 linked instructions,
435 executable ranges, 529 startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. Control source fingerprint:
`F7400BE0FAD41079039D370759A76CF3F7C6A705348C9A3CDC263ED8332653ED`; tree
fingerprint: `3F3630CB9E3BC34031467791BC324B04DB62E2CAB8829945B0BAD424CD347430`.
Candidate source fingerprint:
`08DB7B35A3BFAD24027D3F784B747D9F1C6ED137D1BD370599E1531DC6A78BCE`; tree
fingerprint: `D0DABB836B3F8993DB869F4273E05509C5D28F18CBDA537B5F93FC5AFC84397E`.
