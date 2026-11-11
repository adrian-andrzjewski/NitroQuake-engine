# R_StepActiveU EBX scratch removal promoted (2026-11-11)

## Change

`R_StepActiveU` now reuses `%eax` as the active-edge link temporary in
`LPushBackFound`. `%eax` holds the stepped U during the predecessor search, but
that value is dead after the search succeeds. This removes the normal path's
unconditional `%ebx` save and restore. Builds with `EDGE_SCAN_PROBE_STEP` still
preserve `%ebx` for the probe. The ordering comparisons and edge-list updates
remain unchanged.

## Profile signal

The current-source detailed `demo1` profile recorded 146,281
`R_StepActiveU` calls across 969 frames. This confirms the routine is exercised
often enough for the removed register saves to be measurable. The profile is
instrumented evidence, not release timing evidence; its source tree fingerprint
was `F284F68D3F9A11472B77221E6C8A94A7CC8A114C28EC12CABF0A202CECD0DFBD`.

## Exact output parity

Initial wall-clock presentation captures varied at frames 727–731 in repeated
control runs as well as candidate runs. Those captures were not a deterministic
parity basis. With `-parityclock`, two control runs matched each other and the
candidate matched both across all 970 color records and all 970 Z records. Each
run completed 969 timed frames and ended at framebuffer checksum `1047377823`.
The captured frame 727 PCX files also match byte-for-byte at 65,048 bytes.

| Stream | SHA-256 |
|---|---|
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 727 PCX | `1959106B8D742918FA5F1A6FBD67E36422F9B5C9463956F4AE01374459777591` |

## Complete strict i486 audit

The candidate build from source tree
`C87A8BE5B29FC4E3B39DDE8617DDF7415D19E05EE3A575B9F86DAFBCD9775AC2` passed
the complete executable ISA gate. It had 168 exact project object proofs,
403 exact project and runtime object proofs, and 435 source-bound contributions.
The linked executable contained 316,140 instructions, with zero above-i486,
unknown, or exempt instructions. The gate also passed all 529 startup rows and
9,207 provider instructions with zero exemptions.

## Matched release timing

Three uninstrumented runs used DOSBox-X 2026.08.31, the pinned 320-by-200
`demo1` workload, 969 timed frames, and final checksum `1047377823`. Frame
checksums, fixed-clock mode, instrumentation, and FPS statistics were disabled.
The profile SHA-256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`; the
DOSBox-X executable SHA-256 was
`F17F47DFD6DA895747ACFC70A533077D0B4C55B3A8B79551A04750E2A51B8D34`.

| Pair | Control FPS | Candidate FPS |
|---:|---:|---:|
| 1 | 16.892450 | 16.895005 |
| 2 | 16.892446 | 16.895011 |
| 3 | 16.892444 | 16.895005 |
| Mean | 16.892447 | 16.895007 |

The candidate mean increased by **0.002560 FPS (+0.015157%)**. Every candidate
sample exceeded every control sample. The timing candidate used source tree
`454D676202340D1BD2DF00C7C5652E48F391BE3C46FA6BCAEC19251FC3CB5FA2`; its
`r_edgea.obj` is byte-identical to the strict-gated candidate object, SHA-256
`78D4B75B9F933EDFECE667E9C7A0A8DFF8AF9ED40B6C4F9B5FD13075B36BF52C`.
The source copy differs from the final source only in comments and preprocessor
whitespace; the two `r_edgea.obj` files are byte-identical. These are DOSBox-X
results for `demo1`, not measurements on physical 486 hardware.

## Evidence and disposition

Promote the `%eax` scratch reuse after exact fixed-clock color, Z, and PCX
parity, the complete strict i486 audit, and the positive three-run mean. The
change is limited to the normal-path register save and link-pointer temporary
in `R_StepActiveU`.

## Artifacts

- Detailed profile: `benchmarks/out/engine-profile-demo1-currentdetailed-20261111a.json`
- Control timing: `benchmarks/out/edge-step-ebx-caller-temp-control-20261111.json`
- Candidate timing: `benchmarks/out/edge-step-ebx-caller-temp-candidate-timing-20261111a.json`
- Fixed-clock controls: `benchmarks/out/edge-step-ebx-parityclock-control-1-20261111.json` and `benchmarks/out/edge-step-ebx-parityclock-control-2-20261111.json`
- Fixed-clock candidate: `benchmarks/out/edge-step-ebx-parityclock-candidate-20261111.json`
- Candidate ISA log: `benchmarks/out/edge-step-ebx-parityclock-candidate-20261111.log`
- Candidate build and proof files: `out/local-edge-step-ebx-caller-temp-candidate-parityclock-20261111/`
