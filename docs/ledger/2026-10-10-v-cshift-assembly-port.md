# `V_cshift_f` -> i486 assembly port (2026-10-10)

## Original `v_cshift` command semantics and argument stores

`src/view.c:V_cshift_f` is the `v_cshift` console handler. It reads command
arguments 1 through 4 with `Cmd_Argv`, converts each with `atoi`, then stores
the three destination-color integers and percent into `cshift_empty`. The
handler does not clamp these values. The C routine remains the reference
implementation in BENCH486 builds and the default implementation outside the
assembly-selected profile.

`src/v_paletteasm.s:V_cshift_f_asm486` preserves that call and store order using
ordinary 386-compatible `push`, `call`, `add`, `mov`, and `ret` instructions.
`PaletteImplementation=asm` exports the public `V_cshift_f` entry from
assembly. The shared palette selector avoids adding a separate profile for
this closely related color-shift command. Compile-time layout assertions pin
the 32-bit integer and color-shift field offsets used by the assembly.

## Seven token cases and contents shift

`src/bench486_palette.h:Bench486CshiftCases` uses real
`Cmd_TokenizeString` inputs to cover signed decimal values, `atoi` numeric
prefix behavior, malformed values, missing arguments, ignored extra arguments,
representable integer extremes, and no arguments. It compares the complete
`cshift_empty` record for the C oracle, assembly routine, and selected public
entry, then compares the resulting full client state after each implementation
updates the empty-contents shift. All calls run through the ABI checker. The
focused DOSBox-X run passed all seven cases with zero state or ABI failures.
This checks shift-state behavior; it is not a dedicated framebuffer pair.

## This profile's strict i486 audit

The `i486` palette-assembly benchmark passed strict audits for 207,207 linked
instructions: 207,206 were classified as i386 and one as i486, with zero
above-i486, unknown, undecoded, or exempt instructions. All 363 linked
source-bound contributions mapped successfully. The startup image passed its
529-code-row audit, and the maintained CWSDPMI provider passed its
9,207-instruction proof with zero exemptions. DOSBox-X exited with code zero
and reported `ISA audit: PASS`.

## V_cshift traceability and reproduction

| Reference behavior | Assembly implementation | Correctness evidence | Compatibility evidence |
| --- | --- | --- | --- |
| `src/view.c:V_cshift_f` | `src/v_paletteasm.s:V_cshift_f_asm486` | `src/bench486_palette.h:Bench486CshiftCases`; complete shift state and ABI across seven command cases | Strict linked i486 executable, startup, and CWSDPMI audits |

From `quake/`, reproduce the focused state, ABI, palette, and instruction-set
checks with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -PaletteImplementation asm -PaletteOnly -NoBootstrap
```

The routine is assembly-backed when selected; the C path remains the default.
This accepts the command and content-shift state slice only. Full renderer
profile parity, `V_Init`, initialization and indirect dependencies, and wider
view/screen ownership remain open.
