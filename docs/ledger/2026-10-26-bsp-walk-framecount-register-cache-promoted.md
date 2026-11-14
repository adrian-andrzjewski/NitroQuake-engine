# BSP walk frame-count register cache promoted (2026-10-26)

Status: promoted in `src/renderer/asm486_experiments.s` under the user's any-positive
pooled-mean rule.

The internal-node surface loop now loads the current frame count into `%ebx`
once before visiting the node's surfaces, then compares each surface against
that register. The continuation record restores the current node into `%ebx`
before the back-child traversal. This removes a repeated global frame-count
load from the profiled BSP surface tests while preserving the existing walk.

Both strict timedemos used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261025-231013` | 15.940509 / 15.940555 / 15.940556 | 15.940540000 | 0.000047 |
| Register-cached frame count | `out/dos-timedemo-20261026-002136` | 15.942842 / 15.942880 / 15.942853 | 15.942858333 | 0.000038 |

The strict candidate mean improved by **+0.002318333 FPS (+0.01454363%)**.
Every run completed 969 frames with framebuffer checksum `1047377823`. The
candidate passed the complete strict i486 ISA audit: 314,408 relocated
instructions, zero above-i486, unknown, or exempt instructions. Its source-tree
fingerprint is
`4083E4EB3B822EE8B1CB9963B728E839068CDC8C7B315C11F42D67B27A4D8595`.
