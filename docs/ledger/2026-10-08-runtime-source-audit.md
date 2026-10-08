# Source-bound runtime and startup audit

## Exact runtime object boundaries

The strict audit of the 235 frozen runtime inputs passes 38,326 instructions,
all i386-compatible, with zero unknown encodings, post-486 instructions or
instruction exemptions. The initial 83 flagged sites were embedded constants
or instruction-boundary artifacts. They were resolved by source reproduction
and continuous decoding; no opcode was waived.

The original GCC 4.7.4 produces listings for 172 C objects. Primary assembly
provides another 48. Reassembly with zero-byte boundary labels preserves every
allocated byte, section property and normalized relocation in all 220 native
objects. The primary DJGPP alias generator and installed 2.05 header reproduce
the ten linked alias stubs exactly. Primary GCC 12.2 sources now reproduce the
remaining four 64-bit arithmetic objects and the DWARF unwind object exactly,
including allocated section bytes, flags and normalized relocations. Every one
of the 235 frozen runtime inputs therefore has source-derived boundaries.

Evidence resides beneath `out/isa-classifier-worktree-20261007/out`:

- `runtime-original-compiler-20261007/proofall/boundaries-4/summary.json`
- `runtime-generated-stub-proof-20261008/summary.json` and `provenance.json`
- `libgcc-arithmetic-reconstruction-20261008/proof-index.json`
- `libgcc-unwind-reconstruction-20261008-5/proof-index.json`
- `boundary-policy-refresh-20261008-5/combined-proof-index.json`
- `strict-linked-frozen-20261008-4/isa-audit-linked.json`
- `final-relocated-frozen-20261008/strict-final-isa.json`

Primary sources are [DJGPP 2.05 sources](https://www.delorie.com/pub/djgpp/current/v2/djlsr205.zip),
[2.05 headers](https://www.delorie.com/pub/djgpp/current/v2/djdev205.zip) and
[original GCC 4.7.4](https://www.delorie.com/pub/djgpp/current/v2gnu/gcc474b.zip).
The evidence pins archive, source, tool and native-object hashes. Runtime
objects were inspected, not replaced by rebuilt objects. Compiler reproduction
uses an isolated 128 MB emulator configuration; renderer tests retain the
configured 486 CPU, fixed cycles and 16 MB game environment.

The separate immutable project snapshot was also rechecked under the current
boundary policy: all 82 C objects reproduce exactly, and all 110 project objects
pass 131,352 instructions with zero unknowns or exemptions. This snapshot
precedes the later visibility, public-entry and sky ports. Its current evidence
is `boundary-policy-refresh-20261008-5/project/proof-index.json`. All 28 frozen
handwritten assembly inputs also have byte-identical boundary proofs. The full
345-input strict linked audit passes 169,617 instruction sites, with zero
unknowns, post-486 encodings, instruction exemptions or relocation-field skips.
The independent continuous decoder also passes all 169,617 instruction sites
in the actual relocated executable, using source-bound final addresses.

The isolated tooling tree now contains a portable `tools/isa-runtime-reference`
bundle: primary sources, licenses and original listings for all 235 inputs.
`tools/runtime-source-proofs.py` reassembles those listings with zero-byte
boundary labels and compares every allocated byte and relocation of the
installed objects. `runtime-portable-proof-20261008/proof-index.json` passes all
235 objects. Thirteen adversarial checks reject changed inputs, sources,
listings, escaped paths and permissive policies. Runtime objects are never
replaced; unknown or changed inputs require fresh primary-source reproduction.

## Embedded executable startup code

The MZ loader rebuild matches all 1,536 loaded bytes and all header fields that
control loading. Source-typed ranges include both valid entries into its
deliberate overlapping TEST/REPNE sequence. Its 489 instructions pass the strict
classifier without exemptions. The verifier recomputes source boundaries and
decoding and rejects changed binaries, artifacts, policies or forged ranges.
The current loader verifier passes 21 adversarial checks.

CRT `.data` contains two executable helpers copied into 16-bit DPMI selectors.
Primary `sbrk16.asm` and `exit16.asm` rebuild to the exact embedded 108-byte and
16-byte images. The allocation/API header is verified DATA; instructions and
source NOP alignment are CODE. All 40 helper instructions pass as i386, with
zero unknowns or exemptions. Direct targets and entry points must be decoded
CODE boundaries. BSS stack allocation is accounted for separately from copied
image bytes. The helper verifier passes 22 adversarial checks, including
altered opcodes, header data, artifacts, range modes, object bounds and identities.

`startup-linked-proof.py` now maps the loader and both helpers into the final
frozen executable and verifies every copied byte, including API header data.
`startup-linked-frozen-20261008/startup-linked-proof.json` binds 1,660 loaded
startup bytes and all 529 instruction rows to that executable and its map.
Every row passes the strict i386 classification. Nine further adversarial
checks reject altered final code, header data, entry points and missing,
duplicate or displaced linker-map contributions.

Reproduction tools currently live in the isolated tooling tree:

```powershell
rtk proxy python tools/test-djgpp-startup-helpers-proof.py
rtk pwsh -NoProfile -File out/prove-startup-helpers-20261008.ps1
rtk pwsh -NoProfile -File out/audit-runtime-source-subset-230-20261008.ps1
rtk pwsh -NoProfile -File out/audit-frozen-current-policy-20261008.ps1
```

Run these from `out/isa-classifier-worktree-20261007`. One-time proof creation
refuses to overwrite its evidence directory; fresh regeneration requires a new
output path. Hash-bound verification can be repeated against retained evidence.
The tools preserve DJGPP source attribution and the primary archives' license
files. The synthetic COFF audit containers never replace executable code.

These are isolated mechanical acceptance results. Integration into the normal
automatic build gate and validation of each current build, the external
CWSDPMI provider, and complete renderer ownership remain pending.
They do not establish complete renderer or gameplay acceptance.
