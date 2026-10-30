# `R_GenerateSpans` non-bmodel edge-sort fifteen-continuation trial (2026-10-30)

Status: rejected. The candidate added one comparison-and-advance step to the
promoted fourteen-continuation `Lsortloopnb` group. The fourteen-continuation
source was restored after the trial; its source-tree fingerprint matches the
pre-trial control exactly.

## Matched 320x200 timedemo

Both builds used DOSBox-X 2026.08.31, `cputype=486`, fixed 33445 cycles, the
pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
CWSDPMI, `demo1`, the aggressive selector profile, and
`MemoryImplementation=asm`. Each three-run set completed 969 frames with
framebuffer checksum `1047377823` and identical recorded gameplay-event traces.

| Variant | FPS samples | Spread | Mean FPS |
|---|---|---:|---:|
| Fifteen continuations | 16.328131 / 16.328161 / 16.328163 | 0.000032 | 16.328151667 |
| Fourteen-continuation control | 16.328156 / 16.328166 / 16.328156 | 0.000010 | 16.328159333 |

The candidate mean was **-0.000007667 FPS (-0.00004696%)** below control.
The difference is far smaller than either sample spread and is non-positive,
so the additional continuation was rejected. No 640x480 run was made.

## Correctness and i486 gates

All six runs retained the expected frame count and framebuffer checksum, and
their recorded event counts and frame traces matched. The candidate passed the
full linked i486 audit: 314,291 relocated instructions, 529 embedded startup
instructions, and 9,207 external DPMI-provider instructions, with zero
above-i486, unknown, or exempt instructions. The candidate source-tree
fingerprint was
`FB1D25242E42732AAAF44B1D5C9B71C5E2582E5F16AD9AFF486165556639DC05`;
after restoring the candidate, the current source-tree fingerprint is again
`854ECA64246C18FAED41A1D981A57079C420A2B0FC21F3540FC2973029EF5FE7`, equal
to the control. No fixed-step frame-stream or PCX comparison was run because
the candidate was not retained.

## Artifacts

- Candidate results: `out/dos-timedemo-20261030-154651/timedemo-result.json`
- Control results: `out/dos-timedemo-20261030-151117/timedemo-result.json`
- Candidate build and audit: `out/local-edge-sort-15-20261030/`
- Candidate build fingerprint: `B9CD35EECEB29DC49495BDCB62724B688E158802A9E5EAB47F076F527601B278`
