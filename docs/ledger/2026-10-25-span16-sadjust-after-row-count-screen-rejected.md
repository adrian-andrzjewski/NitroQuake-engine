# Span16 `sadjust` load after row and count setup rejected

Moved the `sadjust` load from before the row-base lookup to after the row-base, U-coordinate, and count setup. The three-run parity screen measured 15.921183, 15.921186, and 15.921183 FPS (15.921184 mean), versus the accepted strict control mean of 15.921190667 FPS. The delta was -0.000006667 FPS.

Every run rendered 969 frames and produced framebuffer checksum `1047377823`. The negative mean rejects this load order; the original `sadjust`-before-row-base order has been restored. No strict run was made because the parity screen failed to show an increase; the parity-only build skipped the ISA audit.

Candidate result: `out/dos-timedemo-20261025-114305/timedemo-result.json`. Strict control: `out/dos-timedemo-20261025-112826/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Candidate source fingerprint: `AA2E94A11D4D2E50ADA900CBA0C9EDCFD434FB54D393EB90117A295B0F157AFC`. Candidate source-tree fingerprint: `D7960133773346A731550228902A6FE1AA99896C00A2199FDC1E2C0E8E8228A6`.
