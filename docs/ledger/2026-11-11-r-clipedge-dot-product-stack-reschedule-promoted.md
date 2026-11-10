# R_ClipEdge endpoint dot-product schedule promoted (2026-11-11)

## Change

`R_ClipEdge` in `src/r_drawa.s` now finishes the first endpoint's clip-plane
dot product before starting the second. Each endpoint still uses the original
left-associative `(x * nx + y * ny) + z * nz` calculation, subtracts the same
single-precision `clip->dist`, and stores the result to the same float slot.
The new stack schedule removes five `FXCH` instructions for each clip-plane
test pair. It adds no cache state and changes no clipping, projection, or edge
emission decisions.

The control and candidate both use source revision `23672ac13a39a955eb7dc389143ff07ef195eb22`,
Build 857, and the `i486-asm-selectable-current` profile. Their only source
difference after line-ending normalization is `src/r_drawa.s`. The timedemo
records identify source fingerprints `97C0D0C3B01A33A1FFA6805AAEE297B4739D6F287362842B7DE733E640578B01`
for control and `DABBC9910B72705EA12D7D2708B39457FF7F6B02AB34EDE480EDA7FE3E434856`
for candidate.

## Profile evidence

The current-source detailed `demo1` profile recorded 789,805 `R_ClipEdge`
calls and 1,479,208 clip-plane tests. The candidate therefore removes
7,396,040 x87 `FXCH` operations across that replay. This count ranks repeated
work; the instrumented profile is not release timing evidence. The profile is
`benchmarks/out/engine-profile-demo1-currentdetailed-20261111.json`.

## Output parity

The fixed-clock 320-by-200 `demo1` control and candidate each completed 969
timed frames and ended at framebuffer checksum `1047377823`. Their full 970-
record color and Z checksum files match byte-for-byte, including the initial
records. The captured frame 482 PCX files are both 65,012 bytes and have SHA-256
`437F3EA0349D226EE4BFD3A4C29CE7085C48FB873807B711AA599030AE413F87`.

| Stream | SHA-256 |
| --- | --- |
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 482 PCX | `437F3EA0349D226EE4BFD3A4C29CE7085C48FB873807B711AA599030AE413F87` |

The checksummed runs are recorded by
`benchmarks/out/clipdotstack-exact-control-20261110-2353.json` and
`benchmarks/out/clipdotstack-pcx-candidate-20261110-2330.json`. The paired
color and Z streams are under `benchmarks/out/dos-timedemo-20261110-225527/`
and `benchmarks/out/dos-timedemo-20261110-224030/`.

## Strict i486 audit

The complete control and candidate gates passed. Both had 168 exact project
object proofs, 403 exact project/runtime object proofs, 435 source-bound
contributions, 529 startup code rows, and 9,207 provider instructions. The
control had 316,344 linked instructions; the candidate had 316,333. Neither
reported above-i486, unknown, or exempt instructions.

The build manifests and executable audits are retained at:

- Control: `D:\nqclipdotcontrol-20261111\out\local-clipdot-control-20261110\`
- Candidate: `D:\nqclipdotstack-20261111\out\local-local-clipdotstack-20261111\`

Their `qbench.exe` SHA-256 values are `7BD9B579CAFCD2B0EE79C24C3B19CA7CE5EAEC1B744E6C4D3D595B83663DC5B5`
and `079EF23088B49125DD697B3298044D5A0AE801B83EAFC942D9FD351395EF00F5`,
respectively.

## Matched release timing

Three alternating uninstrumented pairs used DOSBox-X 2026.08.31, the pinned
320-by-200 `demo1` workload, 969 timed frames, and framebuffer checksum
`1047377823`. The profile SHA-256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`;
the DOSBox-X executable SHA-256 was
`F17F47DFD6DA895747ACFC70A533077D0B4C55B3A8B79551A04750E2A51B8D34`.
Instrumentation, frame checksums, fixed-clock mode, and FPS statistics were
disabled for these timing runs.

| Pair | Control FPS | Candidate FPS |
| ---: | ---: | ---: |
| 1 | 16.823764 | 16.888323 |
| 2 | 16.823767 | 16.888326 |
| 3 | 16.823782 | 16.888320 |
| Mean | 16.823771 | 16.888323 |

The pooled mean increased by **0.064552 FPS (+0.383695%)**. Every candidate
sample exceeded every control sample. All six runs passed the frame-count and
final-checksum gates. This is DOSBox-X evidence for `demo1`, not a measurement
on physical 486 hardware.

The six uninstrumented result JSON files are
`benchmarks/out/clipdotstack-timing-0{1,2,3}-{control,candidate}-20261110.json`.

## Evidence and disposition

Promote the endpoint-at-a-time x87 schedule after exact color, Z, and captured-
frame parity, the complete strict i486 audit, and the positive three-pair
uninstrumented mean. The source change is limited to the clip-plane distance
calculation in `R_ClipEdge`.
