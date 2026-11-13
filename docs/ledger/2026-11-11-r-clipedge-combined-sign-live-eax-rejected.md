# `R_ClipEdge` combined distance sign check rejected (2026-11-11)

<!-- optimization-attempt: clipedge-combined-sign-live-eax rejected -->

## Candidate and failure

The candidate replaced the load of `Ld1` into `%ecx` and the register-to-register
OR with a memory-source OR into `%eax`, saving one instruction on the common
unclipped path. It was not semantically equivalent: `Lp2` immediately tests
`%eax` as the saved `Ld0` value. The candidate left `%eax` holding `Ld0 | Ld1`,
so a negative `Ld1` could be mistaken for a negative `Ld0`, changing the clip
path and producing visible rendering artifacts.

The full strict i486 build passed with 316,141 relocated instructions, 403
project/runtime object proofs, 435 source-bound contributions, 529 startup
rows, and 9,207 DPMI-provider instructions; it reported zero above-i486,
unknown, or exempt instructions. This ISA gate did not detect the live-register
semantic error.

The fixed-clock replay failed on frame 0: the control color checksum was
`4202843875` and the candidate was `2281313971`; the Z checksums were
`1021981689` and `3477171287`. The process exited before a timedemo completion
record, after 260 color rows and 259 Z rows. Frame 727 was not reached, so there
is no captured PCX or performance timing for this candidate.

The flawed source rewrite was reverted before a separate corrected form was
tested. Do not use this flawed candidate executable as a renderer build; the
register-preserving version is documented in
`2026-11-11-r-clipedge-combined-sign-live-eax-reload-promoted.md`.

### Artifacts

- Candidate build: `out/local-r-clipedge-or-sign-candidate-20261111c/`
- Failed candidate replay: `benchmarks/out/dos-timedemo-20261111-071345/`
- Exact control replay: `benchmarks/out/dos-timedemo-20261111-061745/`
