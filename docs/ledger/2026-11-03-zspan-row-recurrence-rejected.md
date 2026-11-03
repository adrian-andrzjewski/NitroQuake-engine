# Z-span vertical-term recurrence rejected

Date: 2026-11-03

Target: 320x200, i486 assembly renderer

Status: rejected; source restored to the existing `nofxch` schedule

## Hypothesis

The span-list census suggested carrying the x87 vertical term between spans
instead of rebuilding `v * d_zistepv` for every span. An instrumented run
counted 1,436,578 links: 31,452 same-row links (2.19%), 1,403,094 previous-row
links (97.67%), no next-row links, and 2,032 other-row links (0.14%).

The opt-in candidate cached the first vertical product, used `FSUBS d_zistepv`
for a descending adjacent row, kept the value for a same-row link, and rebuilt
the product for any other row transition. It attempted recurrence only when the
saved x87 precision setting was 53 or 64 bits; otherwise it fell back to the
original span setup.

## Correctness result

Matched DOSBox-X 2026.08.31 `demo1` runs used the pinned i486 profile
(`cputype=486`, `fpu=387`, fixed 33445 cycles), with frame checksums enabled.
Both produced 969 timedemo frames and final framebuffer checksum
`1047377823`. The captured frame 50 PCX was byte-identical, but the per-frame
checksum streams differed at 38 entries, from frame 99 through frame 733.
The final checksum therefore concealed intermediate image changes. A pixel
count for those mismatching frames was not captured; the checksum mismatch is
already sufficient to reject pixel-exact promotion.

The runs were diagnostic `VisualParityOnly` builds, so the renderer ISA audit
was skipped. Their single-run FPS values (12.752779 control, 12.736487
candidate) include checksum capture and are not accepted as performance
evidence. No uninstrumented timing series was run after the correctness gate
failed.

## Disposition and artifacts

The candidate assembly, selector plumbing, and temporary census counters were
removed from source. The existing schedule remains selected. The reproducible
run reports and checksum streams are retained under:

- `out/dos-timedemo-20261103-031336/` — instrumented span-link census
- `out/dos-timedemo-20261103-032442/` — control checksum run
- `out/dos-timedemo-20261103-032657/` — recurrence checksum run

The two matching workload builds and two failed selector-profile attempts are
temporary; they are not part of the repository or the evidence needed to
reproduce the checksum comparison.
