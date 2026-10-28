# Span16 S-step shift after T-carry screen rejected (2026-10-21)

Status: reverted after the strict three-run mean was negative. The existing
S-step shift at the start of `LSetUpCommon` remains active in `src/d_draw16.s`.

The experiment deferred `shll $12,%ebp` until immediately after
`sbbl %ecx,%ecx`, before the S-fraction add. The T-carry extraction therefore
kept its original flags; the following S-fraction `addl` set the flags consumed
by the address `adcl`. Arithmetic and memory operands were unchanged.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-143832` | 15.537293 / 15.537292 / 15.537300 | 15.537295000 | 0.000008 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-145346` | 15.537313 / 15.537291 / 15.537300 | 15.537301333 | 0.000022 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-151903` | 15.537290 / 15.537288 / 15.537290 | 15.537289333 | 0.000002 |

The parity-only screen was **+0.000006333 FPS (+0.00004076%)** against strict
control. The strict candidate was **−0.000005667 FPS (−0.00003647%)** against
that same control, so its negative mean rejects the change despite the positive
screen. All nine runs retained exactly 969 frames and framebuffer checksum
`1047377823`.

The strict i486 gate passed: 313,315 linked instructions across 435 code ranges,
529 startup code rows, and 9,207 DPMI provider instructions, with zero
above-i486, unknown, or exempt instructions. The parity-only candidate skipped
the ISA audit as intended.

Candidate source-tree fingerprint:
`4675790D41E9D78B31878DAA7CB07EA568F7E40A134E9D4377C03A578BD07FB4`.
Strict candidate executable SHA-256:
`9C12247CA0E9F49889A2150A3C2F7B7F1880B530B784E2FDA00616040AFD65DC`.
After restoring the shift, the source-tree fingerprint returned to the promoted
control value `8AF2A96E7076BC8B394E21D21A8A4386C0F4A8909D7B6DA9280AF61DEB0199C4`.
