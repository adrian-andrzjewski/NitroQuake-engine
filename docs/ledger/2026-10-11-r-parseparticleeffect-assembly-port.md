# `R_ParseParticleEffect` -> i486 assembly port (2026-10-11)

## Reference and assembly mapping

`src/r_part.c:R_ParseParticleEffect` is the C reference. The selectable
replacement is `src/r_parseparticleeffectasm.s:R_ParseParticleEffect`, enabled
by `ParseParticleEffectImplementation=asm`. The normal build default remains
C; the cumulative opt-in assembly profile now includes this selector.

The assembly preserves the original helper order: three `MSG_ReadCoord` calls,
three signed `MSG_ReadChar` calls, two `MSG_ReadByte` calls, then
`R_RunParticleEffect`. It scales signed direction bytes by the same exact
binary `1/16` value and maps the original count sentinel 255 to 1024. Message
read-count and bad-read behavior remains owned by the existing message helpers.
The assembly uses `.arch i486` and `.arch .387`, leaves the caller's x87 control
word unchanged, and returns with an empty x87 stack.

## Direct C/assembly fixture

`src/bench486_parseparticleeffect.h` compares C and assembly state across 11
complete packet cases and all 11 packet truncation lengths, with four x87
rounding modes: 88 exact pairs. It checks the message cursor and error state,
signed coordinates/directions, count-sentinel behavior, deterministic random
calls, emitted particles, pool links and guard words, x87 control/status state,
and the probed calling convention. The `ParseParticleEffectOnly` runner pins
`RunParticleEffectImplementation=c`, so both parser paths use the same C
particle emitter and the fixture isolates packet decoding.

## Strict 486DX+x87 executable evidence

The repeatable run was:

```powershell
rtk pwsh -NoProfile -File tools\bench-dos.ps1 -CpuTarget i486 `
  -ParseParticleEffectImplementation asm `
  -RunParticleEffectImplementation c -ParseParticleEffectOnly
```

The generated DOSBox-X profile used `cputype=486` and `fpu=387`. The focused
fixture passed all 88 pairs with zero mismatches. The strict build audited 142
project objects (172,156 instructions), 377 project/runtime objects (210,453
instructions), and 210,453 linked executable opcodes across 368 text ranges.
All three scans found zero above-i486 instructions, unknown decodings, or
exemptions; the executable mapping had no undecoded or relocation-data bytes.
Startup validation covered 1,660 loaded bytes and 529 CODE rows, and the
CWSDPMI provider proof covered 9,207 instructions. The complete executable ISA
gate passed. The build manifest records `CpuTarget=i486`, parser assembly,
C particle emitter, source-bound ISA proof, and `isaAuditStatus=PASS`.

The rendering source suite passed 94 tests after adding the parser profile
regression, and the build-profile suite passed its pinned i486/i386 flag checks.
The parser fixture is function/state parity rather than a framebuffer comparison.
Its particle-event contribution still needs full paired gameplay-scene
coverage, and broader renderer parity and ownership remain open.

## Traceability and reproduction

| Original behavior | Assembly replacement | Correctness evidence |
|---|---|---|
| `R_ParseParticleEffect` in `src/r_part.c` | `R_ParseParticleEffect` in `src/r_parseparticleeffectasm.s` | `src/bench486_parseparticleeffect.h`, invoked by `-benchparseparticleeffect` |

`tools/test-rendering.py` guards the C reference, cumulative selector, fixture,
and focused runner contract. `tools/test-build-dos.py` checks the parser
selector's C and assembly flag sets. The strict emulator command above
reproduces the machine-code and 88-case state checks.
