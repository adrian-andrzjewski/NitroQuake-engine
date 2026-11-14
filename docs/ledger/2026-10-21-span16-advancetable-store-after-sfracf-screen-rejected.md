# Span16 `advancetable` store after `sfracf` load screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted setup
order stores `advancetable` after both fractional shifts in `src/renderer/d_draw16.s`.

The experiment moved `movl %eax,advancetable` from after both fraction shifts
to immediately after the `sfracf` reload, before the T-step and S-step shifts.
The T-fraction add still set the carry consumed by `sbbl`, and the S-fraction
add still set the carry consumed by the address `adcl`.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-162412` | 15.537297 / 15.537305 / 15.537287 | 15.537296333 | 0.000018 |

The candidate mean was **−0.000000667 FPS (−0.00000429%)** against the
promoted control. The negative mean rejects the earlier store. This parity-only
run skipped the strict i486 ISA audit.

Candidate source-tree fingerprint:
`6746CF56C66263BD65D4F5D38A49AD920C00FD26EF42B3CAFDF8C1BCFEF18918`.
Candidate executable SHA-256:
`D745C0CD436AEAA8A83B13ADC2A52A1CB0449AFAC301397C51F01E8A9B37E5B2`.
After restoring the store placement, the source-tree fingerprint returned to
the promoted control value
`8F7AD115D3A9B6C8EE807B3352DD94CC6AAEC6B63CA334868C5CCC745E082F8F`.
