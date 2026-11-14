# Surface-cache hit-key order (2026-10-30)

Status: rejected and reverted after a negative three-run 320x200 comparison.

## Candidate

In `D_CacheSurface` (`src/renderer/asm486_experiments.s`), check the cached texture
pointer before checking `cache->dlight`. This changes only the order of the two
hit-key comparisons. It preserves the same miss and hit behavior, but measured
slightly slower on the pinned DOSBox-X 486 profile. The source has been restored
to the retained EBX-pointer schedule, with the dynamic-light check first.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the aggressive i486 selector profile.

| Variant | Source-tree fingerprint | FPS samples | Mean FPS |
|---|---|---|---:|
| Retained EBX control | `FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D` | 16.328477 / 16.328473 / 16.328474 | 16.328474667 |
| Texture pointer first | `65026C0BF4610CA23FC812FDF4A53B744921D11646BBC15EE8EA220479F9CFB` | 16.328379 / 16.328389 / 16.328388 | 16.328385333 |

The candidate lost **0.000089333 FPS (-0.000547102%)**. All six runs rendered
969 frames and ended with framebuffer checksum `1047377823`; particle and
damage event traces matched. The complete linked i486 audit passed with zero
above-i486, unknown, or exempt instructions.

Control: `out/dos-timedemo-20261030-162411/timedemo-result.json`.
Candidate: `out/dos-timedemo-20261030-173826/timedemo-result.json`.

The candidate order was reverted; the retained source keeps the dlight
comparison first. This result supports the current branch order only for this
workload and DOSBox-X profile.
