# VESA default-mode selection i486 assembly port (2026-10-18)

## Scope and selector

`VesaDefaultModeImplementation=asm` selects
`src/video/vid_vesadefaultmodeasm.s` in the default i486 release profile. The assembly
owns the linked mode-list scan: it ignores modes that do not use the VESA mode
initializer or are not 320x200, prefers the first linear candidate, and keeps
the first banked candidate as fallback. `VID_ExtraDefaultMode` remains a thin C
adapter that supplies the mode list and initializer address. The C scan remains
available in the C-reference and BENCH profiles.

Compile-time layout assertions pin the `vmode_t` and `vesa_info_t` fields read
by assembly. The routine uses integer comparisons and preserves the i486
callee-saved register set.

## Direct C/assembly parity

The DOSBox-X fixture compares six synthetic linked mode lists against the C
oracle. The cases cover an empty list, a non-VESA mode, size and setter filters,
first-banked fallback, later linear preference, and a linear candidate at index
zero. It checks returned mode indices, unchanged input/canary data, and the ABI.

```text
VESA default-mode selection and ABI PASS failure mask 0x0
486 benchmark correctness PASS
```

Run record: `out/dos-bench-20261018-032602/bench-result.json`; the selected
BENCH manifest records `VesaDefaultModeImplementation=asm-fixture`.

## Strict i486 verification

The focused BENCH gate passed 244,238 project instructions, 282,535 linked
instructions, and 282,535 relocated instructions, with zero above-i486 or
unknown instructions, exemptions, or skipped bytes. Startup validation covered
529 CODE rows and the provider proof covered 9,207 instructions.

The non-BENCH release manifest selects `VesaDefaultModeImplementation=asm`.
Its complete executable gate passed for 163,627 relocated instructions, 529
startup CODE rows, and 9,207 provider instructions, with zero exemptions or
above-i486/unknown instructions.

## Scope limits and reproduction

This port owns candidate selection only. VESA mode-info decoding, mode-list
discovery, and BIOS/DPMI mode-setting operations remain C-owned. The fixture
reports neither FPS nor full-scene parity.

Reproduce the direct fixture and strict BENCH gate with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -VesaDefaultModeOnly -VesaDefaultModeImplementation asm-fixture -CpuTarget i486 -TimeoutSeconds 180
```

Reproduce the non-BENCH release gate with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 -CpuTarget i486
```
