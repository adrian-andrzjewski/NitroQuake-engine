# `R_GenerateSpans` non-bmodel edge-sort sixteen-continuation trial (2026-10-30)

Status: rejected as an unmeasurable gain. The promoted fourteen-continuation
source was restored byte-for-byte after the trial.

## Candidate

The trial added two comparison-and-advance steps at the end of the
`Lsortloopnb` search group, changing the continuation count from fourteen to
sixteen. Each step preserved the original signed `jl LInsertAndExit`,
`PROFILE486` iteration increment, and optional `EDGE_SCAN_PROBE_SORT` block.
The candidate source SHA-256 was
`375BBAB1BB1325BFF2314C1F2C6809853CEF53ADE241E8F693EB2B6352A1F55C`.

## Matched 320x200 timedemo

Both builds used DOSBox-X 2026.08.31, `cputype=486`, fixed 33445 cycles, the
pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
CWSDPMI, `demo1`, the aggressive selector profile, and
`MemoryImplementation=asm`. Three uninstrumented runs per variant completed
969 frames with framebuffer checksum `1047377823`.

| Variant | FPS samples | Spread | Mean FPS |
|---|---|---:|---:|
| Sixteen continuations | 16.321753 / 16.321689 / 16.321718 | 0.000064 | 16.321720000 |
| Fourteen-continuation control | 16.321724 / 16.321713 / 16.321704 | 0.000020 | 16.321713667 |

The candidate mean was **+0.000006333 FPS (+0.00003880%)** above control, less
than its own run spread. The samples do not establish a repeatable speedup, so
the candidate was rejected and the fourteen-continuation implementation was
retained.

## Correctness and i486 gates

All six timedemo runs retained the expected frame count and checksum. Both
builds passed the complete linked executable, startup, and DPMI provider ISA
gates with zero above-i486, unknown, or exempt instructions. The candidate
covered 314,345 relocated instructions; the control covered 314,338. No
fixed-step frame-stream or PCX comparison was run because the candidate showed
no measurable speedup and was not retained.

## Artifacts

- Candidate results: `out/dos-timedemo-20261030-080407/timedemo-result.json`
- Control results: `out/dos-timedemo-20261030-081915/timedemo-result.json`
- Candidate build/audit: `out/local-local-edge-sort-16-cont-20261030/`
- Control build/audit: `out/local-local-edge-sort-14-control-20261030/`
- Restored source SHA-256: `CC4AA7016C1E7BE8DB1239EA9B4B9DFC645ED0A99D12AB69883B7ECD042E597A`
