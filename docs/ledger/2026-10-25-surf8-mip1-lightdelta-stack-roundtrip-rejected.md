# Mip-1 light-delta stack round trip rejected

In the general `SURF8_MIP1_ROW` body, replaced the global `lightdelta` save/reload with a balanced `pushl %ebp` / `popl %ebp` pair around the shifted per-pixel row step. The fixed-point update order remained unchanged.

The three-run parity screen measured 15.921179, 15.921191, and 15.921181 FPS (15.921183667 mean), versus the strict control mean of 15.921187667 FPS. The delta was -0.000004000 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`; the parity-only screen skipped the ISA audit. The negative mean rejects the stack save, which was reverted without a strict run or commit.

Candidate result: `out/dos-timedemo-20261025-085951/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-052211/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
