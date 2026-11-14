# Surface-cache leaf hit fast path rejected (2026-10-30)

## Comparison

The candidate added a frame-free leaf path to `D_CacheSurface` for static
texture hits, leaving animated entities, cache misses, dynamic-light cases, and
profile-instrumented calls on the existing routine. The candidate build passed
the source proof and linked i486 ISA audit (314,381 instructions; zero above
i486, unknown, or exempt instructions).

The uninstrumented `demo1` comparison used DOSBox-X 2026.08.31, `cputype=486`,
the pinned 320x200 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and 969
frames.

| Variant | Samples | Mean FPS |
|---|---|---:|
| Control | 16.321724 / 16.321713 / 16.321704 | 16.321713667 |
| Candidate | 16.325487 / 16.325489 / 16.325488 | 16.325488000 |

The candidate mean was **+0.003774333 FPS (+0.0231%)**. Both timing sets
retained the final framebuffer checksum `1047377823`.

## Parity gate and disposition

The matched per-frame capture runs produced 970 checksum rows each. Thirty-four
rows differed, at frames 99–103, 169–173, 482, 492–496, 528–533, 591–595, and
727–733. The captured frame-500 PCX files were byte-identical (SHA-256
`82C2E02C0241252B829EA1514405115AEC971527967ABA23FF669B9EE5A3B9B4`), and the
event summaries matched, but the full frame stream did not. The cause of those
transient differences was not established, so the positive timing result is
insufficient to promote the change.

The candidate was removed. `src/renderer/asm486_experiments.s` is restored to its
pre-candidate SHA-256
`ECC82E9E6D5C6C020901246DDD57384C72E657492A7CD6B8D5597F5E47192181`.

Artifacts:

- Control timing: `out/dos-timedemo-20261030-081915/timedemo-result.json`
- Candidate timing: `out/dos-timedemo-20261030-092938/timedemo-result.json`
- Control frame stream and frame 500: `out/dos-timedemo-20261030-093358/`
- Candidate frame stream and frame 500: `out/dos-timedemo-20261030-093940/`
- Candidate build: `out/local-dos-timedemo-surface-cache-hit-fastpath-20261030/qbench.exe`
