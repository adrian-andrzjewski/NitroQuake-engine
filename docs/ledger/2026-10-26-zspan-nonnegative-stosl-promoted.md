# STOSL for nonnegative Z-span pair store (2026-10-26)

Status: promoted in src/renderer/d_draw.s after exact framebuffer parity, a positive
strict mean, and the complete i486 ISA gate.

The i486 nonnegative paired Z-span path previously advanced EDI with LEA before
ROR, then stored the packed pair with MOV. It now uses ROR followed by STOSL.
This path already aligns the destination before entering the pair loop, so STOSL
writes the same four bytes and advances EDI by four. General and negative-depth
paths are unchanged.

The matched runs used DOSBox-X 2026.08.31, demo1, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile SHA
532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA. Each run
rendered 969 frames with framebuffer checksum 1047377823.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | out/dos-timedemo-20261026-150012/timedemo-result.json | 15.948144 / 15.948137 / 15.948150 | 15.948143667 | 15.948144 |
| Parity screen | out/dos-timedemo-20261026-191401/timedemo-result.json | 16.085466 / 16.085456 / 16.085465 | 16.085462333 | 16.085465 |
| Strict candidate | out/dos-timedemo-20261026-193850/timedemo-result.json | 16.085452 / 16.085471 / 16.085456 | 16.085459667 | 16.085456 |

The strict mean increased by 0.137316 FPS (0.861%). All candidate runs retained
the exact 969-frame checksum. The complete strict i486 gate passed: 314,358
relocated instructions, 529 startup code rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. Source mapping covered
435 source-bound contributions, 2,376 CODE ranges, and 35 DATA ranges. The
result records visualParityOnly=false and isaAuditStatus=PASS.