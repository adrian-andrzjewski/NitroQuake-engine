# D_DrawZSpans 48-pixel group (2026-10-24)

Status: rejected after the strict timedemo. The committed 32-pixel group is
restored.

The candidate changed the nonnegative Z-span main loop from 32 pixels per
branch to 48 pixels per branch (twenty-four packed pixel pairs), followed by a
32/16/8/4/2-pixel remainder path. Endpoint proof and per-pair arithmetic were
unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, and the pinned 32 MB profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 32-pixel group | `out/dos-timedemo-20261024-043416/timedemo-result.json` | 61.232867 / 61.232885 / 61.232879 | 15.824834 / 15.824830 / 15.824831 | 15.824831667 | 969 / `1047377823` every run |
| Strict, 48-pixel group | `out/dos-timedemo-20261024-053357/timedemo-result.json` | 61.270850 / 61.270938 / 61.270883 | 15.815024 / 15.815002 / 15.815016 | 15.815014000 | 969 / `1047377823` every run |

The candidate mean was **0.009817667 FPS slower** (**−0.06204%**). Every run
retained exact frame and framebuffer-checksum parity. The full strict i486
gate passed: 314,357 linked instructions across 435 executable ranges, 529
startup rows, and 9,207 provider instructions, with zero above-i486, unknown,
or exempt instructions. Candidate source fingerprint:
`E1CB1B9B3C462C7DC2CD3E394CD2C5F71B03974CC171520AEDA2A4CE95B0B626`; tree
fingerprint: `426A3D0FD4C26C76F335005A997900E1210CA9CFEA06A600A1BE73D1520FD553`.
