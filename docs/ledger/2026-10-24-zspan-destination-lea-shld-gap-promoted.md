# i486 Z-span destination LEA in the SHLD/ROR gap (2026-10-24)

Status: promoted after a positive strict three-run mean, exact checksum parity,
and the complete i486 ISA gate.

In `ZSPAN_ADD_PAIR_NONNEGATIVE`, the i486 path now advances `%edi` between
`SHLD` and `ROR`, then stores the packed pair to `-4(%edi)`. The store still
targets the original pixel address. The `TARGET_I386` branch keeps its original
store and pointer-advance order.

The matched timedemos used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with normalized SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run
completed 969 frames. All candidate checksums were `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Median FPS | Spread |
|---|---|---|---:|---:|---:|
| Strict control | `out/dos-timedemo-20261024-174207/timedemo-result.json` | 15.900779 / 15.900826 / 15.900828 | 15.900811000 | 15.900826 | 0.000049 |
| Strict candidate | `out/dos-timedemo-20261024-181940/timedemo-result.json` | 15.900805 / 15.900806 / 15.900857 | 15.900822667 | 15.900806 | 0.000052 |

The candidate mean increased by **0.000011667 FPS (+0.00007337%)**. The
candidate median is 0.000020 FPS lower than the control median, and the sample
ranges overlap. Treat this as a very small, provisional mean gain rather than a
stable improvement until a repeated paired measurement confirms it.

The complete i486 gate passed: 403 exact object proofs, 314,317 linked
instructions, 529 startup rows, and 9,207 provider instructions were checked;
there were zero above-i486, unknown, or exempt instructions. Runtime source
proof and checksum parity passed. The candidate source fingerprint was
`F87DA0C4CCDB0AEB0EF2C851F12BD439C09D28270D70032C5FEE7DD1CA5C2A6A`.
