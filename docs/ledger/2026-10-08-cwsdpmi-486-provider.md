# Maintained i486 CWSDPMI provider

## Exact provider boundaries and replacements are verified

The original CWSDPMI R1 binary contains two CPUID encodings and an undocumented
`AAM 16` formatter sequence. The maintained provider replaces CPU detection
with an explicit i486 result and replaces the formatter sequence with ordinary
documented integer instructions. Only 36 bytes differ in the 25,920-byte
provider. Its MZ headers, relocation records, configuration and remaining code
are unchanged. The original binary, author's source and binary archives,
licenses, patch source and reviewed boundaries are pinned in
`tools/isa-provider-reference/manifest.json`.

The maintained provider SHA256 is
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`.
The primary original is
`0A890815DF6CBDC052915A856C16944CEDEC825267E7B6E453C351A0CDC695F2`.
The portable bundle manifest is
`43564D410A58E4C6DCD8A0AB5EEDAF4FD6004C12194A70A5AAB18CF9526C7CAD`.
`cws-provider-proof.py` reconstructs the changes from maintained assembly and
requires the resulting entire file to match the staged provider exactly.

Ten reviewed code regions and fifteen typed data regions cover the provider.
The strict 16-bit decoder inspects 9,207 instructions with zero unknowns or
exemptions. Direct control flow, indexed dispatcher targets and the native
16-bit descriptor mode are checked. All 25 MZ relocation words lie in typed
data or explicitly recognized immediate fields. The runtime JA-to-JB branch
modification is decoded independently; remaining runtime changes only alter
immediates. DOS, VCPI, XMS and client interfaces are named external boundaries.
This is an exact audit of the original native provider with a small reproduced
patch, not a claim that its complete historical compiler build was reproduced.

The i486 execution fixture tests all 65,536 AX inputs for the formatter,
including its defined SF/ZF/PF results, preserved registers and stack. It also
checks the CPU result. Every case passes. The portable provider mutation suite
passes 21 adversarial checks.

## Three paired scenes preserve rendering and timing

Original and maintained providers ran identical assembly renderer builds
through demo1, demo2 and demo3 twice each on the configured i486 emulator.
The comparison in
`out/cws-provider-worktree-20261008/out/provider-parity-result-20261008.json`
passes all 6,058 post-warmup checksum comparisons and six indexed framebuffer
and 768-byte palette comparisons exactly. Execution-bound original/candidate
providers, executables, manifests and linked reports are retained with the runs.

| Scene | Original FPS | Maintained FPS |
|---|---:|---:|
| demo1 | 12.5558900 | 12.5558910 |
| demo2 | 12.7082010 | 12.7081995 |
| demo3 | 11.9318905 | 11.9318900 |

There is no material timing change. The source-tree fingerprint is
`3B6A1F68F1313878BFE87EFA4B7001C89FE124EE2E254777ACF30683E86792D8`.
The original benchmark executable is
`EBBA9E32F78FBA7D63DA23571F50AA03597152A888ACE0A54E0CC221BA731A0B`;
the maintained-provider executable is
`53AD4F81C1009CC66BF108E12FB7B1275AD84006CDA28ECF8EAB383454D39D30`.

The reviewed provider is now the main checkout's default. Builds bind its
native proof and strict reports into the executable manifest. Normal i486
runners verify the actual staged provider hash before execution; unreviewed
provider substitution is rejected. The integrated release and real cached
runner pass the complete gate. See
[automatic executable verification](2026-10-08-automatic-executable-isa-gate.md).
