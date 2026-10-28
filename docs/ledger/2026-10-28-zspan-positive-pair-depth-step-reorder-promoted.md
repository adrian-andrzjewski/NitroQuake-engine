# Positive-pair Z-span depth-step add reorder (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

In `ZSPAN_ADD_PAIR_NONNEGATIVE`, move `addl %ebx,%edx` after `rorl $16,%eax`.
This keeps the i486 path's arithmetic unchanged while scheduling the depth
accumulator add between the texture shift and store. The i386 branch is
unchanged.

## Timedemo

Control and candidate used `demo1`, DOSBox-X 2026.08.31, the aggressive
optimization profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823` and
matching event traces.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Control | `out/dos-timedemo-20261028-060920/timedemo-result.json` | 16.238081 / 16.238075 / 16.238066 | 16.238074000 | 16.238075 |
| Positive-pair Z-span add reorder | `out/dos-timedemo-20261028-070056/timedemo-result.json` | 16.238082 / 16.238076 / 16.238082 | 16.238080000 | 16.238082 |

The candidate gained **0.000006 FPS (+0.00003695%) by mean**. This is smaller
than the observed run spread, but the project promotion rule accepts any
positive mean from at least three matched uninstrumented runs and sets no
minimum-gain threshold.

## i486 audit

The complete strict audit passed with zero above-i486, unknown, or exempt
instructions: 314,233 relocated instructions across 403 exact source-bound
objects, 529 startup rows, and 9,207 DPMI provider instructions. The timedemo
result reports `isaAuditStatus: PASS`.
