# Span16 initial-span S/T product order promoted (2026-11-04)

## Optimization

Status: retained after a positive four-run uninstrumented comparison, exact
fixed-step parity, and a strict i486 audit.

In the initial and same-row Span16 setup paths, calculate the T product before
the S product. This removes an x87 exchange while preserving both products'
operands, their rounding, and the stack state consumed by the endpoint stores.
The later endpoint-order comparison's control source already contains this
schedule.

## Matched timing

Both variants used DOSBox-X `2026.08.31`, profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and 969-frame uninstrumented runs. The control source
fingerprint is
`9959727CCAB11C391B6E3047E2ED0607410907B1AA91092CC4D07E7F33F5EFBE`; the
candidate source fingerprint is
`DF762A53860FA2C7546C9A840800BBCE0EFDD059BC8C747C1F7883F233C5210D`.
Every run ended at framebuffer checksum `1047377823`.

| Variant | Run artifacts | FPS samples | Mean FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261104-120451`, `...-121424`, `...-121541`, `...-121656` | 12.831455 / 16.365715 / 16.365732 / 16.365687 | 15.48214725 |
| Candidate | `out/dos-timedemo-20261104-120634`, `...-121028`, `...-121144`, `...-121259` | 12.838839 / 16.377713 / 16.377695 / 16.377707 | 15.4929885 |

The candidate pooled mean increased by **0.01084125 FPS (+0.07002%)**. The first
paired run was slow for both variants; it is retained in these means. The three
later runs per variant were between 16.365687 and 16.377713 FPS.

## Correctness and compatibility

The experiment record reports byte-identical fixed-step frame checksums and a
passing complete strict i486 gate. The timing result files each report 969
frames and the same final checksum. The separate replay paths and strict audit
counts were not recovered from the retained output during this cleanup.

## Artifacts

- Control results: `out/dos-timedemo-20261104-120451/timedemo-result.json`,
  `out/dos-timedemo-20261104-121424/timedemo-result.json`,
  `out/dos-timedemo-20261104-121541/timedemo-result.json`, and
  `out/dos-timedemo-20261104-121656/timedemo-result.json`.
- Candidate results: `out/dos-timedemo-20261104-120634/timedemo-result.json`,
  `out/dos-timedemo-20261104-121028/timedemo-result.json`,
  `out/dos-timedemo-20261104-121144/timedemo-result.json`, and
  `out/dos-timedemo-20261104-121259/timedemo-result.json`.
- Candidate executable: `out/local-span16-x87-tfirst-candidate-20261104/`.
- Matched control executable: `out/local-span16-tswap-control-complete-20261104/`.
