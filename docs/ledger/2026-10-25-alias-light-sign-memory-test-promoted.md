# Alias light-sign test uses a direct memory operand (2026-10-25)

Status: promoted in `src/renderer/r_aliasa.s` after exact parity, a positive strict mean,
and the complete i486 ISA gate.

The alias transform loop previously loaded the sign byte of `lightcos` from
`Ltemp+3` into `%dl`, then tested its high bit. It now uses
`testb $0x80,Ltemp+3` directly. The same sign bit selects the same branch; the
x87 operations, lighting multiply, clamp, and framebuffer output remain
unchanged. This removes one register load per transformed alias vertex.

Both variants used DOSBox-X 2026.08.31, `demo1`, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-132611/timedemo-result.json` | 15.921352 / 15.921356 / 15.921363 | 15.921357000 | 15.921356 |
| Direct memory test | `out/dos-timedemo-20261025-143648/timedemo-result.json` | 15.923560 / 15.923549 / 15.923532 | 15.923547000 | 15.923549 |

The candidate mean increased by **0.002190 FPS (0.0137551%)**. Its parity-only
screen also passed: `out/dos-timedemo-20261025-141346/timedemo-result.json`.

The complete strict i486 gate passed: 314,388 linked opcodes, 529 startup
code rows, and 9,207 DPMI-provider instructions; zero above-i486, unknown, or
exempt instructions. Final mapping covered 435 source-bound contributions.
The result records `visualParityOnly: false` and `isaAuditStatus: PASS`.
