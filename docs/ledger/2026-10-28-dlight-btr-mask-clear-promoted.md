# Dynamic-light bit mask cleared with BTR (2026-10-28)

Status: promote the one-instruction mask clear. With the remaining surface
light bits held in `EDI`, `BSF` puts the selected light index in `EBX`; the loop
now uses `btrl %ebx,%edi` instead of `leal -1(%edi),%edx` followed by
`andl %edx,%edi`. This clears the same selected bit and saves one instruction
in the sparse-light loop. The prior EDI mask-register change remains part of
the control and the promoted result.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. All renderer selector values matched exactly and every
run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Per-run FPS | Mean FPS | Median FPS | Spread |
|---|---|---:|---:|---:|
| EDI/LEA/AND control | 16.240105 / 16.240109 / 16.240100 | 16.240104667 | 16.240105 | 0.000009 |
| EDI/BTR candidate | 16.240130 / 16.240106 / 16.240111 | 16.240115667 | 16.240111 | 0.000024 |

The candidate mean increased **0.000011 FPS (+0.00006773%)** and its median
increased 0.000006 FPS. A fourth control run measured 16.240118 FPS, a
+0.000013 FPS drift from the control median. The BTR spread and trailing-control
drift exceed the mean gain; the current policy accepts any positive mean after
three uninstrumented matched samples, so the code is promoted with the timing
limitation recorded.

The strict candidate build passed the complete i486 gate: 313,519 relocated
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions;
zero above-i486, unknown, or exempt instructions. The strict timedemo result
records `isaAuditStatus=PASS`. The exact selector manifest and DOSBox profile
SHA matched the control; only the assembler code changed.

Control runs:

- `out/dos-timedemo-20261028-111923/timedemo-result.json`
- `out/dos-timedemo-20261028-112202/timedemo-result.json`
- `out/dos-timedemo-20261028-112444/timedemo-result.json`
- trailing control: `out/dos-timedemo-20261028-112605/timedemo-result.json`

Candidate runs and full build evidence:

- `out/dos-timedemo-20261028-111801/timedemo-result.json`
- `out/dos-timedemo-20261028-112042/timedemo-result.json`
- `out/dos-timedemo-20261028-112324/timedemo-result.json`
- strict audit: `out/profile-6a3bfbe8462770cc/isa-qbench/`
