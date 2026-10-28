# D_PolysetRecursiveTriangle Y-difference memory-source subtract (2026-10-28)

Status: promoted after a positive matched three-run mean, exact framebuffer
checksum parity, and the complete strict i486 ISA gate.

Each of the three Y-difference checks in `D_PolysetRecursiveTriangle` now loads
one vertex Y value into `%eax` and subtracts the other directly from memory.
The inclusive `+1`, compare against two, and branch condition are unchanged.
This removes one instruction per executed Y check and avoids holding the
intermediate difference in `%ebp` while loading the second operand into `%ecx`.

The matched comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, and the
pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Both
variants used the aggressive optimization profile and `TextureSpanStores=word`.
Every run rendered 969 frames and reported framebuffer checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261027-233600/timedemo-result.json` | 16.211792 / 16.211782 / 16.211787 | 16.211787000 | 16.211787 |
| Memory-source Y subtract | `out/dos-timedemo-20261028-012301/timedemo-result.json` | 16.219507 / 16.219472 / 16.219467 | 16.219482000 | 16.219472 |

The candidate gained **0.007695 FPS (+0.047465%)** over the accepted control.
The complete strict i486 gate passed: 314,246 relocated instructions, 529
startup rows, and 9,207 provider instructions, with zero above-i486, unknown,
or exempt instructions. Source mapping covered 403 exact object proofs, 435
source-bound contributions, 2,376 CODE ranges, and 35 DATA ranges.

The automated DOSBox run is hidden and did not capture the host window. Exact
framebuffer parity confirms the timedemo's guest output, but does not verify
visible DOSBox window presentation.
