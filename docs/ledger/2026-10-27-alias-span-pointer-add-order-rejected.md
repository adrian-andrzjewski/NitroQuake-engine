# Alias span pointer-add scheduling rejected (2026-10-27)

Status: rejected after the strict three-run comparison; the original instruction order is restored.

In the hot `D_PolysetDrawSpans8` loop, the independent `addl $8,%edi`
and `addl $16,%ecx` updates were swapped at the paired eight-pixel boundary.
The intent was to place the destination-pointer update between the Z-buffer
pointer update and its next compare, filling the i486 address-generation delay.
The alternate pair at the loop transition was also reordered. No instructions
were added or removed.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned i486
profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All runs rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| Strict control | `out/dos-timedemo-20261026-214707/timedemo-result.json` | 16.107101 / 16.107111 / 16.107108 | 16.107106667 |
| Pointer-add reorder | `out/dos-timedemo-20261027-012547/timedemo-result.json` | 16.107090 / 16.107094 / 16.107088 | 16.107090667 |

The candidate delta was **-0.000016000 FPS (-0.0000993%)**. The
complete linked i486 ISA gate passed: 314,317 relocated instructions, 529
startup rows, and 9,207 provider instructions, with zero above-i486,
unknown, or exempt instructions. Exact output parity passed, but the negative
mean rejects this schedule, so no optimization commit was made.

The first runner invocation reached the strict audit but could not stage the
PAK files because their NTFS hard-link counts were exhausted. A byte-verified
local data copy was used for the completed measurement; the benchmark profile
and source selectors remained pinned.
