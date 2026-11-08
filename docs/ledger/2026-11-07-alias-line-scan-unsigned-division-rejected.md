# Alias positive line-scan unsigned division rejected (2026-11-07)

## Candidate

In `D_PolysetSetUpForLineScan_asm486`, replace `cdq; idivl %ecx` with
`xorl %edx,%edx; divl %ecx` on the positive long-edge path. The preceding
guards establish a nonnegative numerator and strictly positive denominator,
so quotient and remainder are identical. Negative deltas and the `INT_MIN`
C fallback are unchanged. No branch or table is added.

The experiment was isolated in `out/worktree-linescan-unsigned-div-20261107/`.
Its control includes the already accepted biased bounds checks, product
versioning, and benchmark replay clock. All 20 primary input hashes still
matched `out/input-snapshot.json` when the formal run completed.

## Correctness and compatibility

The native line-scan C/assembly harness passed 16,416 cases across four x87
rounding modes with zero mismatches. Two candidate correctness replays matched
both accepted control replays byte-for-byte: all 970 color records, all 970
depth records, and the complete frame-154 PCX. No frames were excluded.
These runs used the benchmark-only deterministic presentation clock, with
`medianFps: null`; their synthetic timing is not performance evidence.

The benchmark build (`NitroQuake v0.999+8`) and normal game build
(`NitroQuake v0.999+9`) passed the complete source-bound strict i486 gate:
315,247 and 163,517 linked instructions respectively, 529 startup rows,
9,207 provider instructions, and all 403 project/runtime source proofs.
Above-i486, unknown, and exempt counts were zero.

## Formal matched timing

Three alternating control/candidate pairs ran after all compilation and audits
finished. All six formal samples are included; no outlier was removed.
The ordinary clock was active, with instrumentation, frame/depth checksum
streams, frame capture, FPS statistics, and extra Quake arguments disabled.
Every run completed 969 timed frames and ended at framebuffer checksum
`1047377823`. The profile was DOSBox-X 2026.08.31, 486/387, fixed 33,445
cycles, 320x200 `demo1`, CWSDPMI, profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | FPS samples | Mean FPS | FPS spread |
| --- | --- | ---: | ---: |
| Control | 16.823958, 16.823967, 16.823962 | 16.823962333 | 0.000009 |
| Unsigned division | 16.823953, 16.823943, 16.823949 | 16.823948333 | 0.000010 |

The mean difference is **-0.0000832146%**. This is a tiny emulator result;
it establishes no physical-486 speed improvement and fails the positive
matched-mean promotion rule.

A separate pilot control batch collected concurrently with compilation had
FPS samples 16.823949, 16.823977, and 16.689816. Before any candidate timing,
the formal protocol above was declared to avoid compilation overlap. That
pilot remains retained in `out/experiment-status.json` and was not mixed
into the formal comparison.

## Disposition and evidence

Rejected. The primary renderer source was never changed by this experiment.
The candidate source was restored from the primary baseline after saving
the narrow experimental patch as `out/rejected-unsigned-div.patch` in the
experiment worktree. The previously accepted renderer and game bundle remain
the accepted implementation; build numbers 8 and 9 identify rejected artifacts.

All following paths are relative to the experiment worktree. The verifier
`out/verify-results.py` checks the underlying reports, complete streams,
captured image, executable hashes, and audit-report hashes. Its complete
result is `out/final-evidence.json`, including all six timing report paths.
Correctness evidence is in `out/cases.log` and `out/parity.log`; build outputs
are `out/local-unsigned-div/` and `out/local-unsigned-div-game/`. All artifacts
are retained for review. The verifier covers the retained binaries and reports;
the restored source intentionally no longer represents the rejected binaries.
