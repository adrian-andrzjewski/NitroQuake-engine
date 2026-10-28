# Surface-cache hit inline return epilogue (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

Inline the saved-register and stack epilogue on `D_CacheSurface`'s cache-hit
path. This removes the unconditional jump from every cache hit to the shared
epilogue after the miss/rebuild path. The miss path keeps its shared epilogue;
cache keys, draw state, and return value are unchanged.

## Matched timedemo

Both variants used `demo1`, DOSBox-X 2026.08.31, the aggressive optimization
profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823` and
matching renderer event traces.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control (`c9da308`) | `out/dos-timedemo-20261028-193608/timedemo-result.json` | 16.241473 / 16.241484 / 16.241490 | 16.241482333 | 16.241484 |
| Inline cache-hit epilogue | `out/dos-timedemo-20261028-204019/timedemo-result.json` | 16.241862 / 16.241913 / 16.241886 | 16.241887000 | 16.241886 |

The candidate gained **0.000404667 FPS (+0.00249156%) by mean**. Every
candidate sample exceeded every control sample.

## i486 audit

The strict result has `visualParityOnly=false` and `isaAuditStatus=PASS`. The
complete gate verified 314,228 relocated instructions, 529 startup code rows,
and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. The source map verified 403 exact object proofs and 435
source-bound contributions across 2,376 CODE ranges and 35 DATA ranges.

- Source fingerprint: `A9CB795C4EF0321C95BD17BD7281255DDE8F95917AC1F9AD476FEEA9FC8DC070`
- Source-tree fingerprint: `2CD59FD5594887ADF12AC35A3D7B5BC77BFF3683CE7BA69C82C3CCFE43E8C3F5`
- Build manifest SHA-256: `9A2B5FB6774DA9CD80469DE92FEA3FE1EDFF1133F55933189D7BFA7456FE7218`
- Executable SHA-256: `F023FED210875726BCF439C4A3B1C27DE57277D1CB94E6A211D6721CCE2DC7AA`
- Linked report: `out/local-cachehit-inline-20261028/isa-qbench/isa-audit-linked.json`
- Final strict report: `out/local-cachehit-inline-20261028/isa-qbench/relocated-20261028-213438363/strict-isa.json`
