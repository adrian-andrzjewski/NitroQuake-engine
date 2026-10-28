# D_DrawZSpans zero-step negative-depth REP STOSL (2026-10-27)

Status: rejected after the matched three-run mean decreased. The source was
restored to `HEAD`; no commit was made.

The candidate replaced the negative-depth zero-step pair loop, which rebuilt
the same packed dword for every pair, with one packed value and `rep stosl`.
It retained the optional leading alignment word and odd trailing word.

Both timedemos used DOSBox-X 2026.08.31, `demo1`, and the pinned 32 MB i486
profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Accepted control (`6ca3860`) | `out/dos-timedemo-20261027-044245/timedemo-result.json` | 16.156418 / 16.156441 / 16.156448 | 16.156435667 |
| Negative-depth `rep stosl` | `out/dos-timedemo-20261027-053853/timedemo-result.json` | 16.156412 / 16.156447 / 16.156435 | 16.156431333 |

The candidate was **0.000004334 FPS slower (-0.0000268%)**. All six runs
rendered 969 frames and produced framebuffer checksum `1047377823`.

The complete strict i486 audit passed: 314,304 relocated instructions, 435
executable ranges, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
the change despite exact parity and a passing audit.
