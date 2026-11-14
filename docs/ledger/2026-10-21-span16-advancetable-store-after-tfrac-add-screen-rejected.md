# Span16 `advancetable` store after T-fraction add rejected (2026-10-21)

Status: rejected on the negative parity-screen mean; the store remains before
the T-fraction addition in `src/renderer/d_draw16.s`.

The experiment moved `movl %eax,advancetable` from immediately before
`addl %ecx,%edx` to immediately after it. The store value and the T-fraction
inputs are independent. `MOV` preserves flags, so `sbbl %ecx,%ecx` still
consumed the same carry. The separately promoted `tstep` store remains after
the T-fraction addition.

Both variants used the uninstrumented DOSBox-X 2026.08.31 `demo1` timedemo,
CWSDPMI, and pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control, 3 runs | `out/dos-timedemo-20261021-143832` | 15.537293 / 15.537292 / 15.537300 | 15.537295000 | 0.000008 |
| Parity-only candidate, 3 runs | `out/dos-timedemo-20261021-144554` | 15.537300 / 15.537291 / 15.537288 | 15.537293000 | 0.000012 |

The candidate mean was **−0.000002000 FPS (−0.00001287%)** against the strict
control. All six runs completed 969 frames with framebuffer checksum
`1047377823`. The parity-only build skipped the ISA audit. Its negative mean
rejects the schedule, and the original `advancetable` store position was
restored while the promoted `tstep` order remains active.

Candidate source-tree fingerprint:
`F7AC7BF6AFD118644C7A6FBFCFDAAFC86125CAF2966C0B8A44F6D313063DF715`.
Candidate executable SHA-256:
`D06F17268222ECF640B155427D65E6844C84D99DC5BF8CA8FFDCE9110FA59BB9`.
