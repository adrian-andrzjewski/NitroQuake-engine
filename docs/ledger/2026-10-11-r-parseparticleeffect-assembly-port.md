# `R_ParseParticleEffect` -> i486 assembly port (2026-10-11)

## Reference and assembly mapping

`src/renderer/r_part.c:R_ParseParticleEffect` is the C reference. The selectable
replacement is `src/renderer/r_parseparticleeffectasm.s:R_ParseParticleEffect`, enabled
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

`src/tests/bench486/bench486_parseparticleeffect.h` compares C and assembly state across 11
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

At the original parser-port checkpoint, the rendering source suite passed 94
tests and the build-profile suite passed its pinned i486/i386 flag checks. The
event-to-frame gap from that checkpoint is now closed by the paired scene below.

## Deterministic event-to-frame parity

`tools/render-scenarios-parseparticleeffect.json` injects one protocol
`svc_particle` packet (event type 18) into a deterministic 10-frame `demo2`
prefix. Its signed direction bytes exercise high-bit values, and count 255
exercises the original 1024-particle sentinel. `i486-parseparticleeffect-c.json`
and `i486-parseparticleeffect-asm.json` differ only in the parser selector; both
keep `R_RunParticleEffect` on the C implementation to isolate packet parsing.

The paired DOSBox-X run passed twice per profile on the configured 486 target.
Each run recorded exactly one `runParticleEffect` event at frame 10 with no
overflow. After four warmup checksums, all seven remaining frame checksums
matched exactly in both runs. The frame-10 320x200 indexed framebuffer matched
exactly: zero pixel-index differences across 64,000 pixels and zero palette
byte differences. The paired report is
`out/parseparticleeffect-event-parity-20261012/render-parity-result.json`.

Both executables passed the complete i486 audit. The C executable verified
208,939 relocated instructions and the assembly candidate verified 209,179;
each proof covered 235 installed runtime objects, startup code, and the 9,207
instruction CWSDPMI provider, with zero above-i486 instructions and zero
exemptions. The report records `isaAuditStatus=PASS` for both profiles.

The focused demo fixture suite passed 15 tests. The broader rendering test
file ran 99 tests; 98 passed, and one unrelated cumulative-selector assertion
failed because its profile expects `AliasProjectImplementation=c` while the
timedemo runner default is `asm`.

## Traceability and reproduction

| Original behavior | Assembly replacement | Correctness evidence |
|---|---|---|
| `R_ParseParticleEffect` in `src/renderer/r_part.c` | `R_ParseParticleEffect` in `src/renderer/r_parseparticleeffectasm.s` | `src/tests/bench486/bench486_parseparticleeffect.h`, invoked by `-benchparseparticleeffect` |
| `svc_particle` dispatch and parser event in `src/client/cl_parse.c` | The selectable parser call remains the common dispatch point | `tools/render-scenarios-parseparticleeffect.json`; exact event frame, checksums and framebuffer comparison |

`tools/test-rendering.py` guards the C reference, cumulative selector, fixture,
and focused runner contract. `tools/test-build-dos.py` checks the parser
selector's C and assembly flag sets. The strict emulator command above
reproduces the machine-code and 88-case state checks; `tools/render-parity-dos.ps1`
with the parser profiles and scenario manifest reproduces the event-to-frame
comparison.
