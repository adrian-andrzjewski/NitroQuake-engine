# Span16 `loadfirst` recheck against the current control rejected (2026-10-21)

`TextureSpanLoadOrder=control` remains the default. This parity-only recheck
measured the existing `loadfirst` schedule against the currently promoted
low-byte T-carry schedule in the default word-store path.

The comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Current control, 3 runs | `out/dos-timedemo-20261021-125419` | 15.537309 / 15.537297 / 15.537300 | 15.537302000 | 0.000012 |
| `loadfirst`, 3 runs | `out/dos-timedemo-20261021-133338` | 15.537287 / 15.537288 / 15.537295 | 15.537290000 | 0.000008 |

The `loadfirst` mean was **−0.000012000 FPS (−0.00007724%)** against control.
All six runs completed 969 frames with framebuffer checksum `1047377823`. The
parity-only screen skipped the strict ISA audit; its negative mean leaves the
current control order active and `loadfirst` opt-in.

## Recheck after the S-step shift promotion

After promoting the S-step shift after the T-step shift, the `loadfirst`
selector was rechecked against the new promoted source with the same pinned
profile and workload.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict promoted control, 3 runs | `out/dos-timedemo-20261021-155525` | 15.537299 / 15.537295 / 15.537297 | 15.537297000 | 0.000004 |
| `loadfirst` parity-only screen, 3 runs | `out/dos-timedemo-20261021-161822` | 15.537304 / 15.537297 / 15.537287 | 15.537296000 | 0.000017 |

The refreshed `loadfirst` mean was **−0.000001000 FPS (−0.00000644%)** against
the promoted control. All six runs retained 969 frames and checksum
`1047377823`. The parity-only screen skipped the strict ISA audit; its negative
mean leaves `TextureSpanLoadOrder=control` as the default.
