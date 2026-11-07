# Surface span records compacted to 12 bytes (2026-11-07)

## Candidate

`espan_t` now stores the nonnegative screen coordinates `u` and `v` as
16-bit unsigned values, followed by the 32-bit pixel count and pointer link.
The record shrinks from 16 to 12 bytes. C and assembly producers and consumers
were updated together, including the scan-edge, texture-span, turbulent-span,
sky-span, solid-surface, and Z-span paths. Coordinate loads zero-extend the
16-bit fields; x87 setup uses `FILD` from the short fields.

At `MAXSPANS == 3000`, the scratch span pool falls from 48,000 to 36,000 bytes,
a 12,000-byte or 25% reduction. Across 3,500,713 generated spans in the
instrumented `demo1` replay, the narrower coordinate fields avoid up to
14,002,852 bytes of coordinate stores. This count ranks the locality and write
traffic hypothesis; it is not a timing measurement.

## Output parity

The candidate replay at `out/worktree-span12-debug/out/dos-timedemo-20261107-133558`
was compared against the clean current-head control at
`out/dos-timedemo-20261107-083815`. All three candidate color checksum streams
matched all 970 control records; the Z checksum stream was byte-for-byte
identical. The candidate and control color-stream SHA-256 is
`69F4F9869D9AACD9704085EA984DE4E95226795F56615209B26F0B07D11D6883`; the Z
stream SHA-256 is
`3C886D24243FCE937F3EF483F723B2CD3389C9C54B84EAD8625C59F2A0F874F3`.

Frame 154 was captured from the candidate and the accepted clip-chain control
worktree. The 320-by-200 indexed image and palette matched exactly (64,000
pixels, zero changed pixels); both PCX files have SHA-256
`6F71B7D4555631974C5BBE9FBD3E1E4DDB398C122FDC891B6B9BA953A725EF0F`.

## Strict i486 audit

The release candidate passed the complete strict i486 gate: 315,217 linked
instructions, 529 DOS startup rows, and 9,207 DPMI-provider instructions, with
zero above-i486, unknown, or exempt instructions. The project and runtime
source proofs passed.

## Matched release timing

Both variants used DOSBox-X 2026.08.31, the pinned 320-by-200 `demo1` workload,
969 timed frames, profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and
framebuffer checksum `1047377823`. Neither timing run used instrumentation.

The current-head control is `out/dos-timedemo-20261107-091354`; the candidate
is `out/worktree-span12-debug/out/dos-timedemo-20261107-140458`.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.758520, 16.758503, 16.758497 | 16.758506667 |
| 12-byte span record | 16.816114, 16.816080, 16.816077 | 16.816090333 |

The candidate mean is **0.3436% faster**. The gain is small and specific to
this emulator profile; it is not a physical-486 performance claim.
