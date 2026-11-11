# `R_ClipEdge` combined distance sign check with `%eax` reload promoted (2026-11-11)

<!-- optimization-attempt: clipedge-combined-sign-live-eax-reload promoted -->

## Change

`R_ClipEdge` now combines the two distance sign bits with a memory-source OR
into `%eax`. The no-crossing path uses one fewer instruction. Since `Lp2`
needs `%eax` to retain `Ld0`, the clipped path reloads `Ld0` at `Lp2` before
the existing test. This keeps both clip classifications unchanged. The earlier
variant that omitted this reload failed parity and is documented separately.

## Profile evidence

The detailed `demo1` profile recorded 1,479,208 clip-plane tests across
789,805 `R_ClipEdge` calls. The rewrite reduces instructions on no-crossing
tests; the reload keeps the clipped path's original `Ld0` value available.
The instrumented profile counts work but is not release timing evidence.

## Exact rendering parity

The fixed-clock control and candidate each completed 969 frames and ended at
framebuffer checksum `1047377823`. All 970 color records and all 970 Z records
matched byte-for-byte. The captured frame 727 PCX also matched byte-for-byte.

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 727 PCX | `1959106B8D742918FA5F1A6FBD67E36422F9B5C9463956F4AE01374459777591` |

The capture used DOSBox-X 2026.08.31 and the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Complete strict i486 audit

The control and candidate both passed the full source-bound gate. Each covered
403 exact project/runtime object proofs, 435 linked source contributions, 529
startup CODE rows, and 9,207 DPMI-provider instructions, with zero above-i486,
unknown, or exempt instructions. The control had 316,140 relocated
instructions; the candidate had 316,137.

Both were Build 864.

Control sourceTreeFingerprint: `C55DEFEAFF40D41CF3E6D85BE154519B5376C5ABFC1DF9BEC1A7684E17F1ADFE`.
Candidate sourceTreeFingerprint: `2CCFC0940DA59CF00A6220CD9D666B28BA53DD712317E194AFFEE0B5A59B7CEF`.
The only source difference was `src/r_drawa.s`.

## Matched timing

Three alternating uninstrumented `demo1` pairs used the same DOSBox-X profile
and the enforced 969-frame final checksum. Per-frame FPS instrumentation and
fixed-clock mode were disabled.

| Variant | FPS samples | Mean FPS | Range |
| --- | --- | ---: | ---: |
| Control | 16.895005 / 16.894999 / 16.895005 | 16.895003 | 0.000006 |
| Candidate | 16.903156 / 16.903171 / 16.903144 | 16.903157 | 0.000027 |

The candidate mean was **0.008154 FPS higher (+0.048263%)**. All three paired
differences were positive (0.008151, 0.008172, and 0.008139 FPS). Other
DOSBox-X processes were left untouched. This is emulator timing evidence and
does not establish performance on a physical 486.

## Artifacts and disposition

- Control build: `out/local-r-clipedge-sign-reload-control-20261111/`
- Candidate build: `out/local-r-clipedge-sign-reload-cand-20261111/`
- Fixed-clock candidate parity: `benchmarks/out/dos-timedemo-20261111-073253/`
- Control timing: `benchmarks/out/r-clipedge-sign-reload-control-01-20261111.json`, `-02-`, `-03-`
- Candidate timing: `benchmarks/out/r-clipedge-sign-reload-candidate-01-20261111.json`, `-02-`, `-03-`

The register-preserving reload implementation is retained in `src/r_drawa.s`.
