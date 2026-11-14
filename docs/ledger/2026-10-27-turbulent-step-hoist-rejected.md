# Turbulent S/T-step scheduling rejected (2026-10-27)

Status: rejected after a negative pooled three-run mean; the candidate source
change was restored.

In the fourteen-pixel turbulent-span loop, move each coordinate-step addition
to immediately after its coordinate accumulator is consumed. This was intended
to overlap the step loads with the remaining coordinate interpolation and
texture-index work.

The runs used DOSBox-X 2026.08.31, `demo1`, and the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Aggregate pooled FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261027-071815/timedemo-result.json` | 16.178397 / 16.178429 / 16.178426 | 16.178417750 |
| S/T-step hoist | `out/dos-timedemo-20261027-081957/timedemo-result.json` | 16.178401 / 16.178422 / 16.178421 | 16.178414419 |

Pooled FPS is total rendered frames divided by total timedemo seconds across the
three runs. The candidate delta was **−0.000003331 FPS (−0.00002059%)**. Both
variants rendered 969 frames per run and produced framebuffer checksum
`1047377823` on every run.

The full strict i486 audit passed: 403 exact object proofs, 314,300 linked
instructions, 529 startup instructions, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. The result and audit evidence
remain under `out/`. The candidate-only edit to `src/renderer/d_scana.s` was restored, so
there is no source change to commit.
