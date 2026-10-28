# Span16 U-coordinate load moved into initial setup rejected

Moved `movl espan_t_u(%ebx),%ecx` from the post-reciprocal span setup to immediately after the early row-index and adjustment loads. The row-base lookup and next-span stack push stayed in place.

The three-run parity screen measured 15.921177, 15.921189, and 15.921180 FPS (15.921182 mean), versus the strict control mean of 15.921189667 FPS. The delta was -0.000007667 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`. The negative mean rejects the move, which was reverted without a strict run or commit; the parity-only build skipped the ISA audit.

Candidate result: `out/dos-timedemo-20261025-104532/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-103515/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
