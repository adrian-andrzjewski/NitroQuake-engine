# Span16 split adjustment-load schedule promoted

Kept the `tadjust` load in the initial setup and moved the `sadjust` load to immediately after saving `espan_t_pnext(%ebx)`. The row-base lookup and remaining span setup stayed in place.

The three-run parity screen measured 15.921195, 15.921185, and 15.921196 FPS (15.921192 mean), versus the accepted strict control mean of 15.921189667 FPS. The screen delta was +0.000002333 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`.

The strict three-run candidate measured 15.921188, 15.921191, and 15.921193 FPS (15.921190667 mean; median 15.921191), a +0.000001000 FPS delta over the strict control mean of 15.921189667 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`.

The complete i486 ISA gate passed: 276,096 object instructions and 314,393 linked instructions, with no above-i486, unknown, or exempt instructions. Final mapping covered 435 source-bound contributions; startup/provider proofs covered 529 CODE rows and 9,207 provider instructions with zero exemptions. The strict timedemo result records `visualParityOnly: false` and `isaAuditStatus: PASS`.

Parity screen: `out/dos-timedemo-20261025-105031/timedemo-result.json`. Strict result: `out/dos-timedemo-20261025-112826/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-103515/timedemo-result.json`. All used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
