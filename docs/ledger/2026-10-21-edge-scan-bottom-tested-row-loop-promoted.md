# Edge-scan bottom-tested row loop promoted (2026-10-21)

Status: promoted in `src/renderer/asm486_experiments.s` under the any-positive pooled
mean rule.

The scanline loop keeps its initial guard for empty main-row ranges, then tests
the row bound after incrementing `%ebx`. This removes the unconditional jump
back to the top on every main row while preserving the final-row path and the
scanline order.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Fresh control, parity screen | `out/dos-timedemo-20261021-171927` | 15.537293 / 15.537291 / 15.537287 | 15.537290333 | 0.000006 |
| Bottom-tested loop, parity screen | `out/dos-timedemo-20261021-180313` | 15.538381 / 15.538376 / 15.538391 | 15.538382667 | 0.000015 |
| Strict control | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |
| Strict candidate | `out/dos-timedemo-20261021-182741` | 15.538392 / 15.538370 / 15.538390 | 15.538384000 | 0.000022 |

The strict pooled mean is **+0.001087 FPS (+0.00699607%)** over control. Every
run completed 969 frames with framebuffer checksum `1047377823`.

The full strict i486 gate passed: 313,316 linked instructions across 435
executable ranges, 529 startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. The strict candidate
executable SHA-256 is
`CAAFA279A62C1A1BC2B6743996C2C71277BC75F025C412086A113804DC9CC187` and its
source-tree fingerprint is
`D2C420CE6FB2015B68537D66B375ECBE9A8EAAC5C60F4A280C5086AB8300E9FC`.
