# `R_GenerateSpans` non-bmodel sort twenty-four-way unroll rejected (2026-10-29)

Status: rejected after two three-run 320x200 parity screens failed to show a
repeatable gain over a fresh sixteen-way control.

The candidate extended `Lsortloopnb` from sixteen to twenty-four active-surface
comparisons before its backward branch. Every signed comparison still exited
immediately to insertion, and the optional per-comparison profile counter and
dead-scratch probe remained in place. The hypothesis was that the middle-sized
unroll might reduce loop branches without the instruction footprint of the
rejected thirty-two-way version.

## Matched 320x200 timedemo

Runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector
profile, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Timings
were uninstrumented and used the default 320x200 demo path. All runs rendered
969 frames and ended with framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS | Median FPS |
|---|---|---|---:|---:|---:|
| Sixteen-way control recheck | `out/dos-timedemo-20261029-184901/timedemo-result.json` | 16.321721 / 16.321724 / 16.321708 | 0.000016 | 16.321717667 | 16.321721 |
| Twenty-four-way screen A | `out/dos-timedemo-20261029-184425/timedemo-result.json` | 16.321756 / 16.321716 / 16.321715 | 0.000041 | 16.321729 | 16.321716 |
| Twenty-four-way repeat B | `out/dos-timedemo-20261029-185401/timedemo-result.json` | 16.321720 / 16.321701 / 16.321712 | 0.000019 | 16.321711 | 16.321712 |

The two candidate means point in opposite directions. Across all six candidate
runs, the mean was **16.321720 FPS**, only **0.000002333 FPS (+0.0000143%)**
above the fresh control mean; the repeated candidate set alone was
**0.000006667 FPS slower**. Candidate medians were also below the control
median, and the small pooled mean difference is less than the candidate
between-run variation.

An earlier control screen at `out/dos-timedemo-20261029-183910` contained one
slow sample (16.273363 FPS versus 16.321717 and 16.321724). That unstable set
was excluded from the comparison and prompted the fresh control recheck.

The timedemo used `VisualParityOnly`, so it enforced frame-count and checksum
parity but skipped the strict whole-executable ISA audit. No strict audit was
run because the speed result was not repeatable. Source fingerprints were
`4D864F34CE5D1FD6F678B9368A843434F150D0F38EBF5840F7602D51D97F1FAF` for the
control, `33209947A216237D083844A9F5BFEA7728C7E3E26A4FB933974E8D48EE706A4C`
for screen A, and
`365A47106ACADA408A6AD6E43AC7E78A8DDA748717895B47D67EF91C5FE3304B` for
repeat B. All used the pinned profile above.

## Disposition

The eight extra comparison blocks were removed. `Lsortloopnb` remains
unrolled sixteen ways; the 24-way candidate is not retained as a performance
improvement.
