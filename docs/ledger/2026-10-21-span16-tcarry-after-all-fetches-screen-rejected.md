# Span16 T-carry deferral to high-byte fetches rejected (2026-10-21)

The promoted low-byte-only T-carry schedule remains active in
`src/renderer/d_draw16.s`. This parity-only extension moved each high-byte fetch ahead of
the `sbbl %ecx,%ecx` T-carry extraction. At sites where the S-fraction add was
ahead of the high-byte load, that add remained after the load and after SBB.

The comparison used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted low-byte-only control, 3 runs | `out/dos-timedemo-20261021-125419` | 15.537309 / 15.537297 / 15.537300 | 15.537302000 | 0.000012 |
| Defer T-carry after all fetches, 3 runs | `out/dos-timedemo-20261021-132752` | 15.537297 / 15.537297 / 15.537297 | 15.537297000 | 0.000000 |

The extension's pooled mean was **−0.000005000 FPS (−0.00003219%)**. All six
runs completed 969 frames with framebuffer checksum `1047377823`. The
parity-only screen skipped the strict ISA audit; its negative mean rejects the
extension. The high-byte instruction orders were restored, leaving the
low-byte-only promotion intact.
