# Math support assembly ownership

## Accepted returning routines

Twenty public entries from `mathlib.c` now have maintained assembly definitions
in `src/r_mathclosureasm.s`. They cover projection, perpendicular vectors,
axis rotation, angular wrapping, vector operations, length, matrix composition,
floor quotient/remainder, GCD and the terminating plane-sign diagnostic.
Normal builds assemble the file; they do not regenerate it with a C compiler.
The original source, import flags and function mapping are retained in
`docs/renderer-assembly/math-closure-reference.c` and
`math-closure-provenance.json`. Layout/type assertions live in
`src/asm_mathclosure.h`; the ABI and x87 store boundaries are documented beside
the instructions.

The isolated direct fixture passed 29,184 comparisons of the nineteen returning
routines across all twelve documented precision/rounding combinations, followed
by 8,192 uninterrupted matrix frames. It checks exact result/state bits, vector
and matrix aliases, register ownership, stack/x87 balance and guards. The
terminating `BOPS_Error` entry is inspected separately; this fixture does not
claim to execute it. Evidence:
`out/math-closure-worktree-20261007/out/dos-bench-20261007-170852`.

The 2026-10-10 strict i486 release-profile run repeated the fixture under
DOSBox-X with `cputype=486`, `fpu=true`, and fixed 33,445 cycles. All 29,184
direct cases and 8,192 sequential frames passed. The linked executable, 529
startup CODE rows, and 9,207-instruction runtime provider passed the complete
ISA gate with zero above-i486, unknown, or exempt instructions. The runtime
result is `out/dos-bench-20261010-122029/bench-result.json`; the matching
executable and ISA reports are under
`out/profile-ae438ae7269d8e33/isa-qbench/`.

## Scene equivalence and integration

The focused actual-selector pair passed three demo scenes twice per profile:
6,058 post-warmup frame checksums and six indexed framebuffers, including all
palette bytes, matched exactly. Both profiles used source tree SHA256
`3E266011813AFB386D1551CCEBE1182114AC1D1B5CB60DD21188B8DEBC8BD9CA`.
Actual build manifests verified `MathClosureImplementation=asm` for the
candidate and `c` for the reference. Evidence:
`out/math-closure-worktree-20261007/out/render-parity-math-closure-verified-selection-20261007`.

The candidate's object/runtime/linked gate inspected 110 project objects,
235 runtime inputs and 226,169 linked instruction sites. No non-exempt
above-i486 or unknown encoding was accepted by that gate. The remaining
classifier and external-runtime proof obligations are tracked in
`docs/RENDERER-COMPLETION-GAPS.md`; this incremental result does not close them.

Median reference/candidate FPS was 12.6821465/12.6821505,
12.781609/12.7816135 and 12.1748535/12.1748495. These measurements show no
material regression, and speed is not an acceptance criterion.

The reviewed integration retains preimages and an allowlist in
`out/math-closure-integration-preimages-20261007/manifest.json`.
It also removes the unused normalization/orientation C bodies from selected
release builds, keeps benchmark oracles, and gives the perpendicular-vector
oracle its own C normalization call. That integration passed the combined
six-scene pair, with 11,842 exact frame comparisons and twelve exact captures;
see [combined parity](2026-10-07-all-selectable-combined-parity.md).
The 486DX + x87 release profile now defaults `MathClosureImplementation` to
assembly; an explicit C selector and the separate i386 profile retain the C
reference. The all-selectable profile also selects assembly. Complete-renderer
ownership and human acceptance remain pending.
