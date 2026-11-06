# Alias tile-minimum early exit rejected (2026-11-06)

## Candidate

The whole-model alias occlusion query computes the minimum Z value for each
4-by-4 screen tile before it can reject a model. A candidate returned
immediately when the running minimum reached the model's conservative nearest
depth: that one pixel proves the current tile cannot occlude the whole model.

The first version stored that sample in the existing signed partial-minimum
cache. That encoding represents the top-left anchor, so using it for an
arbitrary pixel was invalid. A corrected version left the tile cache unchanged
on early return and was profiled again.

## Diagnostic results

Both runs used the pinned DOSBox-X 2026.08.31 `cputype=486` profile, the
fixed-step `demo1` workload, `-zchecksums`, 969 timed frames, and instrumented
`VisualParityOnly` builds. These are diagnostic profiles, not release timing
or a strict i486 audit.

| Variant | Run | Queries | Model culls | Tile checks | Z samples |
| --- | --- | ---: | ---: | ---: | ---: |
| Control | `out/dos-timedemo-20261106-134647` | 4,503 | 1,627 | 36,938 | 530,190 |
| Early exit, cache unchanged | `out/dos-timedemo-20261106-135818` | 4,503 | 1,627 | 36,938 | 526,676 |

The corrected candidate avoided 3,514 Z samples (0.663%). Its color checksum
stream differed from control at frame 690, while all 971 Z checksum records
matched. Both runs ended at framebuffer checksum `1047377823`; matching final
checksums do not establish frame-exact parity. No release timing or strict ISA
audit was run after this failure.

## Disposition

The early-exit candidate was removed. It saves a small number of tile reads in
the diagnostic profile but does not preserve exact per-frame color output.
The existing full tile-minimum scan remains in place. The ignored `out`
artifacts named above are retained for review.
