# Edge-scan surface-base register cache rejected (2026-10-21)

Status: rejected on the negative strict pooled mean. The original row limit
and surface-base loads remain active in `src/asm486_experiments.s`.

The candidate kept the stable `surfaces` base in callee-saved `%edi` across the
scanline loop, used a stack local for the final row, and reused `%edi` for the
span-state reset and surface-span flush setup.

The parity screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All runs completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Fresh control | `out/dos-timedemo-20261021-171927` | 15.537293 / 15.537291 / 15.537287 | 15.537290333 |
| Surface-base cache screen | `out/dos-timedemo-20261021-172454` | 15.538382 / 15.538369 / 15.538364 | 15.538371667 |

The parity-only screen was positive by **+0.001081333 FPS**. The audited
strict candidate then measured 15.538366, 15.538373, and 15.424542 FPS, for a
pooled mean of **15.500427 FPS**. The third sample is retained in the mean.
Against the latest strict control mean of **15.537297 FPS** from
`out/dos-timedemo-20261021-155525`, the strict delta was **−0.036870 FPS
(−0.23729996%)**. Exact frame/checksum parity held for every run, but the
negative strict pooled mean rejects the candidate.

The complete strict i486 gate passed: 313,313 linked instructions across 435
code ranges, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The strict result is
`out/dos-timedemo-20261021-175617`; its executable SHA-256 is
`C782E61602CB2C526967783BA3A23E138C076A2784A6B470781EB83F29C90D90`. The
candidate source-tree fingerprint was
`8EE85EC119A65261E6E8A124F7CD33E978304F8DE70E0AEC57DD82F0241D1988`.
