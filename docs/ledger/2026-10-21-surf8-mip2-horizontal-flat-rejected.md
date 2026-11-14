# Mip-2 horizontal-flat surface block rejected (2026-10-21)

Status: rejected on the negative three-run pooled mean. The assembly fast path
was removed from `src/renderer/surf8.s`.

This re-opened the mip-2 horizontal-flat surface block after an earlier attempt
had failed its framebuffer checksum. The new implementation checked equal
left/right light values and equal vertical steps, then used a four-row loop
that omitted per-texel light updates for qualifying blocks. It added four
colormap patch sites and their `R_Surf8Patch` entries. The new implementation
passed exact parity, so the earlier checksum regression was not reproduced.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Promoted-source control | `out/dos-timedemo-20261021-043143/timedemo-result.json` | 15.537299 / 15.537291 / 15.537288 | 15.537292667 | 0.000011 |
| Mip-2 horizontal-flat path | `out/dos-timedemo-20261021-062758/timedemo-result.json` | 15.537014 / 15.537000 / 15.537010 | 15.537008000 | 0.000014 |

The pooled delta was **−0.000284667 FPS (−0.00183215%)**. The candidate passed
the complete strict i486 audit: 313,344 relocated instructions across 435
executable ranges, 529 startup code rows, and 9,207 provider instructions, with
zero above-i486 instructions, unknown instructions, or exemptions. All six
timedemos passed frame/checksum parity. Its negative mean rejects the path.
