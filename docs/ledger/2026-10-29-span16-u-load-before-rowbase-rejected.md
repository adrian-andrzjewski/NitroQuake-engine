# Span16 U load before row-table lookup rejected (2026-10-29)

Status: rejected after a three-run 320x200 parity screen; the promoted FILD-
window schedule remains active.

## Candidate and parity screen

The candidate moved `movl espan_t_u(%ebx),%ecx` before the independent
`viewspantable` row-base load. The row-base addition and all fixed-point and
x87 operations stayed in their original order.

The screen used DOSBox-X 2026.08.31, the pinned i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the aggressive assembly profile, and 320x200 output. Candidate
samples were 16.321729, 16.321701, and 16.321715 FPS, mean **16.321715 FPS**.
All runs completed 969 frames with framebuffer checksum `1047377823`.

## Disposition

The retained strict control averaged 16.321723 FPS. The candidate was
**0.000008 FPS slower (-0.000049%)**, so the load move was rejected and the
original order restored. The parity screen records `isaAuditStatus=SKIPPED`;
no strict ISA audit was run after the negative mean.

- Candidate: `out/dos-timedemo-20261029-133214/timedemo-result.json`
- Strict control: `out/dos-timedemo-20261029-115044/timedemo-result.json`
