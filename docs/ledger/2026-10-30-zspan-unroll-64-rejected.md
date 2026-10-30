# Z-span 64-pixel nonnegative group (2026-10-30)

Status: reverted after exact per-frame parity failed and the timedemo mean was lower.

## Candidate

The i486 nonnegative path in `src/d_draw.s` was changed from a 32-pixel
back-edge group to a 64-pixel group. The candidate executed 32
`ZSPAN_ADD_PAIR_NONNEGATIVE` macros per loop iteration and added a 32-pixel
remainder before the existing 16/8/4/2-pixel tails. This aimed to halve the
loop-branch frequency for long spans. The existing 32-pixel loop has been
restored; the promoted row-index load interleave remains.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the aggressive i486 selector profile.

| Variant | Source-tree fingerprint | FPS samples | Mean FPS |
|---|---|---|---:|
| Retained control | `FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D` | 16.328477 / 16.328473 / 16.328474 | 16.328474667 |
| 64-pixel Z group | `47683A0B3E3F7C1BACA15F92B638294413100EDC7CC4B76B85435C3549D1BD1C` | 16.326746 / 16.326769 / 16.326768 | 16.326761000 |

The candidate was **0.001713667 FPS slower (-0.01049496%)**. Its spread was
0.000023 FPS versus 0.000004 FPS for control. All runs rendered 969 frames and
ended at checksum `1047377823`; the recorded event traces matched. These timing
numbers are diagnostic only because exact output parity failed.

The 970-entry per-frame checksum stream differed at **149 frames**, from frame
1 through frame 848. The captured 320x200 frame 169 differed at **18,825 of
64,000 pixels (29.4141%)**, with mean absolute channel error 6.3123 and maximum
error 255. The final checksum therefore concealed substantial intermediate
rendering differences. The candidate fails the renderer correctness gate and
was reverted.

Control timedemo: `out/dos-timedemo-20261030-162411/timedemo-result.json`.
Candidate timing: `out/dos-timedemo-20261030-191218/timedemo-result.json`.
Per-frame and image comparisons: `out/dos-timedemo-20261030-191608/runs/run-01/`.

## Genuine-486 instruction gate

The fresh candidate build passed the complete i486 gate: 314,533 relocated
instructions, 529 startup instructions, and 9,207 CWSDPMI provider
instructions; zero above-i486, unknown, or exempt instructions. The ISA result
does not override the failed frame-parity result.

Build root: `out/local-local-zspan-unroll64-fixed-strict-20261030`.
