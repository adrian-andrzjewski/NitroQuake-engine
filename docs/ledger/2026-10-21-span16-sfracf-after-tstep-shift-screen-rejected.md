# Span16 `sfracf` load after T-step shift screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
`sfracf` load before the T-step shift remains active in `src/d_draw16.s`.

The experiment moved `movl sfracf,%ebx` after the T-step fractional shift in
`LSetUpCommon`, while retaining the promoted S-step shift position after the
T-step shift and before the `advancetable` store. The following T-fraction add
continued to set the carry consumed by `sbbl`.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-160121` | 15.537298 / 15.537287 / 15.537291 | 15.537292000 | 0.000011 |

The candidate mean was **−0.000005000 FPS (−0.00003218%)** against the
promoted control. The negative mean rejects the order. This parity-only run
skipped the strict i486 ISA audit.

Candidate source-tree fingerprint:
`F1E0468F7819B766EFFC2D5312636C16A63D0971B5D57E8FEAF4A08155EE0E21`.
Candidate executable SHA-256:
`A6663A98A2DE8FA0F34D8AFBF38E206D71C1B43BA46AA644C2B6B6415E3FD2F8`.
After restoring the load order, the source-tree fingerprint returned to the
promoted control value
`8F7AD115D3A9B6C8EE807B3352DD94CC6AAEC6B63CA334868C5CCC745E082F8F`.
