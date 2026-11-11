# Alias left-edge `ubasestep` specialization rejected (2026-11-11)

<!-- optimization-attempt: alias-scan-ubasestep-specialization rejected -->

## Profile census

The detailed `demo1` profile showed `alias-glue` at 4.51 seconds. A temporary
PROFILE486-only counter classified the left-edge `ALIAS_SET_LEFT_EDGE_STEPS`
inputs across 102,654 calls in 969 frames:

| `ubasestep` | Calls | Share |
| ---: | ---: | ---: |
| 0 | 39,806 | 38.78% |
| +1 | 10,903 | 10.62% |
| -1 | 35,223 | 34.31% |
| other | 16,722 | 16.29% |

The three common exact values account for 83.71% of calls. The census build
retained the framebuffer checksum `1047377823`; its source-tree fingerprint
was `E665F690F719F5DDAA8DF93A2D50BBFE1988C80FCEAB207CF7E2E20265DFA7D4`.
The counters and report additions were removed before release candidate builds.

## Candidates and strict i486 audit

Both candidates specialized the two `ubasestep * r_{s,t}stepx` products while
leaving every resulting base-step sum exact. The full specialization used
direct add/subtract paths for 0 and ±1, with the original multiply path for
other values. The smaller candidate special-cased only zero and kept the
original multiply path for every nonzero input.

Both builds passed the complete strict i486 gate. The full specialization had
316,177 linked instructions; the zero-only candidate had 316,141. Each had
zero above-i486, unknown, or exempt instructions, 529 startup CODE rows, and
9,207 DPMI-provider instructions. Source proofs covered 403 objects and 435
linked contributions.

Under the default autoexec, both candidates matched the control byte-for-byte
across all 970 color records, all 970 Z records, and the frame 482 PCX. Each
run rendered 969 frames with checksum `1047377823`.

| Stream | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 482 PCX | `437F3EA0349D226EE4BFD3A4C29CE7085C48FB873807B711AA599030AE413F87` |

## Matched timing

Three uninstrumented runs per variant used the pinned DOSBox-X 2026.08.31
i486 profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and the enforced 969-frame checksum gate.

| Variant | FPS samples | Mean FPS | Spread | Delta vs control |
| --- | --- | ---: | ---: | ---: |
| Control | 16.892467 / 16.892447 / 16.892441 | 16.892451667 | 0.000026 | — |
| 0, ±1 specializations | 16.890429 / 16.890530 / 16.890450 | 16.890469667 | 0.000101 | -0.011733% |
| Zero-only specialization | 16.891460 / 16.891478 / 16.891465 | 16.891467667 | 0.000018 | -0.005825% |

Both candidates are slower than control. The `ubasestep` specialization is
rejected and the original two multiply paths remain. DOSBox-X timing does not
establish performance on a physical 486.

## Artifacts

- Census: `benchmarks/out/engine-profile-alias-ubase-hist-20261111.json`
- Control build and timing: `out/local-alias-gradient-fchs-control-20261111/`, `benchmarks/out/dos-timedemo-20261111-025502/timedemo-result.json`
- Full specialization build and timing: `out/local-alias-ubase-specialized-candidate-20261111/`, `benchmarks/out/dos-timedemo-alias-ubase-specialized-candidate-20261111.json`
- Zero-only build and timing: `out/local-alias-ubase-zero-only-candidate-20261111/`, `benchmarks/out/dos-timedemo-alias-ubase-zero-only-candidate-20261111.json`
- Control parity: `benchmarks/out/dos-timedemo-20261111-000504/`
- Full specialization parity: `benchmarks/out/dos-timedemo-20261111-040820/`
- Zero-only parity: `benchmarks/out/dos-timedemo-20261111-042717/`
