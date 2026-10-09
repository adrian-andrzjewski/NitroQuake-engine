# Live `bench486` progress reporting (2026-10-09)

Long memory-helper samples previously left the DOSBox-X window at
`486 benchmark begin` without visible evidence of activity. `bench486` now
prints a progress line before each timed memory sample. The DOS runner polls
the report file while DOSBox-X is active and relays completed lines to the
console with a `[DOSBox-X]` prefix. This reporting happens outside each timed
sample.

The DOS runner also accepts `-MemoryOnly` with
`-MemoryImplementation asm`, so the 19 memory cases can be exercised without
running the rest of the benchmark suite. The focused `CpuTarget=i486` run
completed with DOSBox exit code 0, strict ISA audit PASS, and
`486 benchmark correctness PASS`. It emitted 96 progress lines: one phase
header and one marker for each of the 19 cases' five samples.

This verifies the progress-reporting path and memory-helper benchmark only; it
does not expand renderer-conversion or visual-parity coverage.
