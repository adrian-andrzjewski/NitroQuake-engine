# Reproducing the i486 executable proof

## Selected CPU and FPU contract

The selected hardware target is an Intel 80486DX-class processor with its
integrated, 80387-compatible x87 FPU present and enabled. A 486SX without an FPU
is outside this execution target. The instruction contract is the 486 integer
ISA plus the 387 x87 instruction set; Pentium and later instructions remain
forbidden.

The pinned DOSBox-X execution profile sets `cputype=486` and `fpu=387` to model
that target. DOSBox-X's CPU model is representative only and does not enforce
instruction-set limits, so the object and linked-code audits below remain the
compatibility gate. The i486 build target and its golden flag manifest identify
the same hardware/FPU contract.

## Build and instruction verification

Run `tools/build-dos.ps1 -NoBootstrap` after installing the toolchain described
by `tools/dos-toolchain.json`. The normal i486 build verifies project objects,
all linked runtime objects, the actual relocated executable instructions,
the embedded 16-bit startup code and the maintained CWSDPMI provider. An unknown encoding or an instruction outside
the i486/387 target fails the build. `-SkipIsaAudit` produces an explicitly
unverified artifact which the normal i486 execution runners reject.

The selected execution profile is a 486DX with x87 enabled, represented by
`tools/dosbox-x-486-high.conf` (`cputype=486`, `fpu=387`). `CpuTarget=i486`
remains the strict instruction-set floor; the x87 instructions used by Quake
are permitted on this profile.

For framebuffer diagnosis only, `render-parity-dos.ps1 -VisualParityOnly`
allows paired C/reference and assembly runs to use fresh i486-targeted binaries
with the renderer ISA audit skipped. It writes those binaries to a separate
`out\visual-parity-*` tree, verifies the requested selectors and executable
hashes, and independently checks the maintained CWSDPMI provider. The pair and
both child reports say `isaAuditStatus: SKIPPED`; this mode does not satisfy the
486 compatibility gate and must not be used to promote a renderer
implementation. The regular i486 runner remains strict by default.

For the accepted drawing conversion, build with the selectors in
`tools/renderer-profiles/i486-asm-drawing.json`. Profiles are JSON selector
tables; apply every selector to `build-dos.ps1`, or pass the profile to
`render-validation-dos.ps1`/`render-parity-dos.ps1`. Execution runners verify the
requested selectors against the build manifest before starting DOSBox-X.

`-save-temps=obj` retains each C compilation's actual instruction listing.
Maintained assembly is preprocessed once and assembled directly; the build
does not generate renderer assembly from C. `project-source-proofs.py` annotates
those exact streams with zero-byte labels and requires identical allocated
bytes, section properties and normalized relocations after reassembly.
`coff-code-data.py` distinguishes assembler-emitted constants from instructions
and rejects direct targets or fallthroughs into data. Inline assembly remains
code even when it uses numeric byte directives. Symbol boundaries never cut
instructions, and partially decoded bytes fail verification.

`isa-audit-linked.ps1` verifies every linked contribution against these proofs.
`final-executable-isa-ranges.py` maps their exact boundaries into the executable;
`isa-audit.ps1` independently disassembles every mapped instruction with its
full bytes and operands. The relocated instruction count must equal the verified
input count. Source-bound mode accepts no instruction exemptions, skipped
continuation bytes, arbitrary data-site allowances or relocation-field bypasses.
Reports identify the object, function, address, encoding and offending ISA.
When a proved initialized `STYP_DATA` section such as `.rodata` is linked into
output `.text`, the mapper checks its allocated-section proof, characteristics,
size, and exact linked bytes. DIR32 data relocations are checked against their
mapped section-relative targets. These bytes are recorded in `data-ranges.json`
and remain outside the CODE ranges sent to the instruction decoder.
The decoder batches up to 32 proved CODE ranges into one pinned `objdump`
process. Each range remains a separate raw-binary input, so decoding starts at
its proven boundary and never flows through adjacent data; output markers restore
the matching section, code mode, symbol range and address before classification.
The linked audit also accounts continuously for every byte in output `.text`,
including wrapped input contributions such as `.text.unlikely` and `.rodata`.
It checks the actual bytes and address ranges of linker `*fill*` records. The
documented policy permits only even-length runs of `66 90` (`XCHG AX,AX`, valid
on the 486); a gap, overlap, or different fill pattern fails closed. The linked
report records the covered byte count, policy, and each accepted fill span.

## Runtime sources and embedded startup

`tools/isa-runtime-reference/manifest.json` pins 235 native runtime identities
and 496 accompanying files. The bundle includes primary DJGPP 2.05 sources,
original instruction listings, primary alias-generator inputs, GCC 12.2 helper
sources/configuration, reproduction flags and applicable licenses. The original
DJGPP C listings were reproduced with GCC 4.7.4; their original
`-mtune=i586 -march=i386` flags are recorded rather than described as i486 flags.
Their emitted instructions, rather than compiler settings alone, determine
compatibility. All five later GCC helpers also have exact source reproductions.

`runtime-source-proofs.py` validates every pinned source/listing file and
reassembles each requested native runtime member. Unknown or changed runtime
objects fail; the gate does not substitute a rebuilt library for the linked one.
A toolchain update requires a reviewed new source reproduction and compatibility
proof, not an exemption. The bundle manifest explains the original reproduction
inputs; the normal build repeats exact native-byte boundary reproduction using
the pinned listings.

The primary DJGPP assembler is compiled as a Windows host verification tool.
A native Windows GCC is needed in addition to the DOS cross compiler. The helper
selects a Windows target and strips cross-compiler environment variables; the
Windows tool is not part of the DOS executable. `mz-loader-proof.py` rebuilds the
loaded MZ stub, including both overlapping entry streams. The CRT helper proof
rebuilds code copied from `.data`. `startup-linked-proof.py` binds the loader and
both helpers to their actual final executable bytes and linker locations.
All 1,660 loaded startup bytes are accounted for, with 529 instruction rows and
explicitly typed data.

The build manifest binds the executable, linked report, relocated report,
startup proof and current policy by SHA256. Cached execution fails if these
artifacts, decoder tools, boundary policy, primary runtime bundle or provider
change. `cws-provider-proof.py` verifies the exact maintained provider against
the primary CWSDPMI release, its two small assembly replacements, reviewed
16-bit code/data boundaries, direct and table targets, MZ relocations and
runtime instruction modifications. It decodes 9,207 instructions and the one
alternate runtime branch encoding with zero exemptions. Unrecognized provider
bytes fail. The staged provider must match the executable's verified provider
hash before the i486 runners start DOSBox-X. An alternative HDPMI32 host has no
equivalent proof and is rejected by the i486 timedemo runner.

These checks cover executable and provider machine code. The selected DOS,
BIOS and hardware interfaces remain execution-environment boundaries; their
implementations are not included in the application's binary proof. Use the
configured i486 emulator, not a later CPU profile, for execution acceptance.

## Tests and renderer equivalence

`tools/run-tests.ps1 -NoBootstrap` registers the strict encoding, boundary,
runtime identity, host-tool isolation, final mapping and genuine linked-binary
adversarial tests, including 21 provider mutation checks.
The focused linked-binary fixture also checks wrapped `.text.unlikely` map
entries, rejects a CMOV placed in that section, mutates a linked fill span to a
CMOV encoding, and fails when the map omits a fill range. Its scratch files are
confined to and removed with the fixture's temporary directory.
`test-embedded-startup-isa.py --manifest <build-manifest.json>`
runs all loader, CRT and final startup mutation checks against a verified build.
The full direct renderer suite allows 3,600 seconds and a 3,900-second outer
watchdog because correctness fixtures now include long continuous sequences.

Instruction compatibility is distinct from rendering equivalence. Run paired
profiles through `tools/render-parity-dos.ps1` with identical source, data and
fixed-time scenes. Acceptance compares post-warmup frame checksum streams,
indexed framebuffer bytes and all 768 palette bytes exactly. Historical
golden-image RGB tolerances do not replace the exact paired comparison.
When the toolchain cannot complete the full startup ISA proof, the explicit
visual-only diagnostic can be run with, for example:

```powershell
tools/render-parity-dos.ps1 `
  -VisualParityOnly -CpuTarget i486 `
  -ReferenceProfile tools/renderer-profiles/i486-c-reference.json `
  -CandidateProfile tools/renderer-profiles/i486-asm-frustum-transform.json `
  -Scenario demo1-vga-full,demo2-entity-workload,demo3-world-workload `
  -OutputRoot out/render-parity-frustum-visual
```

The resulting exact frame comparison is visual evidence only; renderer ISA
status remains explicitly skipped and must be established by the normal build
gate in a separate run.
Maintain routine-to-reference/test mappings in `docs/renderer-assembly` and
retain execution-bound binaries and reports with each acceptance result.
Timing measurements detect material regressions; a speed improvement is not a
conversion completion criterion. Remaining scope is tracked in
[renderer completion gaps](RENDERER-COMPLETION-GAPS.md).
