# Surface-cache texture preload rejected (2026-10-21)

Status: rejected on the negative three-run pooled mean. The source was restored
to the promoted key-pointer-retention layout.

The candidate moved the `r_drawsurf.texture` argument load ahead of the
`cache->dlight` test, aiming to overlap the stack load with the cache flag
check. The change was confined to `D_CacheSurfaceHit_asm486` in
`src/renderer/asm486_experiments.s`.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Promoted key-pointer control | `out/dos-timedemo-20261021-043143/timedemo-result.json` | 15.537299 / 15.537291 / 15.537288 | 15.537292667 |
| Texture preload | `out/dos-timedemo-20261021-052418/timedemo-result.json` | 15.537287 / 15.537301 / 15.537284 | 15.537290667 |

The pooled delta was **−0.000002 FPS (−0.00001287%)**. Both builds passed the
complete strict i486 audit, and all six timedemos passed frame/checksum parity.
The negative mean rejects this ordering; the promoted key-pointer-retention
code remains active.
