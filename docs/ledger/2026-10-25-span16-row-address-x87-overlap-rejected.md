# Span16 row-address and next-span load overlap rejected

Moved the `espan_t_v` row lookup and `espan_t_pnext` push earlier in the span setup, between the initial `fildl` loads and the remaining x87 setup.

The parity-only 3-run check passed at 15.921195, 15.921197, and 15.921197 FPS (15.921196333 mean), with 969 frames and framebuffer checksum `1047377823` on every run. The strict 3-run check also passed parity and the complete i486 ISA gate, but measured 15.921164, 15.921181, and 15.921192 FPS (15.921179 mean). This is 0.000008667 FPS below the accepted 15.921187667 FPS control, so the scheduling change was reverted and not committed.

Strict result: `out/dos-timedemo-20261025-075559/timedemo-result.json`. Profile SHA-256: `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
