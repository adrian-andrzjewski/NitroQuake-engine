# Alias triangle cache availability diagnosis (2026-11-07)

The implemented follow-up is recorded in [Alias triangle cache completion rejected](2026-11-07-alias-triangle-cache-fill-rejected.md):
it passed correctness but regressed matched timing. The read-only diagnostic
and its evidence below remain unchanged.

## Prototype and scope

The isolated worktree `out/worktree-triangle-cache-query-20261107/` contains an
integer i486 assembly predicate for front-facing bulk, non-subdivided alias
triangles. It queries the existing 4x4 model-occlusion cache using an expanded
triangle rectangle and the already validated whole-model nearest-depth bound.
It neither samples Z nor changes cached depth. Stale epochs, partial entries,
depth ties, invalid context and unsupported video layouts fall back to drawing.
The cache remains owned by `r_alias.c`; no second cache is allocated.

The context checks cover entity identity, viewmodel exclusion, frame, Z-buffer
identity, viewport, epoch and the exact 320x200 layout. Clipped single-triangle
calls and the recursive subdivided path retain their reference behavior. This
coverage limitation is explicit; the prototype is not a replacement for the
older common-path experiment. No triangle vertex-depth approximation is used.

The initial profile, build `NitroQuake v0.999+11`, found only 62 culls from
61,984 queries. Additional `PROFILE486` counters classify the first failing
tile of each query. Removing those profiling branches leaves the predicate's
release assembly text identical to the initial prototype.

## Strict audit and correctness evidence

The diagnostic build, `NitroQuake v0.999+12`, passed the complete source-bound
i486 gate: 403 project/runtime object proofs, 435 mapped source contributions,
324,198 relocated instructions, 529 startup rows and 9,207 provider instructions.
There were zero above-i486, unknown or exempt instructions. The retained
manifest binds the executable and audit reports by SHA-256.

The native C-oracle/assembly suite passed 1,024 cases across four x87 rounding
modes, with 128 positive results and zero mismatches. It checks ABI, context,
viewport, epoch, depth ties, invalid coordinates, cache guards and unchanged
cache/context state. Its cache-failure fixtures currently target the first
covered tile; a cache-writing successor needs independent Z-scan and cache
mutation oracles, including failures at middle and last tiles.

Two fresh diagnostic demo1 replays matched both accepted control replays in
every one of their 970 color records, 970 Z records and the complete frame-154
PCX. No records were excluded. Both completed 969 timed frames at final
framebuffer checksum `1047377823`. The earlier v11 replay also matched these
complete streams and image.

These runs use the pinned DOSBox-X 2026.08.31 486/387 profile, fixed 33,445 cycles,
32 MiB, 320x200, CWSDPMI and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
They use `-zchecksums -parityclock -condebug`; their FPS is explicitly not a
performance measurement.

## Repeatable miss classification

Both diagnostic replays produced exactly the same counts. Each query records
its first failure only; the four failure categories plus successful culls
account for all 61,984 queries.

| Query outcome | Count per replay |
| --- | ---: |
| Stale tile epoch, no current cache entry | 60,300 |
| Partial entry with cached anchor at or below the model bound | 1,196 |
| Partial entry with cached anchor above the model bound | 14 |
| Completed minimum at or below the model bound | 412 |
| All queried tile bounds pass: triangle culled | 62 |

There were 63,007 tile visits. **97.3% of queries stop at a stale entry**.
The existing whole-model query stops when it cannot cull the model, leaving
much of its rectangle unvisited. Reading completed entries alone therefore
has very little coverage for this triangle path. A low cached anchor is a
conservative lower bound; it does not prove that the current Z samples are
still low after later rendering.

The next experiment should test conservative completion of missing/partial
tiles, count added Z reads, and cover recursive as well as non-subdivided bulk
triangles where profitable. Stable context validation should move to batch
preparation. Keep the accepted whole-model depth bound until a tighter bound
has a proof covering actual integer gradients, edge rounding and overflow.

## Disposition and reproduction

This is an **unpromoted profiling prototype**, not a measured speedup or a
timing rejection. No uninstrumented performance samples were collected for
it. Promotion still requires repeated complete output parity, strict i486
audits, three matched ordinary-clock uninstrumented samples per variant with
a positive pooled mean, and normal-game performance confirmation. These
emulator results do not establish physical-486 performance.

The primary renderer was unchanged by this experiment. Within the isolated
worktree, `out/v1-readonly-source/` and `out/v1-readonly.patch` preserve the
initial candidate; `out/miss-diagnostic-source/` preserves the diagnostic
sources. `out/input-snapshot.json` pins the accepted primary inputs and
`out/miss-diagnostic-sources.json` pins the diagnostic sources.

The diagnostic build is `out/local-triangle-cache-misses-v2-profile/`.
Native results are in `out/dos-bench-20261107-193919/`; both replays are in
`out/dos-timedemo-20261107-193938/`. The earlier v11 profile remains in
`out/dos-timedemo-20261107-190254/`.

`out/miss-diagnostic-evidence.json` records the counts, exact output hashes,
manifest and report paths. Run `rtk proxy python out/verify-miss-diagnostics.py`
from the isolated worktree to check source hashes, primary input hashes,
manifest/audit hashes, native results, accounting and every saved replay byte.
`out/test-miss-diagnostics.ps1` contains the native and replay commands; launch
it with `rtk proxy pwsh -NoProfile -File out/test-miss-diagnostics.ps1`.
