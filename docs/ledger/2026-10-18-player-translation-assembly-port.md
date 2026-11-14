# Player-color translation i486 assembly port (2026-10-18)

## Scope and selector

`PlayerTranslationImplementation=asm` selects `src/client/menu_translationasm.s` in
the default i486 profile. The assembly owns identity-table generation, the
shirt/pants palette-range replacement, and the 64-row scoreboard translation
loop shared by `M_BuildTranslationTable` and `CL_NewTranslation`. The latter
keeps its C state and slot-validation adapter. The C implementations remain
available in the C-reference profile and as BENCH oracles.

The kernel uses 486-compatible integer/string instructions only. Compile-time
checks pin the palette range offsets and `VID_GRADES` against the C headers.

## Direct C/assembly parity

The DOSBox-X fixture compares every legal shirt/pants pair (16 values each):
256 `M_BuildTranslationTable` cases and 256 `CL_NewTranslation` cases. It checks
the generated identity and menu tables, all 64 scoreboard colormap rows, stack
and callee-saved register behavior, and source/scoreboard canaries.

```text
player translation C/ASM tables and ABI PASS failure mask 0x0
486 benchmark correctness PASS
```

Run record: `out/dos-bench-20261018-014755/bench-result.json`.

## Strict i486 verification

The focused BENCH build passed project-object, linked-object, relocated
executable, startup, CRT-helper, and CWSDPMI provider gates. It verified
244,043 project instructions, 282,340 linked instructions, and 282,340
relocated instructions, with zero above-i486 or unknown instructions,
exemptions, or skipped bytes. Startup validation covered 529 CODE rows; the
provider proof covered 9,207 instructions.

The non-BENCH i486 release manifest selects
`playerTranslationImplementation=asm`. Its complete executable gate passed for
163,666 relocated instructions, 529 startup CODE rows, and 9,207 provider
instructions, with zero exemptions or above-i486/unknown instructions.

## Scope limits and reproduction

This slice only updates player-color tables when menu colors change or a server
color update arrives. The fixture is correctness-focused and reports neither
full-scene parity nor FPS. Broader screen, menu, status-bar, video, and renderer
ownership gaps remain open.

Reproduce the direct fixture and strict BENCH gate with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -MenuTranslationOnly -PlayerTranslationImplementation asm-fixture -CpuTarget i486 -TimeoutSeconds 180
```

Reproduce the non-BENCH release gate with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 -CpuTarget i486
```

The repository-wide `tools/test-build-dos.py` guard still reports 25
path-normalization and selector-isolation diagnostics; it reported no
player-translation-specific selector failures. The focused build, parity
fixture, and release manifest independently verify this slice.
