# BSP frustum clip-plane order census rejected (2026-11-03)

## Workload and question

`R_RecursiveWorldNodeClip_asm486` tests active frustum planes in order `0123`
and can stop on the first rejecting plane. Reordering those tests could help
if a different plane order rejected more BSP nodes sooner, reducing the number
of x87 plane evaluations.

## Census method

A `PROFILE486`-only hook at both assembly clipper return paths independently
classified each active plane for the node and incoming clip mask. It compared
the resulting clip mask with the assembly result, then counted how many active
tests each of the 24 plane permutations would perform before its first reject.
The first attempt put the hook in the C traversal wrapper, which the selected
assembly BSP walk bypasses; its zero counters were discarded. The corrected
hook observes the shared assembly clipper directly.

The corrected census used the pinned DOSBox-X 2026.08.31 `cputype=486` profile
at 320x200 with `demo1`. It completed 969 frames with framebuffer checksum
`1047377823`; the strict i486 audit passed. The final clip-mask model had zero
mismatches. The run and profile are retained at
`out/dos-timedemo-20261103-024544/`.

## Results

| Plane order | Modeled active plane tests | Difference from current |
|---|---:|---:|
| `0123` (current) | 705,031 | baseline |
| `1023` | 705,111 | +80 (+0.011%) |
| `0132` | 705,128 | +97 (+0.014%) |
| `1032` | 705,208 | +177 (+0.025%) |

The other 20 permutations required still more modeled tests. These are counts
from the census model, not timings of reordered assembly. The instrumented run's
10.354592 FPS is diagnostic only and is not comparable to uninstrumented
timedemos.

## Decision

Keep the existing `0123` order. It was the lowest-test order for this pinned
workload, and even the next-best permutation adds tests. No renderer change or
performance gain is claimed. The `PROFILE486` instrumentation was removed after
the census.

The corrected run was invoked with:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -Instrumentation -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 1 -NoBootstrap -BspClipImplementation asm -BspWalkImplementation asm -RenderWorldImplementation asm -LocalOutputDirectoryName bsp-clip-order-census-rewired-20261103
```
