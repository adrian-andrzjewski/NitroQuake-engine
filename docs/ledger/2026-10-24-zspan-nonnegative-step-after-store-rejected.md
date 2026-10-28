# D_DrawZSpans second-step add after store (2026-10-24)

Status: rejected at the three-run parity screen; the committed instruction
order was restored and no strict run was started.

The candidate moved the second `addl %ebx,%edx` in
`ZSPAN_ADD_PAIR_NONNEGATIVE` after `movl %eax,(%edi)`. Both screen variants
used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and parity-only timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, add before store | `out/dos-timedemo-20261024-020035/timedemo-result.json` | 61.263773 / 61.263806 / 61.263777 | 15.816852 / 15.816843 / 15.816850 | 15.816848333 | 969 / `1047377823` every run |
| Candidate, add after store | `out/dos-timedemo-20261024-032921/timedemo-result.json` | 61.263801 / 61.263825 / 61.263801 | 15.816844 / 15.816838 / 15.816844 | 15.816842000 | 969 / `1047377823` every run |

The screen mean decreased by **0.000006333 FPS** (**0.000040%**). Exact frame
and framebuffer-checksum parity held, but the negative screen did not qualify
this candidate for a strict ISA audit. The committed order was restored.
