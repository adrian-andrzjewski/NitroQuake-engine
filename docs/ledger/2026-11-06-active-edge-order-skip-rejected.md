# Active-edge monotone-order skip rejected (2026-11-06)

## Candidate

`R_StepActiveU` advances four active edges at a time and checks each edge's new
horizontal position against its predecessor. The experiment marked an edge when
its fixed-point slope was no smaller than its predecessor's, then skipped that
ordering comparison because the pair could not cross during the next scanline.
The tag occupied bit zero of the existing `edge_t.owner` pointer while the edge
was in the active list. Insertions, removals, and pushbacks updated tags, and the
scan cleared them before later face code could use the owner pointer. The C
reference path and i486 assembly edge-list code maintained the adjacency tags;
the i486 assembly walker used them to skip comparisons. No edge storage was
added.

## Exact output and i486 gates

The release candidate at source fingerprint
`D6F546671794FEF7B61D34B3E5F9BF5D4389D748B759324B44AB3A8E3CACD81F` and the
clean control at revision `4bc0d1dd6134` used the DOSBox-X 2026.08.31 high i486
profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`cwsdpmi`, demo1, 320x200, `host_framerate 0.0783`, and
`con_notifytime -1`. The renderer sources at `4bc0d1dd6134` and the candidate's
base revision `c8ad90ba8c03` were identical; intervening commits changed documents
only.

The candidate and a fresh clean-control release replay rendered 969 timed
frames and ended at framebuffer checksum `1047377823`. Their complete color
and Z checksum streams and captured frame 482 PCX were byte-identical:

| Output | SHA-256 |
| --- | --- |
| Color checksum stream | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

The candidate's complete linked i486 gate passed: 315,333 relocated
instructions across 435 source-bound code ranges, 529 startup rows, and 9,207
DPMI provider instructions; there were no above-i486, unknown, exempt, or
unclassified instructions. The exact-source proof covered 403 project and
runtime objects.

## Matched uninstrumented timing

Each variant ran three times with `-Runs 3 -NoBootstrap -NoFpsStats`, without
per-frame checksum or FPS instrumentation. The control was rebuilt from the
clean worktree and passed the same linked i486 gate. All runs rendered 969
frames and ended at checksum `1047377823`.

| Variant | Result folder | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Clean control | `out/worktree-bsp-face-ranges-control-20261106/out/dos-timedemo-20261106-113119` | 16.751569, 16.751619, 16.751617 | 16.751602 | 16.751617 |
| Monotone-order tags | `out/dos-timedemo-20261106-111435` | 16.640724, 15.907347, 16.640726 | 16.396266 | 16.640724 |

The candidate mean was 2.121206% slower and its median was 0.661984% slower.
Every candidate sample was below every control sample. The lower second
candidate sample widened the mean regression; even the candidate median did
not reach the slowest control result.

The source-contract suite reported 112 tests: 107 passed and 5 unrelated
profile-fixture or source-pattern checks failed (alias stats, linegraph,
smoke-runner selector count, sprite-face clipping, and timegraph). The DOS
build-contract suite had previously been interrupted without a result; both
timedemo release builds and their complete i486 gates passed independently.

## Conclusion

Reject and revert the active-edge order tags. Exact output and the strict i486
gate passed, but the saved predecessor comparisons did not repay the extra
adjacency bookkeeping on this workload. Keep the benchmark and parity reports
under the ignored `out/` directory as evidence.
