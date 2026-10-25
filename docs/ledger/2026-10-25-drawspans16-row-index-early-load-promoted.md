# Span16 row-index load moved into initial setup promoted

Moved `movl espan_t_v(%ebx),%eax` from after the initial reciprocal division to immediately after the two initial `fildl` loads. This overlaps the integer row-index load with x87 span-coordinate setup while keeping the same row value for the later destination lookup.

The three-run parity screen measured 15.921197, 15.921200, and 15.921197 FPS (15.921198 mean), versus the strict control mean of 15.921187667 FPS. The parity-screen delta was +0.000010333 FPS. Every run rendered 969 frames and produced framebuffer checksum `1047377823`.

The strict three-run candidate measured 15.921190, 15.921192, and 15.921183 FPS (15.921188333 mean), a +0.000000667 FPS delta over the strict control. Exact frame-count/checksum parity and the complete i486 ISA gate passed: 276,096 object instructions and 314,393 linked instructions, with no above-i486, unknown, or exempt instructions; final mapping covered 435 contributions, and startup/provider proofs covered 529 CODE rows and 9,207 instructions with zero exemptions.

Parity result: `out/dos-timedemo-20261025-091634/timedemo-result.json`. Strict result: `out/dos-timedemo-20261025-093916/timedemo-result.json`. Control result: `out/dos-timedemo-20261025-052211/timedemo-result.json`. All used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
