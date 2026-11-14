# Surface-cache single-style fall-through rejected (2026-10-21)

Status: rejected on the negative three-run pooled mean. The source was restored
to the promoted key-pointer-retention layout.

The candidate inverted the `styles[1] == 255` branch so single-style surfaces
fell through to the frame/dynamic-light check and additional-style comparisons
ran out of line. The change was confined to `D_CacheSurfaceHit_asm486` in
`src/renderer/asm486_experiments.s`.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Promoted key-pointer control | `out/dos-timedemo-20261021-043143/timedemo-result.json` | 15.537299 / 15.537291 / 15.537288 | 15.537292667 |
| Single-style fall-through | `out/dos-timedemo-20261021-045741/timedemo-result.json` | 15.537293 / 15.422742 / 15.537304 | 15.499113000 |

The pooled delta was **−0.038179667 FPS (−0.245729%)**. The second candidate
sample at 15.422742 FPS is a clear timing outlier, but it remains in the pooled
mean under the user's rule. Both builds passed the complete strict i486 audit
and all six timedemos passed frame/checksum parity. The negative mean rejects
the layout; the promoted key-pointer-retention code remains active.
