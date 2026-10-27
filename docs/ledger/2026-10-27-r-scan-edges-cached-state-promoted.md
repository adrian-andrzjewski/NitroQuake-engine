# R_ScanEdges cached state and span clear batching promoted (2026-10-27)

Status: promoted after a positive matched three-run timedemo mean, exact frame and checksum parity, and the complete strict i486 audit.

The R_ScanEdges_asm486 row loop caches pdrawfunc in ESI, retains the surfaces base in EDI, saves vrectbottom minus one in a local, and restores the original span pointer after a flush. It replaces the one-entry-at-a-time span-state clearing loop with guarded blocks of 14, 8, 4, 2, and 1 entries.

The matched workload was DOSBox-X 2026.08.31, demo1, the pinned i486 profile SHA-256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA, and the aggressive selector profile. Every run rendered 969 frames with framebuffer checksum 1047377823.

| Variant | FPS samples | Mean FPS |
|---|---|---:|
| Control parity screen | 16.054140 / 16.054132 / 16.054159 | 16.054143667 |
| Strict audited candidate | 16.057983 / 16.057996 / 16.058019 | 16.057999333 |

The candidate gained 0.003855666 FPS (+0.0240%). The control result is a parity-only screen; the candidate result completed the full strict i486 audit with isaAuditStatus=PASS. The audit verified 314,234 linked instructions across 435 executable ranges, 403 exact object proofs, 529 startup code rows, and 9,207 DPMI-provider instructions, with zero above-i486, unknown, or exempt instructions.

Evidence is retained under out/edge-scan-validation-20261027/. The candidate source fingerprint is 3BFA06237D63132A625E7F140BC92AB042487A0B893457CADB3F289F61EAA879 and source-tree fingerprint is 030CDAF6141B53FB07AAA17E347030829F92C6D6E8CCF3D52D0B4C0D0E250330.
