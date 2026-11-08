# Alias triangle cache completion rejected (2026-11-07)

The [vertex-prefilter follow-up](2026-11-07-alias-triangle-vertex-prefilter-rejected.md)
also passed correctness but remained slower than the accepted control. This
record retains the preceding cache-completion measurements.

## Implementation and scope

In the isolated `out/worktree-triangle-cache-query-20261107/`, extend the
read-only query described in [the cache miss diagnosis](2026-11-07-alias-triangle-cache-miss-diagnosis.md)
to complete missing and partial 4x4 tiles. The integer i486 assembly helper
retains old partial anchors as conservative lower bounds, scans the remaining
pixels, and publishes minimum before epoch. A tile crossing the viewport gets
zero without an out-of-viewport read. Negative Z samples give a zero bound;
depth ties retain the reference draw path. The Z-buffer is read only.

Validate stable entity/frame/viewport/cache context once per draw batch, and
query front-facing triangles in both recursive and non-subdivided bulk paths.
Clipped single-triangle calls retain the reference path. The accepted
whole-model nearest-depth bound is unchanged. The shared cache remains owned
by `r_alias.c`; its existing model-query computation is unchanged.

## Native, replay and strict i486 evidence

The independent C scan oracle and assembly suite passed **2,048 cases** across
four x87 rounding modes in both the profile and uninstrumented builds. Each
suite reported 320 culls, 1,472 cases with cache mutations and zero mismatches.
Checks cover the validating entry, prepared-entry ABI, complete guarded cache
contents, context state, and every byte of the guarded Z-buffer. Fixtures cover
missing/partial entries, first/middle/last tile failures, all 16 fresh sample
positions and all 15 remaining partial-tile samples, viewport edges, invalid
contexts, negative Z, depth ties and epoch transitions.

Profile build `NitroQuake v0.999+13` passed the complete source-bound i486 gate:
325,428 relocated instructions, 529 startup rows, 9,207 provider instructions,
403 project/runtime object proofs and 435 source contributions. Uninstrumented
benchmark build `NitroQuake v0.999+14` passed the same gate with 317,347 relocated
instructions. Above-i486, unknown and exempt instruction counts were zero.

Both fresh profile replays matched both accepted control replays in every one
of their 970 color records, 970 depth records and complete frame-154 PCX. No
records were excluded. Both completed 969 timed frames at final framebuffer
checksum `1047377823`, with identical profile counts:

| Counter | Per replay |
| --- | ---: |
| Triangle queries | 95,167 |
| Triangle culls | 14,498 |
| Tile visits | 148,614 |
| Missing tiles encountered | 25,936 |
| Partial-low query failures | 56,891 |
| Partial-high tile completions attempted | 185 |
| Other depth query failures | 23,778 |
| Triangle-query Z reads | 155,761 |
| Completed cache entries published | 8,655 |

The failure categories plus culls account for all queries. The model owner's
Z reads fell from 529,509 in the prior read-only profile to 525,020; the new
triangle kernel adds 155,761 reads. These profiles use the fixed presentation
clock and establish output/counter behavior only, not speed.

## Matched uninstrumented timing

After both builds/audits and all profile replays finished, the uninstrumented
native suite passed, then three declared alternating control/candidate pairs
ran with the ordinary clock. All six formal samples are retained. Frame/Z
streams, image capture, profiling, FPS statistics and extra Quake arguments
were disabled. The protocol was declared before the first formal sample.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Accepted control | 16.823949, 16.823943, 16.823944 | 16.823945333 |
| Cache completion | 16.750219, 16.750223, 16.750209 | 16.750217000 |

The candidate mean is **0.4382345037% lower**. More culls did not compensate
for the query/scan work. No normal-game build or confirmation was pursued
after this negative result.

All runs use DOSBox-X 2026.08.31, 486/387, fixed 33,445 cycles, 32 MiB,
320x200, demo1 and CWSDPMI. Profile SHA-256 is
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every formal run completed 969 timed frames at checksum `1047377823`.
This does not measure physical-486 performance.

## Disposition and retained artifacts

Rejected; the primary renderer was never modified by this experiment. Keep
the successful native and replay machinery for a successor that avoids
expensive queries when a cheap Z sample already warrants falling back to
drawing. A tighter recursive depth bound is another lead; it must not be
assumed valid for affine gradients.

Within the isolated worktree, `out/cache-fill-source/` and
`out/cache-fill-sources.json` preserve the exact candidate, and
`out/cache-fill.patch` records its difference from the accepted primary inputs.
The profile and uninstrumented builds are
`out/local-triangle-cache-fill-profile/` and
`out/local-triangle-cache-fill-bench/`.

Profile native results are in `out/dos-bench-20261107-200622/`, uninstrumented
native results in `out/dos-bench-20261107-202334/`, and both correctness
replays in `out/dos-timedemo-20261107-200839/`. Formal timing report paths,
samples and means are in `out/cache-fill-timing-evidence.json`.
`out/cache-fill-profile-evidence.json` records every replay hash and counter.
Run `rtk proxy python out/verify-fill-profile.py` and
`rtk proxy python out/verify-fill-timing.py` from that worktree to verify the
archived candidate, audits, native results, replay comparisons and all timing
samples. Later live experimental edits do not replace these archived sources.
