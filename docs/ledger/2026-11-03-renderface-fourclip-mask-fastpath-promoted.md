# `R_RenderFace` full clip-mask chain fast path promoted (2026-11-03)

## Candidate

When all four low clip bits are set (`clipflags == 15`), `R_RenderFace_asm486`
now links the four `view_clipplanes` nodes directly. It initializes the last
node's `next` pointer to null and writes the same 3-to-0 chain built by the
existing partial-mask loop. Every other mask still uses the original path.
The branch is after the existing surface and edge capacity checks.

A profile census found 22,041 zero-mask faces among 215,720 calls, with a
637,689 total low-bit population. Even treating all nonzero masks as having
three bits gives a lower bound of 56,652 calls with all four clip bits set.
This is workload evidence from the instrumented `demo1` run; the instrumentation
was absent from both timing builds.

## Benchmark

Three matched uninstrumented 320x200 DOSBox-X 486 `demo1` runs were measured at
fixed 33,445 cycles with the pinned profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` and
`host_framerate 0.0783`:

| Build | FPS samples | Median |
|---|---|---:|
| Control | 16.484395, 16.484394, 16.484396 | 16.484395 |
| Candidate | 16.491697, 16.491694, 16.491694 | 16.491694 |

The median gain is **0.007299 FPS (+0.044278%)**. This is a small DOSBox-X
result, not a measurement on physical 486 hardware.

## Correctness and compatibility

All six runs rendered 969 frames with final framebuffer checksum `1047377823`
and identical event traces. Candidate and control per-frame checksum streams
matched exactly (970 records); a captured 320x200 PCX comparison found all
64,000 pixels and the palette identical. The candidate passed the complete
linked i486 audit: 314,615 linked instructions, 435 executable ranges, 529
startup rows, and 9,207 provider instructions, with no above-i486 instructions
or exemptions.

## Disposition

Promoted because the three-run gain repeated, the direct chain is equivalent to
the original four-bit construction, and both pixel-level parity and the full
i486 gate passed. Partial clip masks retain their existing code. No genuine
486 hardware result is available.
