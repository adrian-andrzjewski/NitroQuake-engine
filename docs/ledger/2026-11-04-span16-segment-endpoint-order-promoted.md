# Span16 full-segment endpoint conversion order promoted (2026-11-04)

## Optimization

Status: retained after exact parity, the complete strict i486 gate, and a
positive pooled mean over three uninstrumented runs per variant.

In `src/d_draw16.s` at `LNotLastSegment`, calculate and store the T endpoint
before the S endpoint. The candidate changes only the order of the two
independent `z * (t/z)` and `z * (s/z)` products and their `FISTP` stores. Each
product retains its original operands and rounding; after both pops, the x87
stack has the same `1/z | t/z | s/z` values for the following segment setup.

## Matched timing

The control already includes the separately measured initial-span S/T product
reorder. The candidate source fingerprint is
`F13C45F2D8CFB6BCD91B4F6D77F9FE9123536D8137E8A6772650E4CCF68D87FE`; control is
`DF762A53860FA2C7546C9A840800BBCE0EFDD059BC8C747C1F7883F233C5210D`.

Both variants used DOSBox-X `2026.08.31`, profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and 969-frame uninstrumented runs. Every run ended at
framebuffer checksum `1047377823`.

| Variant | Run artifacts | FPS samples | Mean FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261104-124743`, `...-124859`, `...-125015` | 16.377717 / 16.377707 / 16.377686 | 16.377703333 |
| Candidate | `out/dos-timedemo-20261104-124321`, `...-124441`, `...-124557` | 16.377707 / 16.377709 / 16.377715 | 16.377710333 |

The candidate pooled mean is **+0.000007000 FPS (+0.0000427%)**. The difference
is smaller than the observed sample spread; it is retained under the current
any-positive-mean acceptance rule, with the small size and overlap recorded.
The highest single sample in this six-run comparison was **16.377717 FPS** in
the control group.

## Correctness and compatibility

A fixed-step `host_framerate 0.0783` replay recorded 970 checksums with zero
overflow for both variants. The checksum streams and frame-695 PCX captures
were byte-identical. Artifacts are `out/dos-timedemo-20261104-123954` (control)
and `out/dos-timedemo-20261104-124136` (candidate).

The candidate strict build passed the complete i486 executable gate:
314,636 relocated instructions, 529 startup rows, and 9,207 DPMI provider
instructions; zero above-i486, unknown, or exempt instructions. Build output:
`out/local-span16-segment-tfirst-candidate-20261104/`.

## Artifacts

- Control timing: `out/dos-timedemo-20261104-124743`,
  `out/dos-timedemo-20261104-124859`, and
  `out/dos-timedemo-20261104-125015`.
- Candidate timing: `out/dos-timedemo-20261104-124321`,
  `out/dos-timedemo-20261104-124441`, and
  `out/dos-timedemo-20261104-124557`.
- Fixed-step replay: `out/dos-timedemo-20261104-123954` (control) and
  `out/dos-timedemo-20261104-124136` (candidate).
- Strict candidate build: `out/local-span16-segment-tfirst-candidate-20261104/`.
