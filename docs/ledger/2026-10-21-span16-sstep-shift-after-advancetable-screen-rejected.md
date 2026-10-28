# Span16 S-step shift after `advancetable` store screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The S-step shift at
the start of `LSetUpCommon` remains active in `src/d_draw16.s`.

The experiment moved `shll $12,%ebp` from the start of `LSetUpCommon` to just
after `movl %eax,advancetable` and before the T-fraction addition. The T-fraction
`addl` still set the carry consumed by `sbbl`, and the later S-fraction `addl`
still set the carry consumed by the address `adcl`.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-143832` | 15.537293 / 15.537292 / 15.537300 | 15.537295000 | 0.000008 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-152626` | 15.537293 / 15.537288 / 15.537300 | 15.537293667 | 0.000012 |

The candidate mean was **−0.000001333 FPS (−0.00000858%)** against control.
The negative mean rejects the order. This was a parity-only run, so it skipped
the strict i486 ISA audit.

Candidate source-tree fingerprint:
`4D7567493039B30D8B05A211137871B37A8201C2E8F6B064D9A367900D937854`.
Candidate executable SHA-256:
`54CA6E34B5F880C31396DE9DB1A0BE7A77C919BEDFA001B7621427C42EDB2A1F`.
After restoring the instruction order, the source-tree fingerprint returned to
the promoted control value `8AF2A96E7076BC8B394E21D21A8A4386C0F4A8909D7B6DA9280AF61DEB0199C4`.
