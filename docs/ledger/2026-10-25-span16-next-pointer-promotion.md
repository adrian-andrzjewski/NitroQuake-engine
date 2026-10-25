# 16-bit texture-span next-pointer carry (2026-10-25)

Status: promoted assembly optimization in `src/d_draw16.s`.

`D_DrawSpans16` now pushes `espan_t_pnext(%ebx)` before `%ebx` is reused, then
pops the next span at `LEndSpan`. This replaces saving the current span pointer
to `pspantemp`, reloading it, and then loading `pnext`. All completed spans
reach the balanced pop before the loop test. The function reads its input
argument from `%esp` before entering the span loop and has no stack-relative
loop accesses.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same 159 build selectors.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261025-024836/timedemo-result.json` | 15.902654 / 15.902638 / 15.902634 | 15.902642000 | 15.902638 |
| Push next pointer | `out/dos-timedemo-20261025-033823/timedemo-result.json` | 15.913892 / 15.913886 / 15.913890 | 15.913889333 | 15.913890 |

The candidate mean is **+0.011247333 FPS (+0.07072619%)**. Every run rendered
969 frames and produced framebuffer checksum `1047377823`. The pooled mean is
positive under the current no-minimum-gain rule.

The strict linked i486 gate passed: 314,387 relocated instructions, 529 startup
rows, and 9,207 provider instructions; no above-i486, unknown, or exempt
instructions. The candidate result records `isaAuditStatus: PASS`.
