# D_DrawZSpans second accumulator step with LEA (2026-10-24)

Status: rejected at the three-run parity screen; the committed `addl` was
restored and no strict run was started.

The candidate changed only the second accumulator update in
`ZSPAN_ADD_PAIR_NONNEGATIVE` from `addl %ebx,%edx` to
`leal (%edx,%ebx),%edx`. Both screen variants used DOSBox-X 2026.08.31, the
pinned 32 MB 486 profile `out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and parity-only timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, ADD, cutoff 22 | `out/dos-timedemo-20261024-020035/timedemo-result.json` | 61.263773 / 61.263806 / 61.263777 | 15.816852 / 15.816843 / 15.816850 | 15.816848333 | 969 / `1047377823` every run |
| Candidate, second LEA | `out/dos-timedemo-20261024-040621/timedemo-result.json` | 61.263824 / 61.263795 / 61.263781 | 15.816838 / 15.816846 / 15.816850 | 15.816844667 | 969 / `1047377823` every run |

The screen mean decreased by **0.000003667 FPS** (**0.000023%**). Exact frame
and framebuffer-checksum parity held, but the negative screen did not qualify
the candidate for a strict ISA audit. The committed ADD was restored.
