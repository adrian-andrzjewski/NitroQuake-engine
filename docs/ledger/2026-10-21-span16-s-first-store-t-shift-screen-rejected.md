# Span16 S-first/store/T-shift screen rejected (2026-10-21)

Status: reverted after a negative three-run parity screen. The promoted
T-step-shift, S-step-shift, `advancetable` store order remains active in
`src/renderer/d_draw16.s`.

The experiment reordered the independent setup operations to shift the S-step
fraction first, store `advancetable`, and then shift the T-step fraction. The
following T-fraction `addl` still set the carry consumed by `sbbl`; fixed-point
arithmetic and memory operands were unchanged.

The uninstrumented runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |
| Parity-only candidate screen, 3 runs | `out/dos-timedemo-20261021-160730` | 15.537290 / 15.537304 / 15.537283 | 15.537292333 | 0.000021 |

The candidate mean was **−0.000004667 FPS (−0.00003004%)** against the
promoted control. The negative mean rejects the order. This parity-only run
skipped the strict i486 ISA audit.

Candidate source-tree fingerprint:
`BB5B26F82350DB2660305B821CEB666C44D4C5D63E994E70073A394520523D9E`.
Candidate executable SHA-256:
`3849F2900E450036571C239BFA1888ABE9DD516C4FD0821DF75BEB0CF5C58E2E`.
After restoring the instruction order, the source-tree fingerprint returned to
the promoted control value
`8F7AD115D3A9B6C8EE807B3352DD94CC6AAEC6B63CA334868C5CCC745E082F8F`.
