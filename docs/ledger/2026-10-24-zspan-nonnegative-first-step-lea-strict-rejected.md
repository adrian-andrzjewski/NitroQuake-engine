# D_DrawZSpans first accumulator step with LEA (2026-10-24)

Status: rejected after the strict mean decreased; the committed `addl` was
restored.

The candidate changed only the first accumulator update in
`ZSPAN_ADD_PAIR_NONNEGATIVE` from `addl %ebx,%edx` to
`leal (%edx,%ebx),%edx`. Both variants used DOSBox-X 2026.08.31, the pinned
32 MB 486 profile `out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and identical aggressive i486 selectors.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Median FPS | Frames/checksum |
|---|---|---|---|---:|---:|---|
| Control, ADD, cutoff 22 | `out/dos-timedemo-20261024-022300/timedemo-result.json` | 61.263778 / 61.263771 / 61.263744 | 15.816850 / 15.816852 / 15.816859 | 15.816853667 | 15.816852 | 969 / `1047377823` every run |
| Screen, first LEA | `out/dos-timedemo-20261024-033906/timedemo-result.json` | 61.263812 / 61.263761 / 61.263778 | 15.816841 / 15.816855 / 15.816850 | 15.816848667 | 15.816850 | 969 / `1047377823` every run |
| Strict, first LEA | `out/dos-timedemo-20261024-040137/timedemo-result.json` | 61.263857 / 61.263818 / 61.263761 | 15.816830 / 15.816840 / 15.816855 | 15.816841667 | 15.816840 | 969 / `1047377823` every run |

The screen mean was 0.000000333 FPS above the cutoff-22 screen, but the strict
mean decreased by **0.000012000 FPS** (**0.000076%**) and the median decreased
by 0.000012 FPS. Exact frame and framebuffer-checksum parity held.

The complete strict i486 gate passed: 314,025 relocated executable
instructions, 529 startup rows, and 9,207 DPMI provider instructions, with
zero instructions above i486, unclassified instructions, or exemptions. All
403 native/annotated object proofs and 435 source-bound executable
contributions passed.

Strict candidate source fingerprint:
`89DFD4FF55CCD07A9A2E1E9289B54B8C74A7378AE7AD80F1D5578CDCF525E65E`; tree
fingerprint:
`EB355B4DE0070E9DA1CAB0AEF57752A793B2879E1A197991D62A24FD1C60006E`.
