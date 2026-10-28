# Span16 tail-count indirect dispatch — runtime rejection (2026-10-27)

The candidate removed the early `entryvec_table_16` pointer load and the
`jumptemp` store, then restored `counttemp` into ECX and dispatched through the
table at the end of setup. The strict build and complete i486 audit passed:
168 objects / 276,025 instructions; 403 source-bound proofs; and 314,322
linked instructions with zero above-i486, unknown, or exempt instructions.

The candidate executable exited during startup after selecting the VESA linear
mode and produced no `TIMEDEMO.TXT`, so it has no FPS result. The exact accepted
control executable produced a timedemo report in the same DOSBox staging and
profile, isolating the failure to the candidate binary. Diagnostics are in
`out/dos-timedemo-20261027-023312`.

Restored the original entry-vector pointer load, `jumptemp` store, and
`jmp *jumptemp`. No performance increase was measured, so this candidate was
not committed.
