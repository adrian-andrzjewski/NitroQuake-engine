# D_DrawZSpans negative-depth destination LEA in SHLD/ROR gap rejected (2026-10-24)

Status: rejected after a negative strict three-run mean. The candidate passed
exact checksum parity and the complete i486 ISA gate, but the original
pointer/store order has been restored.

The candidate moved the i486 destination pointer increment in
`ZSPAN_SUB_NEGATIVE_PAIR` between `SHLD` and `ROR`, then stored the packed pair
at `-4(%edi)`. The `TARGET_I386` path was unchanged during the experiment.

The matched timedemos used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with normalized SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run
completed 969 frames and retained checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Median FPS | Spread |
|---|---|---|---:|---:|---:|
| Strict control | `out/dos-timedemo-20261024-181940/timedemo-result.json` | 15.900805 / 15.900806 / 15.900857 | 15.900822667 | 15.900806 | 0.000052 |
| Strict candidate | `out/dos-timedemo-20261024-185056/timedemo-result.json` | 15.900804 / 15.900800 / 15.900814 | 15.900806000 | 15.900804 | 0.000014 |

The candidate mean decreased by **0.000016667 FPS (−0.00010482%)**. The full
i486 audit passed: 403 object proofs and 314,318 linked instructions, plus 529
startup rows and 9,207 provider instructions, with zero above-i486, unknown, or
exempt instructions. The candidate source fingerprint was
`2743380D3FC93727194E0BF43A8E2A76F76FECDB4830D514FA0355883B522586`.
