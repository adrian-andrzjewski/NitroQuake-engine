# General Z-span positive pair store with STOSL (2026-10-26)

Status: promoted in src/renderer/d_draw.s after exact framebuffer parity, a positive
strict mean, and the complete i486 ISA gate.

The general positive-sample Z-span pair macro, ZSPAN_ADD_PAIR, handles the
sign-checking fallback when a span does not use the proven nonnegative
long-span loop. Its i486 store now uses STOSL in place of MOV plus LEA, while
the i386 fallback retains the original sequence. STOSL writes the packed pair
to the aligned destination and advances EDI by four without changing flags.

The matched runs used DOSBox-X 2026.08.31, demo1, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile SHA
532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA. Each run
rendered 969 frames with framebuffer checksum 1047377823.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | out/dos-timedemo-20261026-193850/timedemo-result.json | 16.085452 / 16.085471 / 16.085456 | 16.085459667 | 16.085456 |
| Parity screen | out/dos-timedemo-20261026-202241/timedemo-result.json | 16.107075 / 16.107100 / 16.107100 | 16.107091667 | 16.107100 |
| Strict candidate | out/dos-timedemo-20261026-204612/timedemo-result.json | 16.107093 / 16.107088 / 16.107100 | 16.107093667 | 16.107093 |

The strict mean increased by 0.021634 FPS (0.1345%). All candidate runs retained
the exact 969-frame checksum. The complete strict i486 gate passed: 314,339
relocated instructions, 529 startup code rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. Source mapping covered
435 source-bound contributions, 2,376 CODE ranges, and 35 DATA ranges. The
result records visualParityOnly=false and isaAuditStatus=PASS.
