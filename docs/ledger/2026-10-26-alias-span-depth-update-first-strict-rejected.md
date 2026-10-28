# Alias span depth-update-first schedule rejected

Moved the independent 1/z fixed-point update (`addl lzistepx,%ebp; adcl $0,%ebp`) ahead of the T-fraction carry update in all sixteen per-pixel sites of `D_PolysetDrawSpans8`. Each carry-producing pair remained adjacent, and the framebuffer matched exactly.

The parity-only screen measured 15.942836, 15.942878, and 15.942873 FPS (15.942862333 mean) against the 15.942853667 FPS control. The strict 3-run mean was 15.942853 FPS from 15.942843, 15.942841, and 15.942875 FPS, which is 0.000000667 FPS below control. All runs completed 969 frames with framebuffer checksum `1047377823`; the strict i486 executable audit passed with zero exemptions. The schedule was reverted and not committed.

Parity screen: `out/dos-timedemo-20261026-035015/timedemo-result.json`. Strict result: `out/dos-timedemo-20261026-041313/timedemo-result.json`. Profile SHA-256: `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
