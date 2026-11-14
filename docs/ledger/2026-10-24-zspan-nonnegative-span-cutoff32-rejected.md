# D_DrawZSpans nonnegative span cutoff at 32 pixels

Status: rejected on the slower three-run mean; the 24-pixel cutoff remains in
`src/renderer/d_draw.s`.

The paired `demo1` timedemos used DOSBox-X 2026.08.31 and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. All six
runs completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Control, cutoff 24 | `7BE17091D3C94029FAABA5B110526EF5FE6B4C6BA1819DEA41DFA8549EA22ABD` | 15.803280, 15.803272, 15.803277 | 15.803276333 | 0.000008 |
| Candidate, cutoff 32 | `9FF3C845A82FB81D47BF9E7028AC344B41893A64D5FC3A91A39D8E4F53169981` | 15.798684, 15.798679, 15.798690 | 15.798684333 | 0.000011 |

The candidate was **0.004592 FPS slower (−0.029057%)**. The negative mean
rejects skipping the fast path for 24–31 pixel spans, so the committed
24-pixel cutoff has been restored.

- Control result: `out/dos-timedemo-20261023-215042/timedemo-result.json`
- Candidate result: `out/dos-timedemo-20261023-221408/timedemo-result.json`
- Strict candidate build: `out/local-zspan-nonnegative-cutoff32-20261023/`

The candidate's complete strict i486 gate passed before timing: 275,727 build
instructions and 314,024 linked instructions across 435 executable ranges;
529 startup rows and 9,207 DPMI-provider instructions; zero above-i486,
unknown, or exempt instructions. Final source mapping covered 2,375 CODE and
35 DATA ranges. This technical pass does not change the timing rejection.
