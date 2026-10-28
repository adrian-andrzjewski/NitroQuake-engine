# RenderFace owner-compare fusion (2026-10-20)

Status: promoted in the working assembly source.

In the regular edge-cache check in `R_RenderFace_asm486`, the cache-owner test
used to load `28(%edx)` into `%eax` and compare `%eax` with `%ecx`. The
assembly now compares the memory operand directly and keeps the previously
computed `edge_p - r_edges` offset in `%eax`. An owner mismatch branches to the
shared offset-ready clipping path, so it also reuses that offset instead of
recomputing it. The cache-hit check saves one instruction; the owner-mismatch
path avoids the duplicate offset calculation. This assembly-only change builds
on the promoted cache-offset reuse in `src/asm486_experiments.s`.

The strict candidate was compared with the immediately preceding promoted
source state, using DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. Both sets completed all 969 frames with framebuffer
checksum `1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Prior promoted source, strict set | `out/dos-timedemo-20261020-210618/timedemo-result.json` | 62.377506 / 62.377454 / 62.377463 | 15.534446 / 15.534459 / 15.534456 | 15.534453667 |
| Owner-compare fusion, strict set | `out/dos-timedemo-20261020-213827/timedemo-result.json` | 62.367481 / 62.367287 / 62.367295 | 15.536943 / 15.536991 / 15.536990 | 15.536974667 |

The candidate gained **0.002521 FPS (+0.0162284%)** over the preceding strict
set; every candidate sample beat every baseline sample. Exact frame and
checksum parity passed. The strict ISA audit passed with 313,316 relocated
instructions across 435 executable ranges, 529 startup code rows, and 9,207
DPMI-provider instructions; it found no above-i486, unknown, non-instruction,
or exempted bytes. The source-bound map covered 435 contributions, 2,377 CODE
ranges, and 35 DATA ranges. This repeatable positive gain qualifies under the
no-minimum-gain policy.

The result records source-tree fingerprint
`10971FC4D2CB32A9B11038B2B7B5E1DDE8BCFDBE998CAE55126C836FEDEE22C9` and
`isaAuditStatus=PASS`.
