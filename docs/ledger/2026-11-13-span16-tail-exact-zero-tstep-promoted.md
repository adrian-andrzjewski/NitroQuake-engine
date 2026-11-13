# Exact-zero-T texture-span tail path promoted (2026-11-13)

## Change

`D_DrawSpans16` now dispatches short tail segments with an exactly zero T step
to a dedicated suffix. The first texel is already loaded by the shared setup;
the suffix advances the S fixed-point accumulator and writes the remaining
texels without repeating the T accumulator update, carry conversion, or
T-based texture-address lookup. Color and Z processing order are unchanged.
`TextureSpanTailTZeroPath=control` remains available for comparisons.

## Profile census

An instrumented 320x200 profile counted exact-zero-T opportunities in the
remainder after each span's first pixel:

| Map | Tail segments | Zero-T tail segments | Post-first tail samples | Extra samples with zero T | Share |
| --- | ---: | ---: | ---: | ---: | ---: |
| e1m1 | 229,739 | 84,456 | 1,455,989 | 642,567 | 44.13% |
| e1m2 | 223,149 | 91,585 | 1,406,616 | 648,659 | 46.11% |

The counter build is instrumented and its elapsed time is not used for the
performance claim. Captures are
[`e1m1`](../../../benchmarks/out/span16-tailstep-e1m1-20261113.json) and
[`e1m2`](../../../benchmarks/out/span16-tailstep-e1m2-20261113.json).

## Matched local-gameplay timing

Three uninstrumented runs per variant and map used DOSBox-X 2026.08.31,
`cputype=486`, FPU 387, 33,445 fixed cycles, 320x200, sound off, 64 warm-up
frames, 256 measured frames, and a fixed 0.0625-second simulation step. Both
variants used the promoted full-span zero-T selector; only the tail selector
changed. Their source-tree fingerprint was
`96A01BB8488B863C8C52C6F563B7E31BC530DA0EF7E1D450E1363A0D2ADF3B03`.

| Map / run | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| e1m1 / 1 | 10.461404 / 24.470903 | 10.404790 / 24.604051 |
| e1m1 / 2 | 10.461410 / 24.470890 | 10.404797 / 24.604036 |
| e1m1 / 3 | 10.461396 / 24.470921 | 10.404798 / 24.604034 |
| e1m2 / 1 | 11.340589 / 22.573783 | 11.281203 / 22.692616 |
| e1m2 / 2 | 11.340592 / 22.573778 | 11.281192 / 22.692638 |
| e1m2 / 3 | 11.340587 / 22.573788 | 11.281196 / 22.692630 |

Pooled over 1,536 frames, FPS rose from **23.484092** to **23.609711**
(**+0.5349%**). The per-map mean gains were **+0.5441%** on e1m1 and
**0.5265%** on e1m2. Every sample was faster. Each variant retained exact
simulation and final framebuffer checksums:

| Map | Simulation checksum | Framebuffer checksum |
| --- | ---: | ---: |
| e1m1 | 2568184557 | 1299435123 |
| e1m2 | 1496920581 | 1246513233 |

The control and candidate qbench executable SHA-256 values were
`1A99AAC6C9401A03F4E2849188D580AE3EF03A039692997DD74BD3E2A2E1566D` and
`D86914F5C1ED66C41AEAADBD9EA151334D6B44F6C1779DF955BFBFB74162A54D`.
The twelve timing records are under
`benchmarks/out/span16-tail-tzero-{control,candidate}-e1m{1,2}-{1,2,3}-20261113.json`.

## Exact demo color and depth parity

Three fixed-presentation-clock `demo1` replays per variant recorded 970 color
and Z checksum frames each, with zero overflow. Control and candidate streams
matched byte-for-byte in every run. The color trace SHA-256 was
`FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C`; the Z
trace SHA-256 was
`4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37`.
The final framebuffer checksum was `1047377823` in all replays.

See the [control replay](../../../benchmarks/out/span16-tail-tzero-control-demo1-parity-20261113.json)
and [candidate replay](../../../benchmarks/out/span16-tail-tzero-candidate-demo1-parity-20261113.json).

## i486 build evidence

Both source-matched qbench variants passed the complete strict i486 source,
object, linked executable, startup, and DPMI-provider gates. Control linked
317,579 instructions and candidate linked 317,651; the candidate adds 72
instructions. Both verified 529 startup rows and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. The final default-profile
release build also passed: 165,223 linked instructions, 529 startup rows, and
9,207 provider instructions, with zero violations. Its executable SHA-256 is
`8120B67C0DED00ABEE9584CD1E7FCC0623F00163F6E1519B8B215E0E333CC5D7`.

## Limits

The measured improvement is repeatable in the selected DOSBox-X local-game
workloads and passes exact color/Z parity, so the i486 release profile enables
the specialization while preserving a control selector. DOSBox-X elapsed time
does not establish physical-486 cycle counts, cache behavior, or hardware FPS.
