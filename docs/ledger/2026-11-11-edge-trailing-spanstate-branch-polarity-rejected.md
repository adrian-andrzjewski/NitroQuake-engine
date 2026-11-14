# `TrailingEdge` spanstate branch polarity rejected (2026-11-11)

<!-- optimization-attempt: edge-trailing-spanstate-branch-polarity rejected -->

## Candidate

The current helper decrements `st_spanstate` and branches to a one-instruction
return when the value remains nonzero. In the measured `demo1` profile,
`TrailingEdge` runs 2,237,382 times and 53% of calls do not emit a span. The
candidate inverted the conditional and placed `ret` on the fall-through path,
so the common no-emit case could return without taking a branch.

### Correctness and compatibility

Control and candidate used the pinned DOSBox-X 2026.08.31 i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`) and the
same `demo1` data. Both produced 969 timed frames and final framebuffer
checksum `1047377823`.

The deterministic replay compared 970 color-checksum records, 970 Z-checksum
records, and the frame 482 PCX. Each stream and the image matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksums | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

The control and rebuilt candidate both passed the complete strict i486 gate:
316,141 linked instructions, 529 startup CODE rows, and 9,207 DPMI-provider
instructions, with zero above-i486, unknown, or exempt instructions. Source
proofs covered 403 native/annotated objects and 435 linked contributions.

### Matched timing

The uninstrumented release runs used the same pinned DOSBox-X profile and
enforced the 969-frame and final-checksum gates.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.892475 / 16.892428 / 16.892441 | 16.892448000 |
| Candidate | 16.892445 / 16.892436 / 16.892441 | 16.892440667 |

The candidate mean was **0.000007333 FPS lower (-0.0000434%)**. This is below
the sample spread, so the result supports no measurable gain and is not a
performance claim. DOSBox-X results do not establish physical-486 performance.

### Artifacts and disposition

- Control release: `out/local-local-edge-trailing-branch-polarity-control-20261111/`
- Candidate release: `out/local-local-edge-trailing-branch-polarity-candidate-rebuilt-20261111/`
- Control parity: `benchmarks/out/dos-timedemo-20261111-020037/`
- Candidate parity: `benchmarks/out/dos-timedemo-20261111-022038/`
- Control timing: `benchmarks/out/edge-trailing-branch-polarity-control-timing-20261111.json`
- Candidate timing: `benchmarks/out/edge-trailing-branch-polarity-candidate-timing-20261111.json`

The branch-polarity change was removed. `src/renderer/r_edgea.s` is back to the control
implementation; retain the ignored output artifacts for review.
