# World clip-vertex plane-distance cache capacity census (2026-11-06)

Status: diagnostic only. This adds PROFILE486 counters to estimate direct-mapped
cache hits for repeated world-vertex/clip-plane distance evaluations. It does
not add a runtime cache or establish a renderer speedup.

## Census

The pinned DOSBox-X 2026.08.31 profile (`dosbox-x-486-high.conf`, SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`) counted
873,833 world-vertex endpoint evaluations across the four view clip planes.
Of these, 336,108 were unique vertex/plane pairs, leaving 537,725 repeated
uses. The existing one-entry-per-plane LRU hit 262,608 times (30.06%).

The added direct-mapped model resets tags per frame and measures independent
capacities per plane:

| Slots per plane | Hits | Share of all uses | Share of repeated uses |
|---:|---:|---:|---:|
| 8 | 415,526 | 47.55% | 77.27% |
| 16 | 468,522 | 53.62% | 87.13% |
| 32 | 500,199 | 57.24% | 93.02% |
| 64 | 517,139 | 59.18% | 96.17% |
| 128 | 528,668 | 60.50% | 98.32% |
| 256 | 533,864 | 61.09% | 99.28% |

Assuming a four-byte vertex tag and four-byte binary32 distance, 64 slots per
plane would require 2 KiB and 256 slots per plane 8 KiB. The counters model
only hit opportunities; they do not measure lookup cost, cache placement, or
DOSBox and physical-486 timing.

## Output checks

The profile executable rebuilt and completed all 969 `demo1` frames in
`out/dos-timedemo-20261106-151846`. Its aggregate framebuffer checksum was
`1047377823`, and its per-frame Z-checksum file matched the earlier profile
`out/dos-timedemo-20261106-134647` exactly. The color checksum file differed
at six frame records, and the captured frame 482 has no matching control
capture. The run therefore does not establish exact framebuffer parity; its
aggregate checksum is not a substitute for per-frame comparison. The strict
i486 audit was skipped, and instrumented FPS is not a performance result.

## Follow-up

The 64-slot model is a candidate for a release-path prototype because it
captures most observed repeats at a modest estimated memory cost. Any runtime
version still needs exact release color, Z, and captured-image parity, a strict
i486 audit, and matched uninstrumented timing before promotion.
