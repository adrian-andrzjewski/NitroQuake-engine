# Texture-span load-first early-store combination rejected (2026-10-21)

Status: rejected under the positive-mean rule. The candidate's three-run mean
was slightly below the matched control mean, so the source was restored to the
existing promoted early-store schedule. No minimum-gain threshold was applied.

The candidate used `TextureSpanLoadOrder=loadfirst` and moved each packed word
store in both 16-pixel loop halves to immediately before the final carry-based
source-address update. This tested the load-first order together with the
promoted early-store placement. The change touched `src/d_draw16.s` only.

All six timedemos used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the uninstrumented
runner, and the pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Every
run completed 969 frames and reported framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-033929/timedemo-result.json` | 15.537289 / 15.537296 / 15.537289 | 15.537291333 | 0.000007 |
| Load-first + early store | `out/dos-timedemo-20261021-033431/timedemo-result.json` | 15.537283 / 15.537290 / 15.537292 | 15.537288333 | 0.000009 |

The candidate delta was **−0.000003000 FPS (−0.0000193%)**. All six runs
passed frame/checksum parity. The candidate's complete strict i486 audit passed:
313,316 relocated instructions across 435 executable ranges, 529 startup code
rows, and 9,207 provider instructions, with zero above-i486 or unknown
instructions and no exemptions. The control binary also retained a strict
`PASS` manifest. The negative mean rejects this schedule; the default remains
`TextureSpanLoadOrder=control` with the promoted early-store schedule.
