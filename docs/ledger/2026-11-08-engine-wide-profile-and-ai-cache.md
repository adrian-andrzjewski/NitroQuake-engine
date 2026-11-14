# Engine-wide 486 profiling and immutable AI leaf-cache promotion

## Measured engine budgets

The reference environment is DOSBox-X 2026.08.31, dynamic core, CPU 486/FPU 387,
fixed 33,445 cycles, 32 MiB and a 320x200 display. These are emulator elapsed-time
budgets, not physical processor cycles or cache-miss measurements.

Three recorded client demos put surface drawing/Z/software-cache work at
51.10-53.78% of the profiled frame, alias models/culling at 11.53-14.64%,
world BSP/faces at 10.60-13.25%, and edge scanning/dispatch at 9.74-10.61%.
Their measured renderer-profile overhead is about 1.03-1.23%.
Demo2 screen warping is a separate 3.32%, across 210 calls averaging 9.134ms.
The geometry-dependent warp tables are rebuilt on each invocation; table setup
versus indirect pixel-copy cost remains unsplit.

The silent stationary e1m1/e2m2 local-server shares are 9.51% and 17.22%,
including physics, QuakeC, native AI, collision and message preparation.
A qualified hard-skill e1m1 approach/hold includes a visible attacking soldier,
incoming damage and final player health 68. Its uncached server share is 10.16%.
These different scenes are not an isolated experiment on combat versus idle AI.
Inclusive scopes overlap; only exclusive self costs may be added.

Active audio is 3.588% of its sound-enabled frame;
painting/buffer transfer is 2.868%. Output is 11,025 Hz stereo 16-bit, with 8-bit
inputs in this demo. Three matched off/coarse samples give
0.648% elapsed calibration difference.
Audio has a separately reproduced checksum 51442233; silent/audio FPS differences
are not assigned to pure mixer cost because sound startup shares the engine RNG.
PCM activity was counted; physical audible output and PCM-output parity were not measured.

The 2400 KiB surface cache is about 1.45% faster than 600 KiB in the same binary's
capacity experiment, but 2400 KiB was already the default. A separate census finds
no steady demo1 resource-cache eviction and no surface-cache thrash frames.
Allocator totals include loading; helper copy/fill counters are not total memory
traffic. Legacy dynamic-light census counters miss the active ASM cache-check
path, so their zero readings are not zero-cost evidence.

## Promoted immutable leaf-query cache

The production change is confined to [pr_cmds.c](../../src/server/pr_cmds.c)
(`PF_CheckClientLeaf` and its `PF_checkclient` caller),
[progs.h](../../src/progs.h) (reset declaration), and
[host.c](../../src/core/host.c) (`Host_ClearMemory` reset hook).
The 64-entry direct-mapped table occupies 1536 bytes on DJGPP. It stores only the
immutable world-BSP point-to-leaf result, keyed by actor, exact stored view bits
and x87 control word. It preserves original target/PVS decisions and AI cadence.
Nonfinite inputs use the original query. World-pointer changes and memory resets
invalidate the cache before model/hunk memory is released. Non-DJGPP builds retain
the original query path.

Three retained off-mode samples per executable per workload show:

| Workload | Control FPS | Cached FPS | FPS gain |
|---|---:|---:|---:|
| e1m1 stationary, skill1,240frames | 19.144409 | 19.199559 | 0.288% |
| e2m2 stationary, skill1,240frames | 16.653090 | 16.735240 | 0.493% |
| e1m1 incoming fire, skill2,120frames | 14.615673 | 14.667338 | 0.353% |

The frame-weighted pooled gain across all 18 off-mode samples is
**0.387%**. Timing has no active profiling scopes,
per-frame hashes, capture or hit-reference verification. The diagnostic cached
build still increments BENCH hit/miss counters; this is not a normal-release
local-server FPS measurement or a physical-hardware speed claim.
In the encounter, checkclient retains 2436 calls but falls from
0.683 to 0.439 ms/frame in calibrated server profiles.
It reuses 1333 self-view queries. Every ordinary sample retains the reference final
canonical entity/sv.time hash, health and top QuakeC statement counts.

The simple axial-prefix ground-support proposal was screened out before engine
implementation: synthetic geometry fixtures save zero nodes in e2m2 because its
root is nonaxial, and fewer than 4% in e1m1 before added instruction overhead.

## Acceptance evidence

- Full diagnostic canonical entity/sv.time, color/Z streams and selected PCX
  checks agree on stationary maps and the incoming-fire encounter. The checker
  canonicalizes string contents, not relocated string offsets; it does not dump
  all engine/QuakeC globals or RNG state.
- All measured verification hits are recomputed with the original leaf query.
  Normal map commands in both directions also preserve state/color/Z/PCX.
- The exact-source standalone cache/actual assembly-query fixture passes 2248
  comparisons, 12 valid x87 control words, three incoming stack depths, 54 mode-sensitive
  results, 576 nonfinite checks, 512 capacity-stress checks and four world/reset checks.
  It preserves CW and x87 stack depth; whole-program compiler context and x87
  status-flag equivalence are separate limitations.
- The actual primary **NitroQuake v0.999+26** normal build passes 163609 relocated
  instructions, 529 startup rows and 9207 provider instructions, with zero exemptions.
  Selected normal-build images on e1m1/e2m2 are byte-identical to the accepted
  v0.999+7 release under the same fixed-step screenshot schedule.
- Entire primary pr_cmds and assembly leaf-query native text equal the validated
  isolated normal candidate. 166 of 168 project text sections are byte-identical;
  the other two differ only in reviewed product-version and compile-time literal
  strings. Literal normalization is an identity comparison, not an ISA exemption.
- The reviewed three-file patch preserves all pre-existing dirty primary bytes
  outside its insertions/replacement. Promotion did not stage, commit or push changes.

## Normal executable comparison

The final fresh, balanced nine-run 969-frame demo1 comparison uses the actual
normal release, identical arguments, pinned emulator/DPMI/data, and an empty
command buffer during timing. The owned emulator is stopped after its console
result is observed. All completed samples are retained.

| Executable | Median FPS | Median seconds |
|---|---:|---:|
| Quake.exe | 13.4 | 72.4 |
| 486quake.exe | 14.2 | 68.2 |
| NitroQuake v0.999+26 | 16.9 | 57.4 |

From rounded median elapsed times this is approximately
26.1% above Quake.exe and
18.8% above 486quake.exe.
This compares delivered defaults: stock caches are 600 KiB, Nitro 2400 KiB, and video
backends differ. Stock pixel/Z parity is unmeasured. The AI-cache gain is not added
to this result: recorded client demos execute no local server.
All three Nitro console logs show the automatically assigned current build version.

## Evidence, reproduction and limits

- [Complete report and ranked charts](../../out/engine-performance-analysis-20261108/report.html)
- [Current normal executable and build provenance](../../out/accepted-checkclient-leaf-cache/build-evidence.json)
- [Primary source/native/runtime acceptance](../../out/worktree-checkclient-leaf-cache-20261108/out/primary-cache-acceptance.json)
- [Encounter timings and attribution](../../out/worktree-checkclient-leaf-cache-20261108/out/cache-encounter-timing-evidence.json)
- [Final executable comparison and precision limits](../../out/exe-comparison-20261108-final/verified-summary.json)
- [Final comparison chart](../../out/exe-comparison-20261108-final/comparison-chart.png)
- [Hardware facts, source-bound RAM-copy route and inference labels](../../out/worktree-engine-probe-coverage-20261108/out/hardware-interpretation.html)

The retained runners/protocol JSON record exact inputs and commands and reject
overwriting existing evidence. Fresh reproduction needs a fresh output/worktree
while retaining workload pins; do not delete the archived measurements to rerun.
Build numbering remains automatic in the existing builder and shared Git-common
state; source archives use an output-local counter. Future builds reserve their
own identity rather than editing the UI label.

The normal 320x200 VESA path draws into RAM and copies dirty rectangles to mapped
video memory. Logical color is 64000 bytes (64320 reserved with one spare row), Z is
128000 bytes, and the video payload with surface cache and 16-byte pad is 2649936 bytes.
Exact dirty-copy traffic, physical cacheability, L1/L2 misses, VGA/VESA bus cost and
physical 486 FPS remain unmeasured. Stride/set arithmetic is inference, not a miss
count or proof that padding helps. The 1536-byte AI table also has an unmeasured
physical L1 tradeoff.

Scope is three recorded client scenes, two stationary local worlds, active PCM
and one bounded hitscan encounter. Human traces, missile-heavy physics and other
hardware configurations are not covered. Future effort should measure warp table
setup separately, repair active-ASM dlight census coverage, and target actual work
reduction in the dominant surface/geometry groups while retaining exact output.
