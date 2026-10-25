# Texture-span next-pointer carry (2026-10-25)

Status: promoted assembly optimization in `src/d_draw.s`.

`D_DrawSpans8` now pushes `espan_t_pnext(%ebx)` before reusing `%ebx`, then
pops the next span after clearing the x87 temporaries. This replaces saving the
current span pointer to `pspantemp`, reloading it, and then loading `pnext`.
The push/pop pair is balanced on both the loop and return paths. The function
uses `%esp` to fetch its input argument before entering the span loop; the
loop has no stack-relative accesses.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same renderer selectors.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261024-234655/timedemo-result.json` | 15.902648 / 15.902638 / 15.902630 | 15.902638667 | 15.902638 |
| Push next pointer | `out/dos-timedemo-20261025-024836/timedemo-result.json` | 15.902654 / 15.902638 / 15.902634 | 15.902642000 | 15.902638 |

The candidate mean is **+0.000003333 FPS (+0.00002096%)**. Every run rendered
969 frames and produced framebuffer checksum `1047377823`. The pooled mean is
positive under the current no-minimum-gain rule; the medians are equal and the
sample ranges overlap, so the measured gain is small.

The strict linked i486 gate passed: 314,384 relocated instructions, 529 startup
rows, and 9,207 provider instructions; no above-i486, unknown, or exempt
instructions. The candidate result records `isaAuditStatus: PASS`.
