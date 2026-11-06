# World clip-vertex side-sign cache rejected (2026-11-06)

## Candidate and profile census

A saved candidate used four 64-slot direct-mapped banks, one per view clip
plane, to reuse world-vertex distance signs. A PROFILE486 shadow model
replayed the lookups without changing renderer output. It found 357,459 calls
where both endpoint tags were resident with the same sign, 24.7% of modeled
uses. The model observed no sign conflicts, but the small table still replaced
783,987 entries. These are workload counts, not a speed estimate.

## Exact output and i486 compatibility

The candidate's fixed-step replay matched the PROFILE486 control and a clean
visual-only control across all 971 framebuffer-checksum rows and all 971
Z-checksum rows. The captured frame-482 PCX also matched, with SHA-256
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`.
The candidate executable passed the strict linked i486 audit: 323,455 linked
instructions, 529 startup CODE rows, and 9,207 DPMI-provider instructions,
with no above-i486 or unclassified instructions.

## Matched uninstrumented timing

The alternating runs used the pinned DOSBox-X 2026.08.31 486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
the same fixed host frame step, and 969 timedemo frames. The timed runs did not
enable checksum instrumentation.

| Variant | Run 1 | Run 2 | Run 3 | Mean FPS |
| --- | ---: | ---: | ---: | ---: |
| Control | 16.897615 | 16.897610 | 16.897617 | 16.897614 |
| Side-sign cache | 16.263165 | 16.263174 | 16.263176 | 16.263172 |

The candidate was **3.7546% slower** by mean FPS (59.582474 seconds versus
57.345374 seconds per run on average). Reject the cache: its pointer-tag
lookups cost more than the skipped endpoint sign calculations for this
workload. The candidate remains out of the renderer.

## Artifacts

- Profile census and parity replay: `out/dos-timedemo-20261106-212602`.
- Clean visual-only parity control: `out/dos-timedemo-20261106-213925`.
- Alternating release timing runs:
  `out/clip-side-sign-fixedstep-candidate-20261106/timing`.
