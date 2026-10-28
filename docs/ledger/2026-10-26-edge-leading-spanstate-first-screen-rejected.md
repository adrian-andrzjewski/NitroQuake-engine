# Reject spanstate-first leading-edge dispatch (2026-10-26)

The candidate checked `st_spanstate` before loading `st_insubmodel` in
`R_GenerateSpans` and removed the duplicate inverted-span checks from the
non-bmodel and bmodel leading-edge paths. The output remained unchanged, but
the three-run parity screen did not improve the measured mean.

## Parity screen

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261026-150012` | 15.948144 / 15.948137 / 15.948150 | 15.948143667 |
| Spanstate-first screen | `out/dos-timedemo-20261026-162810` | 15.948102 / 15.948154 / 15.948138 | 15.948131333 |

Every run completed 969 frames with framebuffer checksum `1047377823`. The
screen mean was **−0.000012334 FPS** against the strict control mean. The
screen skipped the ISA audit (`isaAuditStatus=SKIPPED`), and its negative mean
does not qualify the candidate for strict promotion. The source edit was
reverted; the original branch order is restored.

The candidate source-tree fingerprint was
`61E69FD073FAAE267B2B85657C2360345C3A6858AFDC9E0228864E2955D64CC3`.
