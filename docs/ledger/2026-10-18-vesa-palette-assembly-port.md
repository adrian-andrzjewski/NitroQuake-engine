# VESA palette conversion i486 assembly port (2026-10-18)

## Scope and selector

`VesaPaletteImplementation=asm` selects `src/vid_vesapaletteasm.s` in the
default i486 release profile. The assembly converts all 256 RGB palette entries
to the VESA four-byte layout: blue, green, red, and a zero filler byte, with
each color channel reduced from eight bits to six by shifting right two bits.
`VID_SetVESAPalette` still owns mode-independent state and the DOS VESA BIOS
call in C. The C conversion routine remains the reference implementation in
the C-reference and BENCH profiles.

## Direct C/assembly parity

The focused fixture runs four deterministic source patterns over all 256
entries. It checks exact converted bytes, channel order, filler bytes, source
and destination canaries, and the i486 callee-saved register ABI.

```text
VESA C/ASM palette conversion and ABI PASS failure mask 0x0
486 benchmark correctness PASS
```

Run record: `out/dos-bench-20261018-023024/bench-result.json`; the selected
BENCH manifest records `VesaPaletteImplementation=asm-fixture`.

## Strict i486 verification

The focused BENCH gate passed 244,492 project instructions, 282,789 linked
instructions, and 282,789 relocated instructions, with zero above-i486 or
unknown instructions, exemptions, or skipped bytes. Startup validation covered
529 CODE rows and the provider proof covered 9,207 instructions.

The non-BENCH release manifest selects `VesaPaletteImplementation=asm`,
`memoryImplementation=asm`, and `surfaceCacheImplementation=asm`. Its complete
executable gate passed for 163,675 relocated instructions, 529 startup CODE
rows, and 9,207 provider instructions, with zero exemptions or above-i486/
unknown instructions.

## Scope limits and reproduction

This port owns only the palette conversion loop. VESA discovery, wait probing,
mode changes, and the BIOS call that writes the hardware palette remain C-owned.
The fixture reports neither FPS nor full-scene parity.

Reproduce the direct fixture and strict BENCH gate with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -VesaPaletteOnly -VesaPaletteImplementation asm-fixture -CpuTarget i486 -TimeoutSeconds 180
```

Reproduce the non-BENCH release gate with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 -CpuTarget i486
```
