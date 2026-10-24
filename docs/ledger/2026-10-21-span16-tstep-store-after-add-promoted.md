# Span16 T-step store after fractional add promoted (2026-10-21)

Status: promoted under the positive pooled-mean rule.

In `src/d_draw16.s`, the `LSetUpCommon` path now stores `%ecx` to `tstep`
immediately after `addl %ecx,%edx` advances the T fraction and before
`sbbl %ecx,%ecx` extracts the carry. `MOV` preserves the flags, so the carry
extraction and following address update are unchanged. The change moves the
independent memory store later without changing the instruction count.

All samples used the uninstrumented DOSBox-X 2026.08.31 `demo1` timedemo,
CWSDPMI, and pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control, 3 runs | `out/dos-timedemo-20261021-132030` | 15.537290 / 15.537291 / 15.537295 | 15.537292000 | 0.000005 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-141204` | 15.537299 / 15.537295 / 15.537284 | 15.537292667 | 0.000015 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-143832` | 15.537293 / 15.537292 / 15.537300 | 15.537295000 | 0.000008 |

The strict candidate mean is **+0.000003000 FPS (+0.00001931%)** against the
strict control. The parity-only screen was also positive by **+0.000000667
FPS**. All nine samples completed 969 frames with framebuffer checksum
`1047377823`. The complete strict i486 gate passed: 313,315 linked
instructions across 435 executable ranges, 529 startup code rows, and 9,207
DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. The positive mean qualifies even though it is below the sample
spread.

Candidate source-tree fingerprint:
`8AF2A96E7076BC8B394E21D21A8A4386C0F4A8909D7B6DA9280AF61DEB0199C4`.
Strict candidate executable SHA-256:
`0AC355219736325E87C1475F534C7A0550768030E1BAE80E68342280D2C1FAEA`.
