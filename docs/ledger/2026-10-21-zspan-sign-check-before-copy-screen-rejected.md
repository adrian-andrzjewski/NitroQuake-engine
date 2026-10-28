# Z-span sign check before accumulator copy rejected (2026-10-21)

Status: rejected on the negative strict pooled mean; the original instruction
order remains active in `src/d_draw.s`.

The experiment moved `testl %edx,%edx` ahead of `movl %edx,%eax` in the
`ZSPAN_ADD_PAIR` and `ZSPAN_SUB_PAIR` macros. `MOV` preserves flags, so the
following sign branch used the same condition, and `%eax` still held the
accumulator for either the positive path or its negative-depth handler. The
instruction count was unchanged.

Both variants used the same uninstrumented DOSBox-X 2026.08.31 `demo1` timedemo,
CWSDPMI, and pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control, 3 runs | `out/dos-timedemo-20261021-132030` | 15.537290 / 15.537291 / 15.537295 | 15.537292000 | 0.000005 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-140359` | 15.537290 / 15.537289 / 15.537283 | 15.537287333 | 0.000007 |

The candidate mean was **−0.000004667 FPS (−0.00003004%)** against the strict
control. All six runs completed 969 frames with framebuffer checksum
`1047377823`. The candidate's strict complete i486 gate passed: 313,315 linked
instructions across 435 ranges, 529 startup code rows, and 9,207 DPMI provider
instructions, with zero above-i486, unknown, or exempt instructions. The
negative pooled mean rejects the schedule, and the original `MOV` then `TEST`
order was restored.

Candidate source-tree fingerprint:
`D2BABDBB19ED53F2B986B8B30A0ED1886811364CC86C6DEE9B3F1132146E4FE4`.
Candidate executable SHA-256:
`CB8A6107DA364738E5BF2DFD23C07A504134026D398C7DD0745862BC79675E1D`.
