# RenderFace cache-offset reuse (2026-10-20)

Status: promoted in the working assembly source.

In `R_RenderFace_asm486`, the regular edge-cache bounds check calculates
`edge_p - r_edges` in `%eax`. When that comparison rejects the cached edge,
the clip path now reuses the still-live offset to set `cacheoffset`. Expired
fully-clipped entries and owner mismatches retain the original recalculation
path. Cache hits take the same instructions as before; the bounds-miss path
removes the duplicate load and subtraction. This is an assembly-only change in
`src/asm486_experiments.s`.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and otherwise identical selectors with
`RenderFaceImplementation=asm`. All runs completed 969 frames with framebuffer
checksum `1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Current control, six samples | `out/dos-timedemo-20261020-190238/timedemo-result.json` | 62.390208 / 62.390171 / 62.390172 / 62.390210 / 62.390211 / 62.390168 | 15.531283 / 15.531293 / 15.531293 / 15.531283 / 15.531282 / 15.531294 | 15.531288000 |
| Candidate, parity screen | `out/dos-timedemo-20261020-204223/timedemo-result.json` | 62.377456 / 62.377488 / 62.377446 | 15.534458 / 15.534451 / 15.534461 | 15.534456667 |
| Candidate, strict set | `out/dos-timedemo-20261020-210618/timedemo-result.json` | 62.377506 / 62.377454 / 62.377463 | 15.534446 / 15.534459 / 15.534456 | 15.534453667 |

The strict three-run mean is **0.02038% faster** than control; every strict
candidate sample was faster than every control sample. The strict linked i486
audit passed: 313,319 relocated instructions across 435 executable ranges,
529 startup code rows, and 9,207 DPMI provider instructions, with zero
above-i486 instructions, unclassified bytes, or exemptions. Exact frame and
checksum parity passed in both candidate sets. This repeatable positive gain
qualifies under the no-minimum-gain policy.
