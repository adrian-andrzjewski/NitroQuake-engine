# Span16 signed row-scale table unqualified and removed (2026-11-02)

## Candidate

The opt-in `TextureSpanAddressing=rowtable8` path cached exact products of the
surface-cache width and signed integer T steps from -8 through 8. Values
outside that range retained `IMUL`. The candidate changed `src/d_draw16.s` and
the build and timedemo selector scripts. The default selector remained
`control` throughout.

## Correctness and performance evidence

The two candidate checksum runs, `out/dos-timedemo-20261102-222239` and
`out/dos-timedemo-20261102-222456`, produced identical 970-record streams with
SHA-256
`23FF212F34AF0ACC87CC4AEFD7A980AF05EB9151062897B2BC96F0D9088313B8`. The
control streams from `out/dos-timedemo-20261102-202624` and
`out/dos-timedemo-20261102-203056` matched each other with SHA-256
`6A5C1EC913D3436B051A5B427FC5945901288D042DE8560B7B0758D7B09085C4`. The
candidate differed from control at indexed records 70, 270, 311, and 412,
although both ended with framebuffer checksum `1047377823`.

Only record 70 was captured for pixel inspection. Its 1,181 changed pixels
were confined to a centered pickup message near the top of the screen; the 3D
scene and lower HUD matched. This points to message-expiry timing for that
record, but does not explain the other three differences or establish full
pixel parity.

These were instrumented visual-parity runs, not valid performance runs. The
candidate build skipped the complete i486 ISA audit. No uninstrumented timing
result, full pixel comparison, or hardware result was obtained.

## Disposition

The `rowtable8` candidate is rejected and removed from the active source,
selector profiles, and local Git stash. Exact parity and strict i486 checks
passed after the register fix, but the candidate was slower in all three
320x200 DOSBox-X runs. `control` remains the only active
`TextureSpanAddressing` option.

## 2026-11-03 register fix and paired validation

The first candidate build passed the linked i486 instruction audit but had
visible rendering corruption. At frame 169, **5,784 of 64,000 pixel indices
differed** (first mismatch index 6, last 48332), and all **964 of 964**
post-warmup frame checksums differed. The original comparison and diff are
`out/rowtable8-parity-current-20261103/render-parity-result.json` and
`out/rowtable8-parity-current-20261103/framebuffer-diffs/demo1-vga-full-run-01.png`.

The defect was corrected by restoring the fractional T step to EAX after the
table lookup. The repaired source passed the complete source-bound i486 audit:
314,447 linked instructions, zero above-i486, unknown, or exempt instructions.
Three fresh source-matched `demo1-vga-full` runs then passed exact parity. All
**964 of 964** compared post-warmup checksums matched in each run, and each
320x200 frame 169 capture had **0 of 64,000** pixel-index differences and an
exact palette match. Both profile builds passed the strict i486 gate. The full
report is `out/rowtable8-source-matched-repeat-20261103/render-parity-result.json`.

The timedemo used non-`PROFILE486` qbench builds (`profileBuild=false` and
`instrumentation=false`) with runtime per-frame checksum capture enabled for
both profiles. The DOSBox-X profile was pinned to
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
three-run control median was **12.813826 FPS** (median 75.621447 seconds); the
candidate median was **12.758711 FPS** (median 75.948112 seconds), a **0.4301%
regression**. Every candidate run took longer than every control run. No other
DOSBox-X process was running during the screen. These are DOSBox-X results, not
physical 486 measurements. The measurements include the same per-frame
checksum overhead on both sides and should be treated as a rejection screen,
not a checksum-free timing estimate. The per-profile reports and timedemo results are in
`out/rowtable8-source-matched-repeat-20261103/reference/` and
`out/rowtable8-source-matched-repeat-20261103/candidate/`.

The earlier 407-frame standalone comparison used different source-tree
fingerprints and was inconclusive. The three later source-matched runs resolve
that discrepancy and qualify the corrected candidate's rendering behavior;
the measured slowdown rejects its performance value.
