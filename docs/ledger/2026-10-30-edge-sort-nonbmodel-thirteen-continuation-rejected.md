# `R_GenerateSpans` non-bmodel edge-sort thirteen-continuation trial (2026-10-30)

Status: rejected after a negative 320x200 timedemo mean; the retained
fourteen-continuation source was restored.

## Candidate

The candidate removed one ordered `st_next` advance, key comparison, and signed
`jl LInsertAndExit` from the unrolled `Lsortloopnb` body. It kept the initial
comparison and thirteen continuations before the back-edge. The `PROFILE486`
counter and optional `EDGE_SCAN_PROBE_SORT` block for the removed comparison
were removed with it. Comparison order and early-exit behavior were unchanged.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the aggressive i486 selector profile, with no extra
Quake arguments.

| Variant | Source-tree fingerprint | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Retained fourteen-continuation control | `FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D` | 16.328477 / 16.328473 / 16.328474 | 0.000004 | 16.328474667 |
| Thirteen-continuation candidate | `D625CAE714B33505FFAE93A9F94BA7CE9FAB519C8F39F055B4E2048AF4D91FA9` | 16.328464 / 16.328470 / 16.328479 | 0.000015 | 16.328471000 |

The candidate mean was **0.000003667 FPS slower (-0.00002246%)** and below
both sample spreads. All six runs rendered 969 frames with framebuffer
checksum `1047377823` and identical event traces. The non-positive mean rejects
the candidate.

## Compatibility and artifacts

This was a timing screen using the isolated visual-parity build, which skipped
the candidate ISA audit. The candidate only removed existing comparisons and
used no new instructions. Since the measured result was negative, no strict
promotion build or fixed-step image comparison was run. After restoration, the
source-tree fingerprint returned to the control value
`FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D`.

- Candidate timing: `out/dos-timedemo-20261030-201539/timedemo-result.json`
- Candidate isolated build: `out/visual-parity-profile-107ff6406936b458/`
- Control timing: `out/dos-timedemo-20261030-162411/timedemo-result.json`
