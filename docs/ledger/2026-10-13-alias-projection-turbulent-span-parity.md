# Alias projection and turbulent span assembly parity (2026-10-13)

Status: the direct alias projection and turbulent span fixtures pass with strict
i486 audits. This records parity evidence and promotes the matching selectors
in the cumulative candidate profile. The full renderer conversion remains
ongoing.

## Original-to-assembly traceability

| Reference behavior | Assembly implementation | Direct fixture |
|---|---|---|
| `src/renderer/r_alias.c::R_AliasProjectFinalVert` | `src/renderer/r_aliasa.s::R_AliasProjectFinalVert_asm486` | `-AliasProjectOnly` |
| `src/renderer/d_scan.c::D_DrawTurbulent8Span` C reference and setup/interpolation | `src/renderer/d_scana.s::D_DrawTurbulent8Span_asm486` | `-TurbulentScanOnly` |
| C turbulent span pixel loop | Selected i486 assembly span loop | `-TurbulentOnly` |

The alias routine retains Quake's x87 projection arithmetic and truncating
integer conversions. Its assembly groups the three truncating stores under one
x87 control-word transition per call. The turbulent routine retains the
fixed-point texture lookup and indexed-pixel write; `d_scana.s` has both the
ordinary store and the optional 486 `STOSB` store sequence. No rendering
algorithm or quality setting changed in this slice.

## Direct differential fixtures

All three fixtures completed with `486 benchmark correctness PASS`. Alias
projection and turbulent-span samples had matching C/assembly checksums; the
scan parity fixture reported zero mismatches. The alias projection cases were
far, near, and viewmodel; their C/assembly median seconds were `0.122609/0.113638`,
`0.122608/0.113639`, and `0.122609/0.113639`. Each of the three checksums
matched exactly.

The turbulent scan fixture compared the C setup/interpolation reference with
the assembly entry at 13 span lengths, six phases, and four x87 rounding modes.
It reported zero mismatches.

The turbulent span fixture used 50,000 iterations and five samples for each
length. Checksums matched at every length:

| Pixels | C median seconds | Assembly median seconds | Median difference |
|---:|---:|---:|---:|
| 4 | 0.225776 | 0.183910 | 18.543% |
| 8 | 0.423142 | 0.327449 | 22.615% |
| 16 | 0.817866 | 0.614521 | 24.863% |
| 64 | 3.186221 | 2.336959 | 26.654% |

These are subsystem microbenchmarks under DOSBox-X, not full-frame performance
or acceptance criteria. The measured rates are recorded as regression data.

## Strict i486 instruction evidence

Each fixture's `bench-result.json` reports `isaAuditStatus=PASS`. The turbulent
selector build's complete executable gate decoded 216,941 instructions: 216,940
i386-valid and one i486 instruction, with zero post-486, unknown, exempted, or
unenforced instructions. The audit also checked 378 exact object proofs, 369
source-bound linked contributions, 529 startup CODE rows, and the 9,207-
instruction provider with zero exemptions. Linked opcode verification matched
all 216,941 decoded instructions.

The canonical `i486-asm-selectable-current` profile now explicitly sets
`TurbulentImplementation=asm` and `AliasProjectImplementation=asm`. It has
104 selectors, all set to `asm`. This profile remains a cumulative candidate;
the standalone fixtures above do not establish full-renderer parity or complete
the remaining renderer conversion.

## Reproduction and scope

Run from the `quake` repository directory:

```powershell
rtk pwsh -NoProfile -File tools\bench-dos.ps1 -CpuTarget i486 `
  -AliasProjectOnly -AliasProjectImplementation asm -DrawingImplementation asm

rtk pwsh -NoProfile -File tools\bench-dos.ps1 -CpuTarget i486 `
  -TurbulentScanOnly -TurbulentImplementation asm `
  -TurbulentScanImplementation asm -DrawingImplementation asm

rtk pwsh -NoProfile -File tools\bench-dos.ps1 -CpuTarget i486 `
  -TurbulentOnly -TurbulentImplementation asm `
  -TurbulentScanImplementation asm -DrawingImplementation asm
```

Machine-readable reports are under `out\dos-bench-20261012-231835`,
`out\dos-bench-20261012-233148`, and `out\dos-bench-20261012-233214`.
