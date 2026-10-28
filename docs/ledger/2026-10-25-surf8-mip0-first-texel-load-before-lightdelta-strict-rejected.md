# Mip-0 first texel load before light-delta save rejected

Moved only the first source-byte read in the general `SURF8_MIP0_ROW` body ahead of the `lightdelta` save, keeping the second read in its original interleaved position.

The three-run parity-only screen averaged 15.921188 FPS (15.921195 / 15.921186 / 15.921183), +0.000000333 FPS against the strict control mean of 15.921187667 FPS. The full strict three-run mean was 15.921181333 FPS (15.921163 / 15.921192 / 15.921189), -0.000006334 FPS against control. All runs rendered 969 frames and produced checksum `1047377823`. The full strict i486 gate passed, but the negative strict mean rejects the change, which was reverted without a commit.

Parity screen: `out/dos-timedemo-20261025-082646/timedemo-result.json`. Strict candidate: `out/dos-timedemo-20261025-084922/timedemo-result.json`. Control: `out/dos-timedemo-20261025-052211/timedemo-result.json`. All runs used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
