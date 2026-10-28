# Mip-3 source-step load hoist rejected

Moved the `sourcetstep` load in `R_DrawSurfaceBlock8_mip3` to immediately after the second row's light-table index was formed, ahead of the first texel lookup.

The three-run parity screen measured 15.921187, 15.921178, and 15.921180 FPS (15.921181667 mean), versus the matched strict control mean of 15.921187667 FPS. The delta was -0.000006000 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`; the parity-only screen skipped the ISA audit. The negative mean rejects the schedule, which was reverted without a strict run or commit.

Screen result: `out/dos-timedemo-20261025-080907/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-052211/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
