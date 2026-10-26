# BSP surface cursor retained in ESI (2026-10-26)

Status: promoted after a positive three-run strict i486 comparison.

`R_RecursiveWorldNode_asm486` walks each node's contiguous `msurface_t` array
with a 64-byte stride. The old loop stored its cursor in a stack local, reloaded
it into ESI for every surface, then incremented the stack local. The candidate
keeps the cursor in callee-saved ESI from array setup through the surface loop.
The renderer callees follow the project's cdecl convention and preserve ESI;
the parent traversal state is held in the continuation record.

## Measurement

Both arms used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile `out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
same pre-existing working-tree edits were present in both arms; the surface
cursor rewrite was the only source change between their fingerprints.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261026-143016` | 15.942838 / 15.942839 / 15.942853 | 15.942843333 |
| ESI surface cursor | `out/dos-timedemo-20261026-150012` | 15.948144 / 15.948137 / 15.948150 | 15.948143667 |

The strict candidate mean improved by **+0.005300333 FPS (+0.03325%)**.
Every run completed 969 frames with framebuffer checksum `1047377823`.
The complete strict i486 executable gate passed: 314,394 relocated game
instructions, 529 startup rows, and 9,207 provider instructions; zero
above-i486, unknown, or exempt instructions. The linked map bound 435 source
contributions across 2,376 CODE ranges and 35 DATA ranges.

Control source-tree fingerprint: `03631CD61E5005D1CF6A3E5549AE83D075909BA91E3812B617C7BBD080118509`.
Candidate source-tree fingerprint: `93263CFB3C70E98579EAB64A825AF165175A8918225611ED82B8F8C6256EF3F0`.
