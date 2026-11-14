# CL_ParseUpdate unused bit-count loop removal (2026-10-30)

Status: retained after three matched, uninstrumented 320x200 DOSBox-X runs,
identical framebuffer checksums and event traces, and the complete linked i486
ISA gate.

## Change

`CL_ParseUpdate` in `src/client/cl_parse.c` previously scanned all 16 update bits and
incremented `bitcounts[16]` for each entity update. A source-wide search found
no reads of that array: the declaration and the increment loop were its only
references. Removing both deletes diagnostic bookkeeping from the client
server-message path without changing message reads, entity fields, or update
ordering.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31 with the pinned `cputype=486` profile
(SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, `testdata/id1`, the aggressive selector profile, and
`CacheCheckImplementation=asm`. The build selector manifests matched. The
source-tree fingerprints differ because the candidate changes `cl_parse.c`:
control `F00C00DC946F043A83B000CAB336167794B43E08894C0E5E77379326CB0ABBD8`,
candidate `854ECA64246C18FAED41A1D981A57079C420A2B0FC21F3540FC2973029EF5FE7`.

| Run | Control seconds | Control FPS | Candidate seconds | Candidate FPS |
|---:|---:|---:|---:|---:|
| 1 | 59.368651 | 16.321745 | 59.345339 | 16.328156 |
| 2 | 59.368771 | 16.321712 | 59.345307 | 16.328166 |
| 3 | 59.368801 | 16.321704 | 59.345340 | 16.328156 |

Control mean: **16.321720333 FPS**. Candidate mean: **16.328159333 FPS**.
The gain is **+0.006439 FPS (+0.0394505%)**, or 24.16 microseconds per frame
on this DOSBox-X profile. Every run rendered 969 frames and ended at framebuffer
checksum `1047377823`. The recorded particle and damage event counts and frame
lists matched across variants, as did the rendering diagnostics.

Control: `out/dos-timedemo-20261030-145542/timedemo-result.json`.
Candidate: `out/dos-timedemo-20261030-151117/timedemo-result.json`.

## Correctness and i486 gate

The candidate passed the complete executable gate: 314,288 relocated
instructions, 529 startup code rows, and 9,207 CWSDPMI instructions; zero
above-i486, unknown, or exempt instructions. The timedemo enforced 969 frames
and checksum `1047377823` on every run.

This small DOSBox-X gain is evidence for retaining the dead-counter removal; it
does not establish the same percentage on a physical 486.
