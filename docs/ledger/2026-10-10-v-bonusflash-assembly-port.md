# `V_BonusFlash_f` -> i486 assembly port (2026-10-10)

## Original command behavior and four assembly stores

`src/client/view.c:V_BonusFlash_f` is the command handler registered as `bf`. The
original routine writes RGB `(215, 186, 69)` and percent `50` into
`cl.cshifts[CSHIFT_BONUS]`. The C implementation remains the default and is
retained as `V_BonusFlash_C` in BENCH486 builds.

`src/client/v_paletteasm.s:V_BonusFlash_asm486` performs the four corresponding
32-bit stores. `PaletteImplementation=asm` exports the public
`V_BonusFlash_f` entry from assembly; the C-reference profile keeps the
original C entry. `src/renderer/asm_palette.h` names the shift index and field offsets,
and `view.c` compile-time assertions pin the client shift array, `cshift_t`
layout, `CSHIFT_BONUS`, and destination-color offset before those constants
are used. The handler makes no calls and leaves the x87 state untouched.

## 256-pattern full-state and ABI fixture

`src/tests/bench486/bench486_palette.h:Bench486BonusFlashCases` initializes all bytes of the
client state to 256 deterministic patterns. For each pattern it compares the
C oracle, the assembly routine, and the selected public command entry against
an expected full client-state image in which only the four bonus-shift fields
change. All three calls run through the ABI checker. DOSBox-X reported 256
patterns and zero state or ABI failures.

## Exact palette-transition differential

The longer palette sequence now invokes the C or assembly bonus handler at
each deterministic bonus transition before continuing through the original
palette update and decay logic. C and assembly shift state, callback counts,
all 768 produced palette bytes, guards, and ABI state are compared exactly.
The focused `PaletteOnly` run passed 480 direct cases and 9,728 sequential
palette frames with zero failures. This exact palette comparison is the
observable color-shift check; the handler itself changes palette state rather
than indexed framebuffer memory.

## Strict i486 executable and provider evidence

The non-diagnostic `i486` benchmark build passed strict audits for all 207,574
linked instructions: 207,573 were classified as i386 and one as i486, with
zero above-i486, unknown, undecoded, or exempt instructions. All 363 linked
source-bound contributions mapped successfully. The final startup image
passed its 529-code-row audit, and the maintained CWSDPMI provider passed its
9,207-instruction proof with zero exemptions. The DOSBox-X run exited with
code zero and reported `ISA audit: PASS`.

## Reference-to-assembly traceability and reproduction

| Reference behavior | Assembly implementation | Correctness evidence | Compatibility evidence |
| --- | --- | --- | --- |
| `src/client/view.c:V_BonusFlash_f` | `src/client/v_paletteasm.s:V_BonusFlash_asm486` | `src/tests/bench486/bench486_palette.h:Bench486BonusFlashCases` and palette output sequence | Strict linked i486 executable, startup, and CWSDPMI audits |

From `quake/`, reproduce the focused state, ABI, and palette-output fixture
with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -PaletteImplementation asm -PaletteOnly -NoBootstrap
```

The routine is assembly-backed when selected; the C path remains the default.
This accepts the bonus-flash state and palette transition only. Full renderer
profile parity, remaining view initialization/command helpers, and broader
gameplay coverage remain open.
