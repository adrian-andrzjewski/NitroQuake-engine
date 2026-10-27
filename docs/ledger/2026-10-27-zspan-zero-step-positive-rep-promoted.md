# D_DrawZSpans zero-step positive-depth REP STOSL promoted (2026-10-27)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 audit.

For nonnegative depth in the zero-fixed-point-step path, the candidate aligns
the destination with an optional leading word, packs two identical depth words
into one dword, and uses `rep stosl`; an odd final pixel remains a word store.
The negative-depth path is unchanged.

Both timedemos used DOSBox-X 2026.08.31, `demo1`, and the pinned 32 MB i486
profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Accepted control (`6ca3860`) | `out/dos-timedemo-20261027-044245/timedemo-result.json` | 16.156418 / 16.156441 / 16.156448 | 16.156435667 |
| Positive-depth `rep stosl` | `out/dos-timedemo-20261027-060739/timedemo-result.json` | 16.165754 / 16.165786 / 16.165774 | 16.165771333 |

The mean increased by **0.009335666 FPS (+0.05778%)**. All six runs rendered
969 frames and produced framebuffer checksum `1047377823`.

The complete strict i486 audit passed: 314,327 relocated instructions, 435
executable ranges, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions.
