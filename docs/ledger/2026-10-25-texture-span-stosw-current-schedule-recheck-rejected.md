# Texture-span `stosw` recheck on the current schedule rejected

Re-screened the opt-in `TextureSpanStores=stosw` path after the promoted Span16 word-store schedule changed. The three-run parity-only candidate measured 15.905088, 15.905090, and 15.905087 FPS (15.905088333 mean), versus the current strict word-store control mean of 15.921187667 FPS. The delta was -0.016099334 FPS. All runs rendered 969 frames with checksum `1047377823`; the parity screen skipped the ISA audit. This recheck confirms the older `stosw` rejection, so indexed word stores remain active and no strict run or commit was made.

Candidate result: `out/dos-timedemo-20261025-081527/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-052211/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
