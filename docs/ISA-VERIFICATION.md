# Reproducing the i486 executable proof

## Build and instruction verification

Run `tools/build-dos.ps1 -NoBootstrap` after installing the toolchain described
by `tools/dos-toolchain.json`. The normal i486 build verifies project objects,
all linked runtime objects, the actual relocated executable instructions,
the embedded 16-bit startup code and the maintained CWSDPMI provider. An unknown encoding or an instruction outside
the i486/387 target fails the build. `-SkipIsaAudit` produces an explicitly
unverified artifact which the normal i486 execution runners reject.

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
