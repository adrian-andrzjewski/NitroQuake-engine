# RenderFace empty-clip fast branch rejected (2026-10-30)

## Candidate

`R_RenderFace_asm486` loads `clipflags` into `%edx` and then performs four
individual plane-bit checks. The candidate added `testl $15,%edx` and a
conditional jump to bypass those checks when none of the four low clip bits is
set. It preserved output, but the extra test and branch cost more than the
checks it avoided in the pinned workload.

## Measurement and disposition

Five alternating, uninstrumented pairs used DOSBox-X 2026.08.31, `cputype=486`,
the pinned `tools/dosbox-x-486-high.conf` profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, `-stdvid`, and the 969-frame 320x200 workload. No 640x480 run was made.

| Pair | Control FPS | Candidate FPS | Delta FPS |
|---:|---:|---:|---:|
| 1 | 16.321719 | 16.319629 | -0.002090 |
| 2 | 16.321719 | 16.319610 | -0.002109 |
| 3 | 16.321723 | 16.319623 | -0.002100 |
| 4 | 16.321756 | 16.319617 | -0.002139 |
| 5 | 16.321720 | 16.319630 | -0.002090 |
| **Mean** | **16.3217274** | **16.3196218** | **-0.0021056 (-0.0129006%)** |

All ten logs reported 969 frames and framebuffer checksum `1047377823`. The
candidate's two correctly configured visual runs also matched the 969-frame
checksum and each other across all 971 recorded frame checksums. Both frame-169
captures passed the committed golden comparison: 12 of 64,000 pixels changed
(0.0001875), with 0.0009375 mean absolute channel error.

The candidate build passed the complete strict i486 gates: 276,036 object
instructions, 314,333 linked-object and executable instructions, 529 startup
code rows, and 9,207 DPMI-provider instructions; there were zero above-i486,
unknown, or exempt instructions. The negative five-pair mean rejects the
candidate. `src/renderer/asm486_experiments.s` was restored to the saved control file
(SHA-256 `ECC82E9E6D5C6C020901246DDD57384C72E657492A7CD6B8D5597F5E47192181`).

## Artifacts

- Candidate executable: `out/local-rfclip-cv-d1-20261030/qbench.exe`
- Correctly configured visual gate: `out/dos-timedemo-20261030-033319/timedemo-result.json`
- Paired timing result files: `out/dos-timedemo-20261030-033721`, `033842`, `034001`, `034119`, `034241`, `034359`, `034515`, `034631`, `034748`, and `034905`
- Candidate and control source snapshots: `out/experiment-rf-clipflags-20261030/asm486_experiments.candidate.s` and `asm486_experiments.control.s`
