# Negative-depth add-pair Z-span store with STOSL (2026-10-26)

Status: promoted in src/d_draw.s after exact framebuffer parity, a positive
strict mean, and the complete i486 ISA gate.

The negative-depth branch of the general add-pair Z-span loop packs the second
depth word as 0xffff, then stores the dword and advances EDI. Its i486 path now
uses STOSL instead of MOV plus LEA. The pair destination is dword-aligned, the
string store preserves flags, and the i386 fallback retains the original
sequence.

The matched runs used DOSBox-X 2026.08.31, demo1, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile SHA
532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA. Each run
rendered 969 frames with framebuffer checksum 1047377823.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | out/dos-timedemo-20261026-204612/timedemo-result.json | 16.107093 / 16.107088 / 16.107100 | 16.107093667 | 16.107093 |
| Parity screen | out/dos-timedemo-20261026-205249/timedemo-result.json | 16.107088 / 16.107092 / 16.107105 | 16.107095000 | 16.107092 |
| Strict candidate | out/dos-timedemo-20261026-211705/timedemo-result.json | 16.107096 / 16.107107 / 16.107102 | 16.107101667 | 16.107102 |

The strict mean increased by 0.000008 FPS (0.0000497%). All candidate runs
retained the exact 969-frame checksum. The complete strict i486 gate passed:
314,320 relocated instructions, 529 startup code rows, and 9,207 provider
instructions, with zero above-i486, unknown, or exempt instructions. Source
mapping covered 435 source-bound contributions, 2,376 CODE ranges, and 35 DATA
ranges. The result records visualParityOnly=false and isaAuditStatus=PASS.
