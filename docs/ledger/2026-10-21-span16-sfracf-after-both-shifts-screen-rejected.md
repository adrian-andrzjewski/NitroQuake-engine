# Span16 `sfracf` load after both shifts screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted order
loads `sfracf` before either fractional shift in `src/d_draw16.s`.

The experiment moved `movl sfracf,%ebx` after both the T-step and S-step
fractional shifts, while keeping the promoted order of those shifts and the
`advancetable` store. The following T-fraction add continued to set the carry
consumed by `sbbl`.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-161235` | 15.537299 / 15.537290 / 15.537283 | 15.537290667 | 0.000016 |

The candidate mean was **−0.000006333 FPS (−0.00004076%)** against the
promoted control. The negative mean rejects the load order. This parity-only
run skipped the strict i486 ISA audit.

Candidate source-tree fingerprint:
`234C297F9F1950F14562D7BA365191D482D0E58FAE1F46DEF9C02997346F3488`.
Candidate executable SHA-256:
`9A353A8BD125687092FB389F9F087A24DAE82091ECDBDD989C905B3261049663`.
After restoring the load order, the source-tree fingerprint returned to the
promoted control value
`8F7AD115D3A9B6C8EE807B3352DD94CC6AAEC6B63CA334868C5CCC745E082F8F`.
