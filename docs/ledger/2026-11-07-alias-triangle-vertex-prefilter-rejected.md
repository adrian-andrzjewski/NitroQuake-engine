# Alias triangle vertex prefilter rejected (2026-11-07)

## Candidate and correctness contract

Extend the [cache-completion experiment](2026-11-07-alias-triangle-cache-fill-rejected.md)
with a cheap first-vertex Z probe before the expanded rectangle and tile query.
Probe only inside the validated viewport. If the current signed Z sample is
at or below the model's conservative nearest bound, return false and execute
the normal draw path. The probe never culls a triangle or publishes a tile
bound. Boundary/malformed vertices continue to the existing coordinate checks.
Both recursive and non-subdivided bulk paths retain the batch guards.

The existing prepared helper still saves its full frame and loads context
before probing. Its caller also saves registers and pushes three arguments
before every call, including queries that immediately fall back to drawing.

## Native, replay and strict i486 evidence

Both profile and uninstrumented native suites passed **2,304 cases** across
four x87 rounding modes: 384 culls, 1,511 mutation cases and zero mismatches.
They compare the independent C scan/prefilter oracle with the validating and
prepared assembly entries, including ABI, entire guarded cache and Z-buffer,
and context state. New dedicated cases test a first-vertex sample equal to,
below, negative relative to, and above the model bound, with missing cache
entries. Early exits must leave the entire cache unchanged.

Profile build `NitroQuake v0.999+15` passed the complete source-bound i486 gate:
324,972 relocated instructions, 529 startup rows and 9,207 provider instructions.
Uninstrumented benchmark build `NitroQuake v0.999+16` passed with 317,031
relocated instructions. Both include 403 project/runtime object proofs and
435 source contributions, with zero above-i486, unknown or exempt instructions.

Both fresh profile replays matched both accepted controls in all 970 color
records, all 970 depth records and the complete frame-154 PCX. No records were
excluded. Each completed 969 timed frames at checksum `1047377823` and produced
identical counters:

| Counter | Per replay |
| --- | ---: |
| Candidate triangles / point probes | 95,167 |
| Point-probe early exits | 66,986 |
| Full tile queries | 28,181 |
| Triangle culls | 14,618 |
| Tile visits | 81,421 |
| Tile-kernel Z reads | 139,170 |
| Point plus tile Z reads | 234,337 |
| Completed entries published | 8,516 |

The probe avoids **70.4% of full queries**. Model-owner reads are 526,016;
point and tile reads above are additional. These fixed-clock profiles prove
output and counter behavior, not performance.

## Matched uninstrumented timing

After all builds, audits and profile replays finished, the uninstrumented
native suite passed. Three declared alternating control/candidate pairs then
ran with the ordinary clock, without profiling, frame/Z streams, capture,
FPS statistics or extra Quake arguments. All six samples are included.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Accepted control | 16.823963, 16.823962, 16.823968 | 16.823964333 |
| Vertex prefilter | 16.796649, 16.796663, 16.796676 | 16.796662667 |

The candidate mean is **0.1622784388% lower** than the accepted control. It
reduces the cache-completion predecessor's regression but still fails the
positive-mean acceptance rule. No normal-game build or confirmation was
pursued after this negative result.

A read-only two-second host-load sample observed unrelated application and
compiler activity during this experiment. No unrelated process was modified.
All declared samples were retained; the control spread was 0.000006 FPS and
the candidate spread 0.000027 FPS. The controls are consistent with earlier
authority runs. This observation is recorded rather than used to remove data.

All runs use DOSBox-X 2026.08.31, 486/387, fixed 33,445 cycles, 32 MiB,
320x200, demo1 and CWSDPMI. Profile SHA-256 is
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All formal samples completed 969 frames at checksum `1047377823`.
Physical-486 performance was not measured.

## Disposition and retained artifacts

Rejected. The primary renderer remains unchanged. The next lead is to probe
at the bulk call sites before register saves and argument pushes, then call
the full tile-query body only when necessary. This must cover both paths and
preserve the independent native/cache/ABI and complete replay gates. Moving
the probe ahead of the helper prologue is a smaller alternative; neither is
yet a measured improvement.

The isolated worktree is `out/worktree-triangle-cache-query-20261107/`.
Within it, `out/vertex-probe-source/` and `out/vertex-probe-sources.json` pin
the exact candidate, and `out/vertex-probe.patch` records its difference from
the accepted primary inputs. Builds are retained in
`out/local-triangle-vertex-probe-profile/` and
`out/local-triangle-vertex-probe-bench/`.

Profile native results are `out/dos-bench-20261107-205231/`; uninstrumented
native results are `out/dos-bench-20261107-211158/`. Both correctness replays
are `out/dos-timedemo-20261107-205504/`.
`out/vertex-probe-profile-evidence.json` records all hashes and counters;
`out/vertex-probe-timing-evidence.json` records every formal report path,
sample and mean. Run `rtk proxy python out/verify-vertex-probe-profile.py`
and `rtk proxy python out/verify-vertex-probe-timing.py` from that worktree
to verify source hashes, audits, native results, exact replay comparisons
and all timing samples. `out/read-host-load.ps1` is the read-only load probe.
