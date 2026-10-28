# RenderFace triangle/quad edge unroll (2026-10-20) — rejected

The assembly `R_RenderFace` path was temporarily given straight-line regular
edge handling for 3- and 4-edge faces, matching the C reference's common-face
specialization. It removed the per-edge loop decrement and branch, but repeated
the cache and clipping body for each edge. The change was removed after the
strict timedemo showed a repeatable slowdown.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the same build selectors except for the temporary
assembly change. Every run completed 969 frames with framebuffer checksum
`1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Current assembly control | `out/dos-timedemo-20261020-190238/timedemo-result.json` | 62.390208 / 62.390171 / 62.390172 / 62.390210 / 62.390211 / 62.390168 | 15.531283 / 15.531293 / 15.531293 / 15.531283 / 15.531282 / 15.531294 | 15.531288000 |
| Triangle/quad unroll | `out/dos-timedemo-20261020-203609/timedemo-result.json` | 62.392089 / 62.392212 / 62.392203 | 15.530815 / 15.530785 / 15.530786 | 15.530795333 |

The candidate averaged **0.00317% fewer FPS**, and all three candidate samples
were slower than every control sample. Its exact output parity and strict
linked i486 audit passed (313,891 linked instructions, 529 startup rows, and
9,207 provider instructions; zero above-i486 instructions or exemptions), but
the performance result rejects promotion. The unrolled paths are absent from
the current source.
