# Span16 row-index load before x87 rejected

Moved the duplicate `espan_t_v` row-index load before both initial `fildl` instructions while preserving x87 arithmetic order. The parity-only screen looked positive, but the strict result was lower than control, so the source reorder was reverted.

The parity-only screen measured 15.942842, 15.942855, and 15.942886 FPS (15.942861 mean), with 969 frames and framebuffer checksum `1047377823` on each run.

The strict 3-run check passed parity and the complete i486 ISA gate. It measured 15.942821, 15.942839, and 15.942873 FPS (15.942844333 mean), which is 0.000009334 FPS below the accepted 15.942853667 FPS control. Each run rendered 969 frames with framebuffer checksum `1047377823`. The scheduling change was reverted and not committed.

Strict result: `out/dos-timedemo-20261026-033853/timedemo-result.json`. Profile SHA-256: `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
