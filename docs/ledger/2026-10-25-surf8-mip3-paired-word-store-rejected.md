# Mip-3 paired word store rejected

In `R_DrawSurfaceBlock8_mip3`, preserved the first shaded texel in `AH` and replaced the two adjacent byte stores with one little-endian 16-bit store.

The three-run parity screen measured 15.921188, 15.921183, and 15.921187 FPS (15.921186 mean), versus the matched strict control mean of 15.921187667 FPS. The delta was -0.000001667 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`; the screen skipped the ISA audit. Because the mean was negative, the change was reverted without a strict run or commit.

Screen result: `out/dos-timedemo-20261025-080358/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-052211/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
