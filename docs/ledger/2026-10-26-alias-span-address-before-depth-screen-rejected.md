# Alias span address-update-before-depth schedule rejected

Kept the T carry and mask update first, then executed the S-fraction and texture-address update before the independent 1/z update in all sixteen per-pixel sites of `D_PolysetDrawSpans8`. This moves the source pointer earlier for the next texel load while preserving each carry pair.

The parity-only 3-run screen measured 15.942828, 15.942823, and 15.942873 FPS (15.942841333 mean), 0.000012334 FPS below the 15.942853667 FPS control. Every run completed 969 frames with framebuffer checksum `1047377823`; the negative screen mean rejects the schedule before strict audit. The source reorder was reverted and not committed.

Screen result: `out/dos-timedemo-20261026-041858/timedemo-result.json`. Profile SHA-256: `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
