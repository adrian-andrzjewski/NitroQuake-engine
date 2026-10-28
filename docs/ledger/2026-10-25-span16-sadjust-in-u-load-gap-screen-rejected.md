# Span16 `sadjust` load in U-coordinate load gap rejected

Moved the `sadjust` load between loading `espan_t_u(%ebx)` and adding U to the row base, to test whether it could cover the load-to-use gap. The three-run parity screen measured 15.921176, 15.921183, and 15.921196 FPS (15.921185 mean), versus the accepted strict control mean of 15.921190667 FPS. The delta was -0.000005667 FPS.

Every run rendered 969 frames and produced framebuffer checksum `1047377823`. The negative mean rejects the schedule; the original `sadjust`-before-row-base order has been restored. No strict run was made because the parity screen failed to show an increase; the parity-only build skipped the ISA audit.

Candidate result: `out/dos-timedemo-20261025-114822/timedemo-result.json`. Strict control: `out/dos-timedemo-20261025-112826/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Candidate source fingerprint: `357C57C0600E99A82DD9B14206FDFCF16E1437E4F855AF786B829B55219BAE00`. Candidate source-tree fingerprint: `754B9A00DF802DB17C7DA9893D4AB36D73AC179470EB73416983BE15959AC472`.
