# Span16 row-base lookup before `sadjust` rejected

Moved `movl C(viewspantable)(,%eax,4),%edi` ahead of the `sadjust` load in the post-reciprocal span setup. The three-run parity screen measured 15.921170, 15.921192, and 15.921183 FPS (15.921181667 mean), versus the accepted strict control mean of 15.921190667 FPS. The delta was -0.000009000 FPS.

Every run rendered 969 frames and produced framebuffer checksum `1047377823`. The negative mean rejects the load order; the original `sadjust`-before-row-base order has been restored. No strict run was made because the parity screen failed to show an increase; the parity-only build skipped the ISA audit.

Candidate result: `out/dos-timedemo-20261025-113751/timedemo-result.json`. Strict control: `out/dos-timedemo-20261025-112826/timedemo-result.json`. Both used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Candidate source fingerprint: `E9A9CB3126DAECB20DFF26B8C03FDA5F808C8E87A1CD3DE0099CE22E31D60953`. Candidate source-tree fingerprint: `9C43747B4B8976A8DDB0D85D9D0ECBA44EC20E325DB145806769AA98308C6504`.
