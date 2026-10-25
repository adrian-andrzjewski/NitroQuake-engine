# Span16 S/T adjustment loads moved into initial setup promoted

Moved the `tadjust` and `sadjust` loads from the post-reciprocal span setup to immediately after the initial `espan_t_v` and `espan_t_u` loads. The values remain live through the intervening x87 setup and are consumed by the same `addl s,%esi` / `addl t,%edx` operations.

The three-run parity screen measured 15.921185, 15.921197, and 15.921197 FPS (15.921193 mean), versus the strict control mean of 15.921188333 FPS. The screen delta was +0.000004667 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`.

The strict three-run candidate measured 15.921193, 15.921179, and 15.921197 FPS (15.921189667 mean), a +0.000001333 FPS delta over the strict control. Exact frame-count/checksum parity and the complete i486 ISA gate passed: 276,096 object instructions and 314,393 linked instructions, with no above-i486, unknown, or exempt instructions; final mapping covered 435 contributions, and startup/provider proofs covered 529 CODE rows and 9,207 instructions with zero exemptions.

Parity result: `out/dos-timedemo-20261025-101238/timedemo-result.json`. Strict result: `out/dos-timedemo-20261025-103515/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-093916/timedemo-result.json`. All used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
