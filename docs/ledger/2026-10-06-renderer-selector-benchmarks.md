# Renderer selector benchmarks and BSP walk follow-up

Status: ongoing renderer port. The renderer remains a mixed C and assembly
implementation; the measurements below promote only a selectable candidate.

## Selector-set frame performance and BSP call removal (2026-10-06)

`i486-asm-surface-alias` selects the assembly surface, lightmap, alias, and
raster paths while leaving world and edge orchestration in C. An alternating
three-run `demo1` comparison on DOSBox-X configured as a 486, without FPS
instrumentation or frame-checksum instrumentation, measured:

| Profile | Run times (s) | Median (s) | Final checksum |
|---|---:|---:|---:|
| C reference | 59.852046, 59.851910, 59.852036 | 59.852036 | `1047377823` each |
| Surface/alias assembly | 59.592073, 59.592174, 59.592167 | 59.592167 | `1047377823` each |

The assembly subset is 0.259869 s, or 0.4342%, faster by median. This clears
the current end-to-end timing gate for this workload, but it is a small gain on
one demo and does not establish that every assembly selector helps. The C
reference remains the release default while the whole renderer is incomplete.
Each result is under `out/dos-timedemo-20261006-034xxx/` with its exact selector
values, source fingerprint, emulator profile hash, frame count, and checksum in
`timedemo-result.json`.

A first single-run diagnostic matrix extended the same selector pair to low-,
medium-, and high-complexity timedemos. These runs used `-FpsStats` for per-frame
percentiles, disabled per-frame framebuffer logging, and kept the scenario's
fixed-frame command. They are useful for finding workload-specific regressions,
not promotion-quality repeat samples:

| Workload | C reference (s) | Surface/alias assembly (s) | Change | Checksum in both |
|---|---:|---:|---:|---:|
| Low: demo1, 50% viewport | 37.265106 | 37.364909 | +0.268% slower | `59667682` |
| Medium: demo2, entity workload | 60.207033 | 59.670802 | -0.891% faster | `1887495667` |
| High: demo3, world workload | 70.557031 | 70.747604 | +0.270% slower | `2316550348` |

The `timedemo-result.json` files contain each run's average, median, p95, and
p99 per-frame FPS statistics. Repeat the low/high regressions and medium gain
before making a selector-wide promotion; keep the release default on C for now.

To remove one hot call per visible internal BSP node, the selectable assembly
walk now expands the same x87 plane-dot body as
`R_RecursiveWorldNodePlaneDot_asm486`; that selector helper remains available
for isolated comparison. Axis-plane fast cases and arbitrary-plane arithmetic
keep their prior operation order. Compile-time checks in `src/renderer/r_bsp.c` pin the
plane `dist` and `type` offsets and structure size used by the assembly. The
updated `i486-asm-world-group` build passed its object ISA gate with zero
enforced instructions above i486. The source-level scan also passed for all 82
C and 21 assembly files with zero above-i486 or unclassified instructions.

The six-scene golden-frame suite passed for the updated world-group profile:

| Scene | Changed pixels / 64,000 | Maximum channel error | Result |
|---|---:|---:|---|
| `demo1-vesa-full` | 12 | 12 | pass |
| `demo1-vga-full` | 12 | 12 | pass |
| `demo1-fullbright` | 0 | 0 | pass |
| `demo1-viewsize-50` | 2 | 8 | pass |
| `demo2-entity-workload` | 0 | 0 | pass |
| `demo3-world-workload` | 0 | 0 | pass |

All six final frame checksums matched their pinned values. Each scene was
captured once, so this is not a repeated-run stability test. A paired C-reference
and world-group checksum-stream comparison found 141 differing records out of
970, from frame 0 through frame 956. Earlier per-frame checksums for the
surface/alias subset differed on 74 of 970 samples; its selected frame 956
comparison differed by one pixel out of 64,000. The updated world-group frame
169 capture differs from its golden by 12 pixels in the full-view scenes.

Checksum collection itself changes the final image in the reduced-viewport
timedemo: with the same C-reference binary and `host_framerate 0.0783` plus
`viewsize 50`, the run without per-frame checksums ended at `59667682`, while
the run with per-frame checksums ended at `885630476`. The captured frame 169
from the instrumented C and world-group runs is byte-identical, and the C
capture differs from its golden by two pixels. Treat checksum-stream diffs as
frame locators, not pixel-error measurements; compare PCX captures from the same
instrumentation mode. Performance promotion runs remain uninstrumented.

The reduced-viewport, demo2, and demo3 world-group scenes were then repeated
twice each. The harness reported `repeatParity: PASS` after six warmup frames in
all three cases, with 953, 970, and 1,067 unique post-warmup checksums in each
stream. Both captures were stable in every case; the two demo2 and two demo3
captures matched their references exactly, and the two reduced-viewport
captures each differed by only two pixels.

Inlining did not close the world-group cost. Three FPS-instrumented world-group
runs measured 60.308266, 60.308252, and 60.308181 s (median 60.308252 s), each
with 969 frames and checksum `1047377823`. The prior one-run world-group sample
was 60.326260 s, too weak a comparison to attribute a gain to the inlining.
Against the earlier same-instrumentation surface/alias median of 59.603306 s,
the full world group is about 1.18% slower. Keep the world and edge selectors
opt-in while profiling their C/assembly costs individually.

The edge scan was isolated on top of the uninstrumented surface/alias profile.
Three assembly-scan runs measured 59.625577, 59.625542, and 59.625511 s, each
with checksum `1047377823`. This is 0.033375 s (0.0560%) slower than the
surface/alias median of 59.592167 s, just beyond the 0.05% gate. Keep
`ScanEdgesImplementation=c` in the selected profile and price the other edge
selectors separately. One-run edge probes on the same selector base measured
59.593020 s for `EdgeDrawing=asm`, 59.714256 s for
`EdgeListMaintenance=asm`, and 59.592097 s for `BackwardSpans=asm`; all retained
the expected checksum. Edge drawing and backward spans were effectively
neutral in these single samples, while active-edge maintenance was 0.205%
slower. These edge paths remain C in the selected profile.

`RenderFaceImplementation=asm` was measured separately over three full
`demo1` runs. Its times were 59.731708, 59.731736, and 59.731729 s (median
59.731729 s), each with checksum `1047377823`. That is 0.234% slower than the
surface/alias median, so keep render-face setup on C despite its roughly 8.4%
qprof stage share.

The cached-edge emitter was then measured on the surface/alias profile with
three alternating C/assembly pairs and a trailing C drift check. The C samples
were 59.592138, 59.592110, and 59.592107 s (paired median 59.592110 s), with a
59.592089 s trailing control. The assembly samples were 59.601142, 59.601270,
and 59.601157 s (median 59.601157 s). All seven runs rendered 969 frames and
matched checksum `1047377823`. Assembly was 0.009047 s (0.0152%) slower than
the paired C median, so retain `EmitCachedEdgeImplementation=c`.

Single-run probes of `BspWalkImplementation=asm` and
`RenderWorldImplementation=asm` measured 60.086696 s and 59.592469 s,
respectively, each with checksum `1047377823`. The BSP walk alone was 0.83%
slower than the surface/alias baseline; render-world orchestration was neutral.
Both stay C in the selected profile.

The BSP walk was then changed from recursive calls to explicit continuation
records on the caller's stack. Each internal node saves its node, clip mask,
plane dot, side, and traversal stage; the walk visits the front subtree, draws
the parent's marked surfaces, then visits the back subtree. This preserves the
reference depth-first order and removes recursion from the assembly traversal.
The record is 24 bytes normally and 28 bytes when the cached-framecount
selector is enabled. Calls to clipping and surface routines remain ordinary
platform-call boundaries.

An interim tail-walk version removed only the second recursive call. Three
alternating `demo1` comparisons measured C at 59.592174, 59.592065, and
59.592169 s (median 59.592169 s), and assembly at 60.014548, 60.014496, and
60.014542 s (median 60.014542 s). The trailing C control was 59.592119 s; all
seven runs rendered 969 frames with checksum `1047377823`. This timing records
the interim version only; the explicit-stack implementation below supersedes
it, and timing is diagnostic rather than its compatibility acceptance gate.

The explicit-stack `i486-asm-world-group` profile passed all six captured
scenes. Its final checksums matched the scene pins; the VESA and VGA full-view
captures each differed by 12 pixels, the reduced-viewport capture by two, and
fullbright, demo2, and demo3 captures matched exactly. A two-run demo3 check
rendered 1,090 timedemo frames per run, matched `2316550348` on both runs, and
reported `repeatParity: PASS` after six warmup frames. Each stream had 1,067
unique post-warmup checksums, zero repeated zero-checksum frames, and a longest
identical run of ten frames. Both captured images matched the reference exactly.
The selected walker build's ISA audit decoded 204,922 instructions with zero
enforced above-i486 instructions and zero unclassified instructions; the one
exemption remains the CRC table bytes in `crc.obj`.

The complete `i486-asm-selectable` profile then exercised every renderer
implementation selector in assembly, including BSP clip/plane tests, submodels,
edge insertion/removal/scanning, backward spans, and polygon rendering. Its
object audit decoded 205,538 instructions with zero enforced above-i486
instructions and zero unclassified instructions. All six captured scenes
passed their pinned frame and checksum gates; fullbright, demo2, and demo3 were
pixel-exact, and the VESA, VGA, and reduced-viewport captures remained at 12,
12, and two differing pixels. Two repeated all-assembly demo3 runs each
rendered 1,090 frames with checksum `2316550348`; their streams were stable
after the six-frame warmup and their captures matched the reference exactly.

The current qprof stage ordering still points next to texture spans,
surface-cache work, render-face setup, edge scanning, and Z spans. Instrumented
all-assembly versus C snapshots put those stages near 23%, 9%, 8.4%, 8.2%, and
7.5% of the measured frame, respectively. Those percentages are diagnostic;
their timer instrumentation is not suitable for the promotion timing above.
The fresh surface/alias qprof measured texture spans at 23.58%, render-face C
work at 9.98%, surface-cache at 9.47%, edge scanning at 8.19%, and Z spans at
7.94%. It had 2,011,618 timer reads, no profile stack errors, and an estimated
0.74% instrumentation overhead against the C reference. Use the stage shares
to choose experiments, not as promotion timings.
The renderer-port ledger and `BUILD-DOS.md` describe the selector build,
per-stage profiler, benchmark runner, DOSBox-X profile, and ISA audit.

Remaining gates include pixel-level comparisons for frames flagged by the
checksum-stream diff, repeated validation runs, live-display review, broader
low/medium/high-complexity timedemos, and migrating the remaining active C
renderer paths. Full-pipeline assembly and the completion criteria remain
open.
