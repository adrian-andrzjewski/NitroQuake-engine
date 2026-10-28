# Mip-1 first source-texel read before light-delta save rejected

In the general `SURF8_MIP1_ROW` body, moved only the first source-texel read ahead of the `lightdelta` save, leaving the second read in its original position.

The three-run parity screen measured 15.921175, 15.921183, and 15.921195 FPS (15.921184333 mean), versus the strict control mean of 15.921187667 FPS. The delta was -0.000003334 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`; the parity-only screen skipped the ISA audit. The negative mean rejects the move, which was reverted without a strict run or commit.

Candidate result: `out/dos-timedemo-20261025-090918/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-052211/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
