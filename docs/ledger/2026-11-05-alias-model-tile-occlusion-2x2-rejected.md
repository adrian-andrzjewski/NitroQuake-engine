# Whole-model alias occlusion with 2-by-2 tiles rejected (2026-11-05)

## Candidate

The accepted whole-model alias occlusion cache stores a lazy minimum Z and
8-bit epoch for each 4-by-4 screen tile. This experiment reduced the tile size
to 2-by-2 pixels, increasing the cache from 4,000 entries and 12,000 bytes to
16,000 entries and 48,000 bytes. It retained the same conservative projected
model bounds and minimum-depth predicate.

## Profile and parity

The 2-by-2 profile at `out/dos-timedemo-20261105-215504` and the 4-by-4 control
at `out/dos-timedemo-20261105-211219` each recorded 4,503 queries. The finer
grid culled 1,684 models versus 1,627, but raised tile checks from 36,940 to
118,025. Z-buffer samples fell from 567,552 to 456,948.

The fixed-step color checksum streams differed at frame 690, while all Z
checksums matched. Their captured frame 482 PCX files matched, and both runs
ended at framebuffer checksum `1047377823`. The strict instrumented i486 audit
passed with 322,324 relocated instructions, 529 startup rows, and 9,207 DOS
provider instructions; it reported zero above-i486, unknown, exempt, or
unclassified instructions.

A second 2-by-2 profile raised the depth margin from 2 to 32 and captured frame
690. It still differed from the 4-by-4 color checksum at frame 690, with an
identical Z checksum stream. It culled 1,328 models, checked 100,237 tiles, and
sampled 386,784 Z values. Its strict i486 audit also passed. The two
instrumented output folders are `out/dos-timedemo-20261105-215504` and
`out/dos-timedemo-20261105-221108`; the corresponding builds are
`out/local-alias-occlusion-2x2-profile-20261105` and
`out/local-alias-occlusion-2x2-margin32-profile-20261105`.

## Disposition

The 2-by-2 tile cache was removed because it failed exact color parity and
expanded tile checks by more than three times. Increasing the depth margin did
not repair the mismatch. No uninstrumented timing A/B was run after the parity
failure. The 4-by-4 tile cache remains the retained configuration.
