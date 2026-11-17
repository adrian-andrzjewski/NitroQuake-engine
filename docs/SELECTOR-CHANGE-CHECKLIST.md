# Selector change review

Per-routine selectors add build variants and increase the number of schedules
that must retain parity, pass the i486 instruction gate, and remain reproducible.
Do not add one for hypothetical future use.

## Before adding a selector

- Record the concrete need in `docs/OPTIMIZATION-PLAN.md` or a focused ledger
  entry. State whether the selector supports C/assembly parity, a measured
  alternative, or historical experiment reproduction, and link its evidence.
- Name the control and candidate values, the affected workloads, and the expected
  correctness and timing checks. For a performance candidate, identify the exact
  color/Z or framebuffer parity test and matched uninstrumented run plan.
- Add the selector once in `tools/selectors.ps1`, preserving the ordered flag and
  suffix contracts. Add its supported values to the applicable renderer profile
  and build inventory.
- Update `tools/test-build-dos.py` and the pinned `tools/golden/build-flags-*.json`
  only after reviewing the resolved suffixes, flags, source lists, and object
  inventory. Update `test-renderer-profile-completeness.ps1` if it introduces a
  new assembly-capable choice.
- Ensure the selector's effective behavior is represented by a fingerprinted
  resolved field: profile suffix, compiler/assembler flags, or source inventory.
  The manifest must also echo the selected value. Run
  `test-build-fingerprints.ps1` and `test-build-number.ps1`; the former includes
  a profile-suffix mutation check for this contract.
- Run the affected C-reference and i486 builds, exact parity fixtures, and strict
  linked-image ISA checks. Do not promote a performance candidate without exact
  output parity and repeated matched uninstrumented runs; record all samples and
  spread in the optimization ledger.

## Before removing a selector

- Confirm it is absent from supported profiles and active benchmark scenarios.
- Search the optimization plan and ledger for parity baselines, measurements, or
  historical build reproduction that still depend on it.
- Only then remove its table entry, profile value, tests, golden data, and
  manifest expectations together, and rerun the build inventory and identity
  checks.

The canonical selector table remains the only source for selector behavior.
This review record supplies rationale and acceptance steps without adding a
second flag or source-schedule table.
