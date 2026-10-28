# D_DrawZSpans 40-pixel group (2026-10-24)

Status: rejected after the strict timedemo. The committed 32-pixel group is
restored.

The candidate changed the nonnegative Z-span main loop from 32 pixels per
branch to 40 pixels per branch (twenty packed pixel pairs), followed by a
32/16/8/4/2-pixel remainder path. Endpoint proof and per-pair arithmetic were
unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, and the pinned 32 MB profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 32-pixel group | `out/dos-timedemo-20261024-043416/timedemo-result.json` | 61.232867 / 61.232885 / 61.232879 | 15.824834 / 15.824830 / 15.824831 | 15.824831667 | 969 / `1047377823` every run |
| Strict, 40-pixel group | `out/dos-timedemo-20261024-055930/timedemo-result.json` | 61.740822 / 61.281202 / 61.281118 | 15.694640 / 15.812353 / 15.812375 | 15.773122667 | 969 / `1047377823` every run |

The candidate mean was **0.051709000 FPS slower** (**−0.32676%**). The slow
first sample is retained because no separate cause was established; the other
two samples were also below the control mean. The full strict i486 gate passed:
314,329 linked instructions across 435 executable ranges, 529 startup rows,
and 9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions. Candidate source fingerprint:
`4707E7DD079E6E66C3C016A432DE3F5603E183192D8EA8CD5AF20E5D9EDDE24C`; tree
fingerprint: `D10E6637D41EDC906FAAC0E3122AA10799ACA807A8C2BDE88A04B92387469E03`.
