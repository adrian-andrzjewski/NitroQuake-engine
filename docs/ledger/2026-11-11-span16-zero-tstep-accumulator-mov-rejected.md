# Span16 zero-T-step accumulator move rejected (2026-11-11)

<!-- optimization-attempt: span16-zero-tstep-accumulator-mov rejected -->

## Candidate

In `D_DrawSpans16`, the zero-integer-T-step branch follows
`sarl $20,%eax` with a not-taken `jnz LNonZeroSetup`, which establishes
`%eax == 0`. The candidate replaced `addl %edx,%eax` with `movl %edx,%eax`
to seed the S-step without depending on the zero value. The detailed current
`demo1` profile recorded 1,028,835 zero-T-step cases among 2,059,232 full
segments; texture spans were 22.25% of profiled frame time. This profiling
data selected the path but is not timing evidence.

### Exact rendering parity

The control and candidate each completed 969 timed frames with final framebuffer
checksum `1047377823`. All 970 color records and all 970 Z records matched
byte-for-byte. Frame 727 PCX files also matched byte-for-byte.

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 727 PCX | `1959106B8D742918FA5F1A6FBD67E36422F9B5C9463956F4AE01374459777591` |

The fixed-clock replays used DOSBox-X 2026.08.31 and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

### Complete strict i486 audit

Both Build 865 executables passed the source-bound i486 gate. Each had 403
exact project/runtime object proofs, 435 linked source contributions, 529
startup CODE rows, and 9,207 DPMI-provider instructions, with zero above-i486,
unknown, or exempt instructions. Both had 316,137 relocated instructions.
The control source-tree fingerprint was
`2CCFC0940DA59CF00A6220CD9D666B28BA53DD712317E194AFFEE0B5A59B7CEF`; the
candidate fingerprint was
`EE20EFDF67ABA790001F7FCE376EDA658C4590464345D07A2073355DB531144C`.

### Matched timing

Five alternating uninstrumented `demo1` pairs used the same pinned profile and
the enforced 969-frame checksum. Other DOSBox-X processes were left untouched.

| Pair | Control FPS | Candidate FPS | Delta FPS |
| ---: | ---: | ---: | ---: |
| 1 | 16.903120 | 16.903152 | +0.000032 |
| 2 | 16.903118 | 16.903130 | +0.000012 |
| 3 | 16.903164 | 16.903147 | -0.000017 |
| 4 | 16.903158 | 16.903155 | -0.000003 |
| 5 | 16.903128 | 16.903132 | +0.000004 |
| Mean | 16.903137600 | 16.903143200 | +0.000005600 |

The paired mean delta was **+0.0000056 FPS (+0.000033%)**; only three of five
pairs favored the candidate. The change is indistinguishable from the measured
spread and is rejected. The source was restored to the original `addl` form.
These are DOSBox-X measurements, not physical-486 results.

### Artifacts

- Control build: `out/local-span16-zero-tstep-mov-control-20261111/`
- Candidate build: `out/local-span16-zero-tstep-mov-candidate-20261111/`
- Control and candidate parity replays: `benchmarks/out/dos-timedemo-20261111-082542/`, `benchmarks/out/dos-timedemo-20261111-084040/`
- Control timing JSONs: `benchmarks/out/span16-zero-tstep-mov-control-01-20261111.json` through `-05-`
- Candidate timing JSONs: `benchmarks/out/span16-zero-tstep-mov-candidate-01-20261111.json` through `-05-`

This was the initial disposition. It is superseded by
[`2026-11-11-span16-zero-tstep-accumulator-mov-reclassified-promoted.md`](2026-11-11-span16-zero-tstep-accumulator-mov-reclassified-promoted.md): the current acceptance rule promotes any positive pooled mean from at least three matched uninstrumented runs, even when the result is smaller than observed spread. The samples and parity evidence above are unchanged.
