# Span16 direct count subtraction promoted (2026-10-27)

For spans longer than 16 pixels, seed `counttemp` at `LSetupNotLast1` and
subtract 16 directly from it for each full segment. This replaces the segment
count decrement in ECX and its store back to `counttemp`; ECX is overwritten by
`C(tadjust)` immediately afterward. Short spans do not enter this path.

The strict uninstrumented comparison used DOSBox-X 2026.08.31, `demo1`,
CWSDPMI, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Control and candidate both rendered 969 frames with framebuffer checksum
`1047377823` on every run.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261027-034245/timedemo-result.json` | 16.134742 / 16.134768 / 16.134757 | 16.134755667 | 16.134757 |
| Direct memory subtraction | `out/dos-timedemo-20261027-041306/timedemo-result.json` | 16.145639 / 16.145599 / 16.145616 | 16.145618000 | 16.145616 |

The candidate gained **0.010862333 FPS (+0.067323%)**. The complete strict
i486 audit verified 314,322 relocated instructions across 435 executable
ranges, 529 startup rows, and 9,207 DPMI-provider instructions, with zero
above-i486, unknown, or exempt instructions. The candidate build and audit
reports are in
`out/local-dos-timedemo-20261027-span16-counttemp-memory-sub/`. The source
fingerprint is
`0FEC5A86F2F05DA2D653C35C2EBF90E3BF09445E392909AB52D6748DD398D9C6`; the
executable SHA-256 is
`A526F2FA5B016C0786143E3583098EDF9325476EA12E7BC077922406F3B6137E`.
