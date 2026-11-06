# BSP-node face-order index rejected (2026-11-06)

## Candidate

The renderer's BSP walk tests each node surface's plane-facing flag before
checking its visibility mark. This experiment precomputed a front-facing count
and stable 16-bit surface-index lists for each node, allowing the C and i486
walkers to visit only the selected facing subset. The lists were built during
model loading. A temporary coverage map detected overlapping node ranges and
kept the original scan as a fallback. The BSP node layout remained 40 bytes;
the added index pointer increased model_t from 392 to 396 bytes.

## Exact-output and i486 gates

The clean control at source revision f3804dc and the candidate used the pinned
DOSBox-X 2026.08.31 i486 profile, 320x200 demo1, host_framerate 0.0783, and
con_notifytime -1. Both produced byte-identical per-frame color and Z
checksum streams, each with 970 per-frame rows plus a completion footer, and
identical captured frame 482 PCX.
The color stream SHA-256 is
3b027a59e35e9290d554866ae078b2913a01a75f2e3a19665ffed8e9a5bc0e7b; the Z
stream SHA-256 is
1b41d2ab5b0fc99fcca5158c51e4d7b9028cbf4c3ec8dfdf32c6ab96c2db85e8; and the
PCX SHA-256 is
31595bc38a502f9df6598fd8c744dad2556011af36ff026e3e43a86c1133f213. The
final framebuffer checksum was 1047377823.

The candidate passed the complete strict i486 gate: 315,602 relocated
instructions, 529 startup code rows, and 9,207 provider instructions, with
zero above-i486, unknown, exempt, or unclassified instructions.

## Matched uninstrumented timing

Three runs per variant used the same pinned DOSBox-X profile and commands,
without per-frame checksum or FPS instrumentation. Every run rendered 969
frames and produced the expected final framebuffer checksum.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| Clean control | out/worktree-bsp-face-ranges-control-20261106/out/dos-timedemo-20261106-080952 | 16.893008, 16.893024, 16.893026 | 16.893019333 |
| Front/back index | out/dos-timedemo-20261106-081334 | 16.827806, 16.827804, 16.827804 | 16.827804667 |

The indexed walker was 0.386045% slower than the clean control. All three
candidate samples were below all three control samples.

## Conclusion

Reject the front/back index and retain the existing sequential BSP surface
scan. The saved facing-flag checks did not repay the added index loads and
surface-pointer reconstruction on this workload. The experimental source
changes were reverted; the local DOSBox-X reports and checksum artifacts remain
under the ignored out directory for reference.
