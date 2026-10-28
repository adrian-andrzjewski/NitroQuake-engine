# D_DrawZSpans positive 32-pixel fixed-offset stores rejected

Replaced the positive nonnegative 32-pixel group's per-pair `%edi` increment with fixed store offsets from the group base and one 64-byte pointer advance after the group. The parity-only build compiled, but timedemo run 1 failed the framebuffer parity gate: checksum `3506415329` instead of `1047377823`.

This is not a valid timing result, and no strict ISA audit was run. The candidate was removed and the original per-pair `LEA`/store schedule restored.

Failed parity attempt: `out/dos-timedemo-20261025-115416/`. The build used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
