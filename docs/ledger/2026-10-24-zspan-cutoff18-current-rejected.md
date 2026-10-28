# D_DrawZSpans nonnegative fast-path cutoff 18 recheck (2026-10-24)

Status: rejected after the full strict three-run gate; the source was restored
to the accepted 19-pixel cutoff.

This recheck lowered the current positive/add-step Z-span fast-path cutoff from
19 to 18 pixels. The strict build passed the complete i486 ISA audit and every
run rendered the expected 969 frames and framebuffer checksum
`1047377823`. The third candidate timing was a substantial slowdown; no
independent cause was established, so it remains in the pooled mean.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, identical aggressive selectors, and three uninstrumented
runs.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean time | Median FPS |
|---|---|---|---|---:|---:|
| Control, cutoff 19 | `out/dos-timedemo-20261024-153311/timedemo-result.json` | 61.019502 / 61.019478 / 61.019548 | 15.880169 / 15.880175 / 15.880157 | 15.880167025 | 15.880169 |
| Candidate, cutoff 18 | `out/dos-timedemo-20261024-155639/timedemo-result.json` | 61.017942 / 61.017978 / 61.476971 | 15.880575 / 15.880565 / 15.762000 | 15.840849022 | 15.880565 |

The strict pooled mean was **0.039318003 FPS slower (−0.24759187%)** than
control, despite a higher median. The two faster samples do not outweigh the
slow third sample under the project's pooled-mean rule.

The complete strict i486 gate passed: 276,017 project instructions and
314,314 linked instructions, with zero above-i486, unclassified, or exempt
instructions; all 403 exact object proofs and 435 executable ranges passed;
529 startup rows and 9,207 DPMI provider instructions also passed with zero
exemptions.

Candidate source fingerprint:
`377C095E4DD9C45DA1CE37C1F261074E00780563283131BFCA21E905B2FEB02A`.
Candidate source-tree fingerprint:
`FEE76C746CD55269A2E9F8F22F588CDB769A9CD249D1E24E32BB3E7A495C714E`.
