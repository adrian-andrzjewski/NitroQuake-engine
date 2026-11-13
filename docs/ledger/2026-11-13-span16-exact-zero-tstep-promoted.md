# Exact-zero-T texture-span path promoted (2026-11-13)

## Change

`D_DrawSpans16` now has an i486-default specialization for full 16-pixel
segments whose unshifted T delta is exactly zero. It keeps the existing S
fixed-point accumulator, source address carry, and color writes, while removing
the per-pixel T accumulator update, carry conversion, and T-based source-address
selection. Segments with any nonzero T delta still use the existing control
path. `TextureSpanTZeroPath=control` remains available for comparisons.

This does not skip framebuffer or Z-buffer work. It specializes texture
addressing only; Z spans continue to execute as before.

## Profile basis

The instrumented 320x200 local-game profiles counted exact-zero T deltas on
full 16-pixel segments:

| Map | Full segments | Exact-zero-T segments | Share |
| --- | ---: | ---: | ---: |
| e1m1 | 883,165 | 482,008 | 54.58% |
| e1m2 | 881,669 | 400,332 | 45.41% |

These counters justified testing the specialization; they are not timing
measurements. The source profile, component rankings, and instrumentation
limits are described in
[`ENGINE-PROFILING-20261113.md`](../../../benchmarks/docs/ENGINE-PROFILING-20261113.md).

## Matched local-gameplay timing

Three uninstrumented qbench runs per variant and map used DOSBox-X 2026.08.31,
`cputype=486`, FPU 387, 33,445 fixed cycles, 320x200, sound off, 64 warm-up
frames, and 256 measured frames at a fixed 0.0625-second simulation step.
Control and candidate were built from the same source tree fingerprint.
`2A5F6930ED3B817457135164BD2FAA1F185E85FDDA74EC0C4A20BBC7E9BAFCDF`.
The qbench control and candidate executable SHA-256 values were
`68F5ADC63A63A891F0FFD19D4BB6E7120CA0214AADA042F13527C4299EFDBD45` and
`469012117BFFE54A0FE4F4685AD5B1DE550C1BC27754FF39576B3EA11860A835`.

| Map | Control FPS samples | Control mean | Candidate FPS samples | Candidate mean | Change |
| --- | --- | ---: | --- | ---: | ---: |
| e1m1 | 23.691877, 23.691851, 23.691869 | 23.691866 | 24.470899, 24.470893, 24.470884 | 24.470892 | +3.288160% |
| e1m2 | 22.055426, 22.055423, 22.055400 | 22.055416 | 22.573773, 22.573791, 22.573785 | 22.573783 | +2.350292% |
| Both maps pooled |  | 22.844372 |  | 23.484087 | +2.800318% |

Every run had the same final simulation and framebuffer checksums as its
matched variant:

| Map | Simulation checksum | Framebuffer checksum |
| --- | ---: | ---: |
| e1m1 | 2568184557 | 1299435123 |
| e1m2 | 1496920581 | 1246513233 |

## Exact demo color and depth parity

Three fixed-presentation-clock `demo1` replays per variant reported 969 demo
frames and 970 color and Z checksum frames. Every control run matched every
other control run, every candidate run matched every other candidate run, and
the control and candidate checksum files were byte-identical. The color trace
SHA-256 was
`FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C`; the Z
trace SHA-256 was
`4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37`.
The final demo framebuffer checksum was `1047377823` in each run.

Control and candidate demo records are
[`control`](../../../benchmarks/out/span16-tzero-control-demo1-parity-20261113.json)
and
[`candidate`](../../../benchmarks/out/span16-tzero-fast-demo1-parity-20261113.json).
The three matched gameplay timing records per map are under
`benchmarks/out/span16-tzero-{control,fast}-e1m{1,2}*.json`.

## i486 build evidence

The source-matched qbench control and candidate builds passed the full strict
i486 audit. The candidate linked 317,579 instructions, 529 startup rows, and
9,207 DPMI-provider instructions, with zero above-i486, unknown, or exempt
instructions. The release-profile build with the specialization as the i486
default also passed the strict linked, startup, and provider gates: 165,151
linked instructions, 529 startup rows, and 9,207 provider instructions, with
zero violations. Its executable SHA-256 is
`5591E134D9A1779A7370700CCED85ED887FD6D4A9EBA0753338BB760200187AF`.

## Limits

The gain is repeatable in these DOSBox-X workloads and large enough to retain.
DOSBox-X does not establish real 486 cycle counts, L1 cache behavior, or
physical-hardware FPS. The optimization preserves all measured color and Z
output; additional scenes remain useful regression coverage.
