# Commit validation and existing host-test debt (2026-11-08)

## Verified builds and focused checks

The reviewed source builds successfully with the supported builder and complete
source-bound i486 audits. Fresh normal **NitroQuake v0.999+27** checks
163609 relocated instructions; fresh BENCH **NitroQuake v0.999+28** checks
315385. Both also pass 529 startup rows, 9207 provider instructions and all
403 project/runtime object proofs, with zero instruction exemptions.

The fresh normal build has 166 of 168 project text sections byte-identical to
the previously validated normal release. The other two differ only in reviewed
complete version and compile-time literal strings. This transfers native-code
identity, not a new runtime/FPS measurement.

Automatic numbering, 48 concurrent reservations, archive fallback, invalid-state
rejection and read-only flag inspection pass. Release/BENCH flag contracts for
both i486 and i386 match the untouched baseline after only the intended forced
host identity header is accounted for. The missing independent per-source-header
test expectation was fixed in the build-identity commit.

Retained renderer and AI-cache state/color/Z/image evidence was reverified from
the underlying files. The prior measured performance results are preserved;
these validation builds do not replace or extend the benchmark samples.

## Pre-existing host-suite failures

The broad host run passes **11 of 19 gates**. The complete host suite is not
green, and the full DOS verification suite was not rerun for this commit task.
An untouched archive of starting commit `e303693` reproduces the failing gates:

| Gate | Observed existing failure |
|---|---|
| test-build-dos.py | 72 stale suffix, golden flag and selector/dependency expectations |
| test-sysinfo-dos.py | Source-layout/order fixture cannot find its expected call |
| test-video-dos.py | Extracted C fixture fails to compile against current reference functions |
| test-rendering.py | Five obsolete assembly/selector-count assertions |
| test-lavasplash.py | Expects 55 assembly sources; inventory contains 86 |
| test-entityparticles.py | Expects 55 assembly sources; inventory contains 86 |
| test-renderer-ownership.py | Two errors and two failures in old indirect-dispatch fixtures |
| test-renderer-profile-completeness.ps1 | Rejects intentionally retained legacy edge-list assembly |

The initial current build-matrix run had two additional missing-header
expectations. After correction, a complete rerun reports the same **72 failure
categories as the untouched baseline**, with only checkout-derived output hashes
normalized for comparison. No golden, selector or runtime change was made to
hide those failures. The other failing gates also reproduce in the baseline.
The video fixture was retried with native GCC available through a process-local
PATH; both the baseline and current fixture fail to compile. The initial missing
compiler on PATH is therefore not the only cause of that failure.

These are existing validation debts, not passing checks. Repairing the stale
fixtures and contracts is separate maintenance; this change does not claim the
full suite passes or that physical 486 hardware has been tested.

## Evidence and preservation

All validation output is retained locally in `out/commit-review-20261108/`.
`validation-summary.json` pins both fresh manifests, exact baseline comparison,
and raw logs. `host-test-results.json`, `head-baseline-tests.json`,
`build-identity-contract.json`, `fresh-release-native-evidence.json` and
`history-fold.json` retain the detailed checks and commit grouping.

The five source/documentation commits separate build identity, correctness
replays, alias line-scan bounds, historical experiments and the AI leaf cache.
The correction to the header expectation was folded into the initial identity
commit without touching working files; pre-existing commits were not rewritten.
The two supplied logo assets are committed separately in the outer repository.
The outer gitlink is updated only after the nested repository is committed.

Generated builds, staging, charts, logs and experimental worktrees remain local
under ignored output directories. The supplied `tools/486quake.exe` is preserved
and ignored alongside the other supplied baseline executables. No evidence or
unrelated files were deleted, and nothing was pushed.
