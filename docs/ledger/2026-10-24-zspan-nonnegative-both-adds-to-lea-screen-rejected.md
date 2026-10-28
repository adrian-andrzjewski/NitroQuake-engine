# D_DrawZSpans two accumulator LEAs (2026-10-24)

Status: rejected at the three-run parity screen; both additions were restored
and no strict run was started.

The candidate changed both accumulator updates in
`ZSPAN_ADD_PAIR_NONNEGATIVE` from `addl %ebx,%edx` to
`leal (%edx,%ebx),%edx`. Both screen variants used DOSBox-X 2026.08.31, the
pinned 32 MB 486 profile `out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and parity-only timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, two ADDs | `out/dos-timedemo-20261024-020035/timedemo-result.json` | 61.263773 / 61.263806 / 61.263777 | 15.816852 / 15.816843 / 15.816850 | 15.816848333 | 969 / `1047377823` every run |
| Candidate, two LEAs | `out/dos-timedemo-20261024-033429/timedemo-result.json` | 61.263794 / 61.263800 / 61.263775 | 15.816846 / 15.816844 / 15.816851 | 15.816847000 | 969 / `1047377823` every run |

The screen mean decreased by **0.000001333 FPS** (**0.0000084%**). Exact
frame and framebuffer-checksum parity held, but the screen did not qualify the
candidate for the strict ISA audit. The committed ADD instructions were
restored.
