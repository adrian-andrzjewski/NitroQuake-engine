# D_DrawZSpans per-row depth-term cache rejected (2026-11-05)

Status: rejected. The candidate preserved the tested framebuffer and Z output
and passed the complete strict i486 audit, but its three-run uninstrumented mean
was 0.363% slower than the matched control.

## Candidate

`D_DrawZSpans` forms the initial inverse-depth value for each span from the
scanline term `v * d_zistepv`, the horizontal term `u * d_zistepu`, and
`d_ziorigin`. The prototype cached the rounded single-precision scanline term
for 200 screen rows and tagged each entry with the exact bits of
`d_zistepv`. Repeated spans on a row could then load the term instead of
converting `v` to integer for x87 and multiplying it. Rows outside the 320x200
cache used the original calculation. The arrays occupied about 1.6 KiB.

An instrumented profile counted 411,727 cache hits and 1,000,561 misses across
1,413,428 Z spans, a 29.1% hit rate. Each lookup still required a row bound,
tag load and comparison, and value load on a hit.

## Results

The three-run release A/B used the pinned DOSBox-X 2026.08.31 profile
(`dosbox-x-486-high.conf`, SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), the
969-frame `demo1` workload, and the same i486 build settings. Every run ended at
framebuffer checksum `1047377823`.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| Control | `out/dos-timedemo-20261104-235041` | 16.388048, 16.388076, 16.388070 | 16.388064667 |
| Row-term cache | `out/dos-timedemo-20261105-000636` | 16.328564, 16.328566, 16.328560 | 16.328563333 |

The candidate lost 0.059501334 FPS (-0.363%). A separate instrumented
fixed-step parity run, `out/dos-timedemo-20261104-233327`, matched the control
`out/dos-timedemo-20261104-224740` across all 970 recorded framebuffer
checksum rows and all 970 Z-checksum rows. The complete strict i486 audit
passed: 314,642 relocated executable instructions, 529 DOS startup code rows,
and 9,207 provider instructions, with zero instructions above i486 and zero
exemptions.

## Disposition and evidence

The cache and its profiling counters were removed from the source tree. The
instrumented parity/profile outputs, release control and candidate timedemo
results, and their build/audit evidence remain under the ignored `out`
directory. The measured slowdown rejects this lookup structure for the tested
workload.
