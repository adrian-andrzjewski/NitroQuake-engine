# Alias-gradient Y reciprocal sign flip rejected (2026-11-11)

<!-- optimization-attempt: alias-gradient-y-reciprocal-fchs rejected -->

## Candidate

`D_PolysetCalcGradients_asm486` forms `ystepdenominv` by multiplying the X
reciprocal by the exact constant `-1.0`. The candidate replaced that memory
operand multiply with x87 `FCHS`, which flips only the sign bit and avoids the
constant load.

## Exact rendering and i486 compatibility

The baseline source-tree fingerprint was
`F2514508A8C904402D5FD76760D33CD6AD105472724067B93E474F4D274D09F9`; the
candidate fingerprint was
`A97C3C705BDC6AE9594216DCDE195C469A67E7099B9183BB6F37255481225B41`. Both
used the pinned DOSBox-X 2026.08.31 486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the runner's default autoexec commands.

All 970 color records, all 970 Z records, and the frame 482 PCX matched
byte-for-byte. Each timedemo completed 969 frames with framebuffer checksum
`1047377823`.

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 482 PCX | `437F3EA0349D226EE4BFD3A4C29CE7085C48FB873807B711AA599030AE413F87` |

Both builds passed the complete strict i486 gate. The control had 316,141
linked instructions; the candidate had 316,129. Each had one i486 instruction,
zero above-i486, unknown, or exempt instructions, 529 startup CODE rows, and
9,207 DPMI-provider instructions. Source proofs covered 403 objects and 435
linked contributions. The object instruction count for `d_polysa.obj` fell from
1,411 to 1,399; this static reduction did not produce a positive timedemo
result.

## Matched timing

Three uninstrumented samples per variant used the same enforced 969-frame
checksum gate:

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.892467 / 16.892447 / 16.892441 | 16.892451667 |
| Candidate | 16.892476 / 16.892428 / 16.892436 | 16.892446667 |

The candidate mean was **0.000005 FPS lower (-0.0000296%)**. The sign-flip
rewrite is rejected; the multiply remains active. DOSBox-X results do not
establish physical-486 performance.

## Artifacts

- Control build: `out/local-alias-gradient-fchs-control-20261111/`
- Candidate build: `out/local-alias-gradient-fchs-candidate-20261111/`
- Control parity: `benchmarks/out/dos-timedemo-20261111-000504/`
- Candidate parity: `benchmarks/out/dos-timedemo-20261111-032030/`
- Control timing: `benchmarks/out/dos-timedemo-20261111-025502/timedemo-result.json`
- Candidate timing: `benchmarks/out/dos-timedemo-20261111-031317/timedemo-result.json`

The first candidate replay, `benchmarks/out/dos-timedemo-20261111-031700/`,
included extra autoexec viewport commands and was excluded from parity
comparison. The default-autoexec replay above is the valid comparison.
