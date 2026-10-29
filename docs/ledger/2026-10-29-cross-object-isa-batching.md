# Cross-object i486 ISA range batching (2026-10-29)

## Change

The strict object ISA audit now collects every proved CODE range before
disassembly and sends one manifest to `isa-disassemble.py`. The decoder groups
ranges by code mode and submits at most 32 separate raw inputs per pinned
`objdump` process across all objects. It writes temporary per-object output
files so PowerShell can classify one object at a time without holding the full
disassembly in memory. Object, range, section, mode, symbol and address
boundaries remain explicit; data ranges are never joined to code.

## Evidence

The recorded strict build contains 403 audited objects, 2,376 proved CODE
ranges across 397 objects with code, and 35 DATA ranges. The prior per-object
batching required 425 `objdump` processes for these ranges. Cross-object batching
used 75 processes, an 82.4% reduction, and reduced the Python disassembler
starts from 397 to one. These are process-count measurements; no wall-clock
speedup is claimed against an old-code timing run.

The full strict object audit completed in 160.628 seconds and matched the
recorded report: 314,263 instructions (314,262 i386 and one i486), zero above
i486, unknown or exempt instructions. The instruction-detail JSONL was
byte-identical to the recorded audit. The two-object regression fixture passed
with 505 permitted and 544 forbidden instruction encodings, and the ISA
classifier contract test passed.

This changes verification tooling only. It does not change the renderer binary
or its FPS.
