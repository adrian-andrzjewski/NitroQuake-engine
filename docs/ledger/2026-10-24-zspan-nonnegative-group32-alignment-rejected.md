# D_DrawZSpans 32-pixel loop alignment (2026-10-24)

Status: rejected after the strict timedemo. The committed 32-pixel group without
extra alignment remains restored.

The candidate added 16-byte alignment immediately before the 32-pixel
nonnegative Z-span main loop. The loop body and remainder path were unchanged.

The run used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, and the pinned 32 MB profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, unaligned 32-pixel group | `out/dos-timedemo-20261024-043416/timedemo-result.json` | 61.232867 / 61.232885 / 61.232879 | 15.824834 / 15.824830 / 15.824831 | 15.824831667 | 969 / `1047377823` every run |
| Strict, 16-byte aligned 32-pixel group | `out/dos-timedemo-20261024-062348/timedemo-result.json` | 61.245385 / 61.245340 / 61.245385 | 15.821600 / 15.821612 / 15.821600 | 15.821604 | 969 / `1047377823` every run |

The candidate mean was **0.003227667 FPS slower** (**−0.02039622%**). The
full strict i486 gate passed: 314,155 linked instructions across 435
executable ranges, 529 startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. Candidate source fingerprint:
`17DF92D0EB5D4ECD2C2DC3E86AB4FDC63C147D76CD317FE187E0AD8F7EAFD616`; tree
fingerprint: `C5362678D46DC123635A2C135B7050030F34F7099A840D5901C70B4A56E4C435`.
