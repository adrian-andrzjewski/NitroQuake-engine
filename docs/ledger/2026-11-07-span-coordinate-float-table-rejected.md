# Surface span coordinate float table rejected (2026-11-07)

## Candidate and exact values

At `D_DrawSpans16` span setup, load U/V through an exact float table instead of
converting their 16-bit integer fields with two `FILD`s. Reuse the two integer
loads already needed for the destination address. The table contains 0..1280
and adds 5,124 bytes, covering the complete current `MAXDIMENSION` domain.
The arithmetic following the loads is unchanged.

All 1,281 source values and their assembled COFF `.data` entries were verified
to be exact float equivalents of the integers. Consequently the x87 loads
represent the same legal screen coordinates without rounding. No approximate
reciprocal or interpolation change is involved.

## Correctness and strict audit evidence

The benchmark build, `NitroQuake v0.999+10`, passed the complete strict i486
gate: 315,249 relocated instructions, 529 startup rows, 9,207 provider
instructions, and all 403 project/runtime object proofs. Above-i486, unknown,
and exempt counts were zero. Its manifest and executable/audit hashes were
verified against the retained artifacts.

The first two full-clock replays captured frame 154. Every depth record and
both captured images matched the accepted baseline. The first run differed in
color records 2..15; its repeat matched every accepted color record. This early
repeatability issue was retained and was not declared solved.

A subsequent matched diagnostic with `-zchecksums -parityclock -condebug`
captured frame 4: one fresh control and two candidate runs matched **all 970
color records, all 970 depth records, and the frame-4 PCX**, with no excluded
records. Their complete streams also matched both accepted baseline replays.
These fixed-clock runs are correctness evidence only, not speed measurements.

## Matched uninstrumented timing

After all builds/audits and replay diagnostics finished, three alternating
control/candidate pairs ran at 320x200 under the pinned DOSBox-X 2026.08.31
486/387 profile, fixed 33,445 cycles, 32 MiB, `demo1`, and CWSDPMI. The profile
SHA-256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All six completed 969 timed frames at final framebuffer checksum `1047377823`.
The ordinary clock was active; instrumentation, frame/depth streams, frame
capture, FPS statistics, and extra Quake arguments were disabled. All six
formal samples are included, without outlier exclusion.

| Variant | FPS samples | Mean FPS | FPS spread |
| --- | --- | ---: | ---: |
| Accepted control | 16.823956, 16.823970, 16.823951 | 16.823959000 | 0.000019 |
| Float table | 16.823958, 16.823946, 16.823938 | 16.823947333 | 0.000020 |

The candidate mean is **0.0000693455% lower**. This effectively flat, slightly
negative emulator result fails the positive-mean acceptance rule. It does not
establish a physical-486 performance improvement. No normal-game build or
production timing confirmation was pursued after this rejection.

## Disposition and retained artifacts

Rejected. The primary renderer was never changed by the experiment. The
isolated `src/renderer/d_draw16.s` was restored from the hash-verified accepted primary
source after preserving the narrow patch and candidate source. All builds,
replays, diagnostics, and timing samples remain retained.

The worktree is `out/worktree-span-coordinate-floats-20261107/`. Within it,
`out/final-evidence.json` contains every timing report path, means, spreads,
replay hashes, and the unresolved initial startup issue. `out/verify-results.py`
checks that evidence against the retained artifacts, including the archived
`out/candidate-d_draw16.s` and native object table. The compiled artifacts
intentionally represent the rejected candidate, not the restored live source.

The patch is `out/rejected-coordinate-table.patch`; build output is
`out/local-coordinate-floats/`. The first replay log is `out/parity.log` and
the subsequent diagnostic logs are `out/startup-control.log` and
`out/startup-candidate.log`. `out/parity-diagnostic.json`,
`out/startup-analysis.json`, and `out/startup-stream-analysis.json` retain the
comparison details. `out/input-snapshot.json` confirms all primary input hashes
were unchanged before restoration. The accepted normal game and the separately
published three-executable comparison chart remain unchanged.
