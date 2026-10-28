# D_DrawZSpans nonnegative subtract-path destination LEA rejected (2026-10-24)

Status: rejected after a negative strict three-run mean. The candidate passed
exact checksum parity and the complete i486 ISA gate, but the original
pointer/store order has been restored.

The candidate moved the i486 destination pointer increment in
`ZSPAN_SUB_PAIR_NONNEGATIVE` between `SHLD` and `ROR`, then stored the packed
pair at `-4(%edi)`. The `TARGET_I386` path was unchanged during the experiment.

The matched timedemos used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with normalized SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run
completed 969 frames and retained checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Median FPS | Spread |
|---|---|---|---:|---:|---:|
| Strict control | `out/dos-timedemo-20261024-181940/timedemo-result.json` | 15.900805 / 15.900806 / 15.900857 | 15.900822667 | 15.900806 | 0.000052 |
| Strict candidate | `out/dos-timedemo-20261024-191429/timedemo-result.json` | 15.900822 / 15.900786 / 15.900847 | 15.900818333 | 15.900822 | 0.000061 |

The candidate mean decreased by **0.000004333 FPS (−0.00002725%)**. The full
i486 audit passed: 403 object proofs and 314,318 linked instructions, plus 529
startup rows and 9,207 provider instructions, with zero above-i486, unknown, or
exempt instructions. The candidate source fingerprint was
`FACDF5FBAA5B2A9C91453789B2C326D73871C22021460384AD9FCD2A3F30056C`.
