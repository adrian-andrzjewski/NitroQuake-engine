# Promote STOSB in the cached fourteen-pixel turbulent loop (2026-10-27)

The current i486 assembly profile now selects `fourteen-stosb`. It combines the
cached texture base in EBX from the fourteen-pixel loop with the existing
`STOSB` pixel store in `src/renderer/d_scana.s`. The control uses the same fourteen-pixel
loop with the explicit destination increment and byte store.

The candidate was compared with the control in seven alternating uninstrumented
DOSBox-X 2026.08.31 runs on the pinned i486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). All runs
used `demo1`, rendered 969 frames, and produced framebuffer checksum
`1047377823`.

| Variant | FPS samples | Mean |
|---|---|---:|
| Control (`fourteen`) | 16.194907, 16.194906, 16.194914, 16.194906 | 16.194908 |
| Candidate (`fourteen-stosb`) | 16.210791, 16.210797, 16.210798 | 16.210795 |

The pooled-mean delta is **+0.015887 FPS (+0.0981%)**. All seven runs passed
frame-count and framebuffer-checksum parity.

Candidate `qbench.exe` is
`out/profile-107ff6406936b458/qbench.exe`, SHA-256
`D4136E266A0E15BF0EF562DD2836EB225C7BB155317B9F254424E4B9E372AC3A`. The
strict linked i486 audit passed: 314,246 linked instructions were verified
with zero above-i486, unknown, or exempt instructions. The audit covered 403
objects, 435 executable text ranges, 529 startup rows, and 9,207 provider
instructions. The final mapping covered 2,376 CODE ranges and 35 DATA ranges.

The compared binaries share the same i486 selector profile apart from the
turbulent implementation. Their source-tree fingerprint is
`22211414D4E98A1841DCFF8E6156A73701825869384608153556D4E493ACBE71`.

Run reports are retained in `out/dos-ab-fourteen-stosb-20261027/`.
