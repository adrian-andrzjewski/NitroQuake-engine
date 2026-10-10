# `R_StoreEfrags` exact-state parity fixture

Status: validated on 2026-10-10 with the strict i486 profile and DOSBox-X.

## Traceability

`src/r_efrag.c:R_StoreEfrags` is the C reference for
`src/asm486_experiments.s:R_StoreEfrags_asm486`. With
`ASM486_EFRAG_STORE` and `BENCH486` selected, the C function is retained as
`R_StoreEfrags_C`; the existing selector binding chooses the assembly body for
assembly profiles, while the C reference remains selectable.

`src/bench486_efragstore.h` compares the reference and assembly functions from
identical inputs. It covers an empty list, all three supported model types,
duplicate and already-visible entities, one remaining visible-list slot, and
a full visible list. The exact snapshot includes the entire `cl_visedicts`
array, count, frame number, fixture entities/models/efrags, list head, canary
words, and the ABI harness result. The fixture also checks expected additions
and that every call preserves the caller ABI.

The fixture is called from the generic BENCH486 suite and can be run in
isolation with:

```powershell
rtk proxy pwsh -NoProfile -Command '& .\tools\bench-dos.ps1 -NoBootstrap -CpuTarget i486 -EfragStoreOnly -EfragStoreImplementation asm -MathClosureImplementation asm'
```

The isolated run passed all four exact C/assembly comparisons with zero
failures. DOSBox-X used `cputype=486`, `fpu=true`, and fixed 33,445 cycles. The
same build passed the complete linked executable, startup, and runtime-provider
ISA gate: 212,072 relocated instructions, 529 startup CODE rows, and 9,207
provider instructions, with zero above-i486, unknown, or exempt instructions.
Both this fixture and the math-closure fixture used executable SHA256
`809E75A22E36053FE62B97454FC944B17DCEF88B609D0582EB259185D4169CC1`.

Following that parity and ISA proof, `EfragStoreImplementation` now defaults to
assembly for i486 release builds. Explicit C selection and the separate i386
profile retain the reference implementation.

Runtime result: `out/dos-bench-20261010-122057/bench-result.json`. The matching
build and machine-code proof are under
`out/profile-ae438ae7269d8e33/isa-qbench/`.
