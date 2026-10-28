# D_DrawSpans16 S-step shift before T branch (2026-10-28)

Status: promoted after a positive three-run mean, exact framebuffer parity, and
the complete strict i486 ISA gate.

## Change

Move the independent arithmetic shift of the S step before the T-step shift
and branch. The T-step shift still sets the flags consumed by `jnz`; both
setup arms retain identical arithmetic and carry-sensitive work. This removes
the duplicated S-step shift from the two branch arms.

## Timedemo

Control and candidate used `demo1`, DOSBox-X 2026.08.31, the aggressive
optimization profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Control | `out/dos-timedemo-20261028-052618/timedemo-result.json` | 16.238095 / 16.238076 / 16.238022 | 16.238064333 | 16.238076 |
| S shift before T branch | `out/dos-timedemo-20261028-060920/timedemo-result.json` | 16.238081 / 16.238075 / 16.238066 | 16.238074000 | 16.238075 |

The candidate gained **0.000009667 FPS (+0.0000595%) by mean**. Its median is
0.000001 FPS below control, and the mean gain is below the observed run spread.
The project promotion rule uses the positive pooled mean from at least three
matched uninstrumented runs and has no minimum-gain threshold, so this result
qualifies. All runs retained identical event traces.

## i486 audit

The complete strict audit passed with zero above-i486, unknown, or exempt
instructions: 314,233 relocated instructions across 403 exact source-bound
objects, 529 startup rows, and 9,207 DPMI provider instructions. The timedemo
result reports `isaAuditStatus: PASS`.
