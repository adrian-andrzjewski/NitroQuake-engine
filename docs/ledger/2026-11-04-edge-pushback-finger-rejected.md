# Active-edge scanline predecessor finger rejected (2026-11-04)

The candidate kept the active-edge list as the source of truth and retained the
most recent insertion predecessor in a register for the current scanline. On a
later pushback it reused that pointer only when its U value was strictly
between the edge's target and the normal backward-search start. No index or
extra edge storage was added.

## Profile census and ISA audit

The profile-only run recorded 95,759 pushback-search iterations and selected
the finger 467 times. The control profile recorded 96,243 iterations. The
candidate therefore removed only 484 loop iterations, while adding the hint
checks to each pushback search. This was not enough work reduction to justify
an uninstrumented timing A/B.

Both builds passed the complete strict i486 audit. The profile build covered
168 objects and 283,772 object instructions, 403 linked objects and 322,069
linked instructions, 529 startup rows, and 9,207 provider instructions. The
release build covered 168 objects and 276,347 object instructions, 403 linked
objects and 314,644 linked instructions, 529 startup rows, and 9,207 provider
instructions. Every relocated instruction was mapped; both builds had zero
above-i486, unknown, or exempt instructions.

## Parity and disposition

The uninstrumented candidate rendered 969 timed frames and produced 970 color
checksum records. Against each of the three control runs, 288 records differed
between frames 32 and 948. The control runs differed among themselves at only
three records (frames 728, 730, and 731 for run 1 versus run 2; frames 728,
729, and 731 for run 1 versus run 3). The candidate retained the final
framebuffer checksum `1047377823`, but failed per-frame color parity. This
checksum run did not enable `-zchecksums`, so it produced no candidate Z stream;
the color failure already rejects the implementation.

The control was `out/dos-timedemo-20261104-194409`; the candidate parity run
was `out/dos-timedemo-20261104-215722`. The profile census is in
`out/dos-timedemo-20261104-213918`. Builds and ISA reports are in
`out/local-edge-pushback-finger-profile-20261104` and
`out/local-edge-pushback-finger-uninstrumented-20261104`. All runs used DOSBox-X
2026.08.31 and the pinned i486 profile hash
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

The candidate is rejected for color-parity failure and insufficient profile
work reduction. No source implementation is retained, and no performance claim
is made from the checksum-enabled run.
