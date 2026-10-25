# Render-face capacity check loads the edge count early (2026-10-25)

Status: promoted in `src/asm486_experiments.s` after a positive strict mean,
exact checksum parity, and the complete i486 ISA gate.

`R_RenderFace_asm486` now loads `fa->numedges` before the surface-capacity
branch. The common path needs the count for the following edge-capacity check;
moving the independent load earlier overlaps it with the first comparison.
The conditions and capacity arithmetic are unchanged.

## Matched timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261025-203909/timedemo-result.json` | 15.940503 / 15.940522 / 15.940552 | 15.940525667 |
| Early edge-count load | `out/dos-timedemo-20261025-212734/timedemo-result.json` | 15.940524 / 15.940551 / 15.940522 | 15.940532333 |

The strict candidate mean increased by **0.000006667 FPS (0.0000418%)**. The
three-run parity screen also passed, with samples 15.940511 / 15.940563 /
15.940519 FPS and mean 15.940531; its result is
`out/dos-timedemo-20261025-210339/timedemo-result.json`.

The complete i486 gate passed: 168 source objects and 235 runtime objects;
314,394 linked instructions across 435 executable ranges; 2,376 CODE and 35
DATA source-bound ranges; 529 startup CODE rows; and 9,207 provider
instructions. There were zero above-i486, unknown, or exempt instructions.
The strict result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
The candidate source-tree fingerprint is
`FF3AD957C5D290D886F6171913BB3C0AEA72B97930E954C824EB043A2052FF05`.
