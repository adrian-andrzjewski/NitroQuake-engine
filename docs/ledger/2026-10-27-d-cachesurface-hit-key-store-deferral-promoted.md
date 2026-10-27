# D_CacheSurface cache-hit key-store deferral (2026-10-27)

Status: promoted in src/asm486_experiments.s after a positive strict three-run mean, exact frame and checksum parity, and the complete linked i486 ISA gate.

The cache-hit predicate now checks the dlight flag, texture, and four light-style keys inline before filling global r_drawsurf fields or calling setup. A valid hit returns the existing cache without writing those five texture and light-style fields. A miss fills them before the existing setup and rebuild path. Dynamic-light validation and cache-miss behavior are unchanged.

## Matched timedemo

DOSBox-X 2026.08.31, demo1, CWSDPMI, aggressive selector profile, and the pinned 32 MB i486 profile SHA-256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA. Each uninstrumented variant completed three runs of 969 frames with framebuffer checksum 1047377823.

| Variant | Evidence | FPS samples | Mean FPS | Median FPS | Spread |
|---|---|---|---:|---:|---:|
| Control parity screen | out/cache-validation-20261027/control-parity-timedemo-result.json | 16.058005 / 16.057997 / 16.058017 | 16.058006333 | 16.058005 | 0.000020 |
| Candidate parity screen | out/cache-validation-20261027/candidate-parity-timedemo-result.json | 16.077386 / 16.077418 / 16.077416 | 16.077406667 | 16.077416 | 0.000032 |
| Candidate strict | out/cache-validation-20261027/candidate-strict-timedemo-result.json | 16.077390 / 16.077415 / 16.077410 | 16.077405000 | 16.077410 | 0.000025 |

The strict candidate mean increased by 0.019398667 FPS (+0.120804%) over control. All runs retained exact frame and checksum parity. The candidate result has visualParityOnly=false and isaAuditStatus=PASS.

## i486 proof

The full gate verified 314261 relocated instructions, 529 startup code rows, and 9207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It also verified 403 exact native or annotated object proofs and mapped 435 source-bound contributions across 2376 CODE ranges and 35 DATA ranges. Compact reports are retained under out/cache-validation-20261027; large instruction JSONL dumps were omitted to limit disk use.
