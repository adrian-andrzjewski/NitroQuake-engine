# Mip-3 horizontal-flat surface block (2026-10-20) — rejected

The earlier price-only estimate reopened when the fixed promotion floor was
removed. An opt-in i486 assembly path detected equal left/right light values
and row increments, then rendered each 2×2 block with one shade per row.

## Matched timedemo

DOSBox-X 2026.08.31, `cputype=486`, fixed 33,445 cycles, 32 MB profile,
CWSDPMI, verified `testdata/id1`, `demo1`, 969 frames, and framebuffer checksum
`1047377823`. Both runs used profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Run times (s) | Run FPS | Mean time (s) | Mean FPS | ISA status |
|---|---|---|---:|---:|---|
| Control | 62.508420 / 62.508410 / 62.508409 | 15.501912 / 15.501914 / 15.501915 | 62.508413 | 15.501913667 | Full linked audit PASS |
| Mip-3 flat fast path | 62.508670 / 62.508720 / 62.508690 | 15.501849 / 15.501837 / 15.501845 | 62.508693 | 15.501843667 | Skipped for diagnostic screen |

Every run reached 969 frames with checksum `1047377823`. The candidate was
**0.000070 FPS slower** (**−0.0004516%** mean FPS); every candidate run also
took longer than every control run. Control timing spread was 0.000011 s and
candidate spread was 0.000050 s, so the negative result exceeded the observed
within-variant spread.

## Decision

Reject and remove the fast path and its temporary selector. The measured result
does not support promotion. The candidate's checksum gate passed, but its
diagnostic build skipped the ISA audit; no strict candidate audit was run after
the timed regression. The previously promoted cache-key fusion remains in the
working source.
