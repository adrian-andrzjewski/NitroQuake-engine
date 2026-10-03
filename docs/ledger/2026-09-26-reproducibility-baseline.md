# Reproducibility note and the first baseline (2026-09-26)

Extracted verbatim from `ASM486-HANDOFF.md` lines 3578-3611 (`## Current state`),
which held all 74 dated log entries under one heading. Nothing in the text below has
been reworded; the only edits are that re-parented sub-headings were demoted one level and
cross-file references were repointed by heading, as the process rule in
`ASM486-HANDOFF.md` requires. Entries appear newest first, as they did in the original.

Index of every entry: [`../INDEX.md`](../INDEX.md).

## Current reproducibility note (2026-09-26)

ASM/setup: D_SetupFrame now lazily rebuilds viewspantable only when the active
view buffer or effective row stride changes. Full correctness and video tests
pass. Three raw demo1 runs measured 59.422468 / 59.422417 / 59.422374
seconds (median 16.306977 FPS), checksum 1047377823 on every run, versus the
16.297855 FPS clean baseline.

The benchmark worktree seeds srand(1) at the start of PROFILE486 timedemos and
uses -falign-jumps=16 in the aggressive DOS build. These changes make the
current profiling/timedemo workload deterministic enough for A/B comparison,
but they change the framebuffer reference from older handoff runs. The current
worktree authority is 969 frames with checksum 1047377823; older reports using
4154140932 remain historical results and must not be mixed into current A/B
comparisons.

The optional ASM surface-cache predicate was rechecked with guarded dispatch
and then rejected: C median 59.506742 seconds (16.283870 FPS) versus ASM median
59.512084 seconds (16.282407 FPS) across three raw runs. All runs completed
969 frames with checksum 1047377823, and both variants passed the full 486
benchmark correctness PASS harness. Keep the C surface-cache predicate as the
default; a focused helper win is insufficient when the complete timedemo loses.

The negative-gradient Z-span eight-pixel packing schedule was rechecked with
the current seeded workload. It is available only through the explicit
`-ZSpanNegativeUnroll unroll8` build/timedemo option; `control` remains the
production default. Three matched runs completed 969 frames with checksum
1047377823: control measured 59.408069 seconds median and `unroll8` measured
59.408076 seconds. The candidate is rejected as a marginal regression, but the
selector remains for reproducible A/B work. The accompanying PROFILE486 run
puts texture spans first at 28.11% of instrumented self time, making them the
next optimization target; the instrumented duration is attribution evidence,
not a release timing claim.

