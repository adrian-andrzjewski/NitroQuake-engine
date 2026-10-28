# Span16 row-base lookup moved into initial setup rejected

Moved `movl C(viewspantable)(,%eax,4),%edi` from the post-reciprocal span setup to immediately after the early `espan_t_v`, `tadjust`, and `sadjust` loads. The next-span stack push and remaining span setup stayed in place.

The three-run parity screen measured 15.921158, 15.921176, and 15.921179 FPS (15.921171 mean), versus the strict control mean of 15.921189667 FPS. The delta was -0.000018667 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`. The negative mean rejects the move, which was reverted without a strict run or commit; the parity-only build skipped the ISA audit.

Candidate result: `out/dos-timedemo-20261025-104033/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-103515/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
