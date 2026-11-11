# Span16 zero-T-step accumulator move reclassified as promoted (2026-11-11)

## Change

In `D_DrawSpans16`, the fall-through after `sarl $20,%eax` and
`jnz LNonZeroSetup` establishes `%eax == 0`. The zero-T-step path now uses
`movl %edx,%eax` to seed the S-step accumulator instead of adding `%edx` to
that known-zero value. The computed span offset is unchanged.

## Policy reclassification

The initial ledger rejected this candidate because only three of five pairs
favored it and the mean was smaller than run-to-run spread. The current policy
in `docs/OPTIMIZATION-PLAN.md` says to promote any positive pooled mean from at
least three matched, uninstrumented runs per variant, regardless of the gain's
magnitude or spread. The recorded five-pair mean is positive, so this change is
promoted under that rule. The result remains very small and is not evidence of
a statistically distinguishable gain.

## Exact rendering parity

Control and candidate each completed 969 timed frames with framebuffer checksum
`1047377823`. All 970 color records and all 970 Z records matched byte-for-byte.
The frame 727 PCX files also matched byte-for-byte.

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 727 PCX | `1959106B8D742918FA5F1A6FBD67E36422F9B5C9463956F4AE01374459777591` |

The deterministic replays used DOSBox-X 2026.08.31 and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Strict i486 gate

Both original Build 865 executables passed the complete source-bound i486 gate:
403 exact project/runtime object proofs, 435 linked source contributions, 529
startup CODE rows, 9,207 DPMI-provider instructions, and 316,137 relocated
instructions, with zero above-i486, unknown, or exempt instructions.

A fresh Build 866 candidate rebuild from source commit
`a285fceb1a70b7a21bd4d319cefb14ebdbce70af` also passed the complete gate. It
verified 316,137 relocated instructions, 529 startup rows, and 9,207 provider
instructions, with zero exemptions. Its `d_draw16.obj` SHA-256
`0CD1E63FB894237974448AA8DD925F936B768F99085FC8143DCD322F3CDD7B04` is
identical to the Build 865 measured candidate object. The fresh build output is
retained at
`D:\NitroQuake-span16-policy-20261111\out\local-local-span16-policy-candidate-20261111b\`;
its executable SHA-256 is
`219CAF8F850BB03838724FEF5A22AD3310D8D6DF52D8FFCBF736EC535FB4ABD0`.
The Build 866 executable is used here for the refreshed ISA gate only; the FPS
measurements below are from the matched Build 865 pair.

## Matched uninstrumented timing

Five alternating `demo1` pairs used 320x200, the same pinned profile, 969 timed
frames, and the enforced final checksum. Instrumentation and per-frame FPS
statistics were disabled. Other DOSBox-X processes were left untouched.

| Pair | Control FPS | Candidate FPS | Delta FPS |
| ---: | ---: | ---: | ---: |
| 1 | 16.903120 | 16.903152 | +0.000032 |
| 2 | 16.903118 | 16.903130 | +0.000012 |
| 3 | 16.903164 | 16.903147 | -0.000017 |
| 4 | 16.903158 | 16.903155 | -0.000003 |
| 5 | 16.903128 | 16.903132 | +0.000004 |
| Mean | 16.903137600 | 16.903143200 | +0.000005600 |

The pooled mean is **+0.0000331%**. Control samples ranged over 0.000044 FPS;
candidate samples ranged over 0.000025 FPS, and paired deltas ranged from
-0.000017 to +0.000032 FPS. The positive mean meets the project's current
acceptance rule, but the change is within observed spread and does not establish
a repeatable physical-486 gain. These are DOSBox-X measurements only.

## Artifacts and scope

- Original control build: `out/local-span16-zero-tstep-mov-control-20261111/`
- Original candidate build: `out/local-span16-zero-tstep-mov-candidate-20261111/`
- Exact parity replays: `benchmarks/out/dos-timedemo-20261111-082542/` and
  `benchmarks/out/dos-timedemo-20261111-084040/`
- Control timing JSONs:
  `benchmarks/out/span16-zero-tstep-mov-control-01-20261111.json` through `-05-`
- Candidate timing JSONs:
  `benchmarks/out/span16-zero-tstep-mov-candidate-01-20261111.json` through `-05-`
- Fresh Build 866 strict audit: see the retained worktree path above.
