# Span16 S-step add before source-byte fetch screen rejected (2026-10-21)

The default word-store schedule remains active in `src/renderer/d_draw16.s`. This
parity-only screen moved each `addl %ebp,%ebx` ahead of its paired
`movb (%esi),%al` in the A and B halves. The `movb` preserves the carry consumed
by the following `adcl`; no DDA arithmetic changed. The experiment's source
tree fingerprint was
`3CE688C9F98FCBE56503E02FF882C2E9B31AA7D0968884C8F85DD549BAC3768D`.

The comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control, 3 runs | `out/dos-timedemo-20261021-120454` | 15.537292 / 15.537300 / 15.537292 | 15.537294667 | 0.000008 |
| S-add before fetch, 3 runs | `out/dos-timedemo-20261021-124707` | 15.537293 / 15.537292 / 15.537283 | 15.537289333 | 0.000010 |

The candidate pooled mean was **−0.000005333 FPS (−0.00003433%)** against
control. All six samples completed 969 frames with framebuffer checksum
`1047377823`. The parity-only screen skipped the strict ISA audit; because its
mean was negative, the instruction order was restored without a strict run.
