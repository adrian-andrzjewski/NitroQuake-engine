# Span16 S-step shift after T-step shift promoted (2026-10-21)

Status: promoted under the positive pooled-mean rule.

In `src/d_draw16.s`, `LSetUpCommon` now shifts the S-step fraction after the
T-step fraction shift and before storing `advancetable`. The following
T-fraction `addl` still sets the carry for `sbbl`; the later S-fraction `addl`
still sets the carry for the address `adcl`. The fixed-point arithmetic and
memory operands are unchanged.

All runs used the uninstrumented DOSBox-X 2026.08.31 `demo1` timedemo, CWSDPMI,
and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-143832` | 15.537293 / 15.537292 / 15.537300 | 15.537295000 | 0.000008 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-153141` | 15.537307 / 15.537296 / 15.537293 | 15.537298667 | 0.000014 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |

The strict candidate mean is **+0.000002000 FPS (+0.00001287%)** against
control. The parity-only screen was also positive by **+0.000003667 FPS
(+0.00002360%)**. All nine runs retained exactly 969 frames and framebuffer
checksum `1047377823`. The strict mean qualifies even though it is below the
sample spread.

The complete strict i486 gate passed: 313,315 linked instructions across 435
code ranges, 529 startup code rows, and 9,207 DPMI provider instructions, with
zero above-i486, unknown, or exempt instructions.

Promoted source-tree fingerprint:
`8F7AD115D3A9B6C8EE807B3352DD94CC6AAEC6B63CA334868C5CCC745E082F8F`.
Strict candidate executable SHA-256:
`9E988CC7EB97E873C0B84646538E56B9E1FE70E1F3FBFBE4D2BCF6EC7289CB4A`.
