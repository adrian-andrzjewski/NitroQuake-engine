# `V_ParseDamage` -> i486 assembly port (2026-10-10)

## Reference behavior and assembly mapping

`src/view.c:V_ParseDamage_C` remains the reference implementation. It reads the
armor and blood bytes plus three damage coordinates, computes and caps the
damage amount, updates the damage color shift and face animation time, then
normalizes the source direction and derives the view kick from the current
view-entity basis. The C implementation remains selectable and is the default.

`src/v_damageparse.s:V_ParseDamage_asm486` implements the same sequence. The
`DamageParseImplementation` selector chooses it through the public
`V_ParseDamage` wrapper. `src/asm_vdamage.h` pins the accessed structure sizes
and offsets with C compile-time checks, including the double-sized client
clock, damage `cshift_t` fields, entity origin and angles, and cvar value.

The routine uses cdecl, preserves EBX/ESI/EDI/EBP, balances the x87 stack, and
calls the existing message and math helpers. Its integer path uses 386
instructions and its floating-point path uses 387 instructions. A temporary
x87 control word makes the C float-to-integer conversion truncate regardless
of the caller's rounding mode, then restores the original control word. The
damage direction dot products retain the live x87 precision and multiply order
observed in the reference compiler output; this avoids one-ULP differences in
the stored kick values.

## Direct C/assembly fixture

`src/bench486_vdamage.h` compares the original C function and assembly with
guarded client, entity, parser, and message state. It checks state bytes,
message cursor/error behavior, guards, register preservation, and x87 control
word and stack state. Nine directed inputs, 64 armor/blood combinations, and
eight truncated-message lengths run under all four x87 rounding modes for 324
paired comparisons. The diagnostic DOSBox-X 486 run passed all 324 with zero
failures. That direct fixture run used the explicitly diagnostic
`-SkipIsaAudit` build path; the strict instruction proof below comes from the
separate paired-profile builds.

## Paired rendered-frame parity

`tools/render-scenarios-svcdamage.json` describes a deterministic short `demo2`
prefix. Its fixture builder injects one fixed `svc_damage` packet, and the
timedemo recorder requires exactly one event at rendered frame 10 with no
overflow. The C and assembly profiles each passed two runs. Each produced 11
frame checksums; after ignoring the four startup records, all seven compared
records matched exactly. Both captured 320x200 images matched at all 64,000
pixel indices and all palette bytes. The final framebuffer checksum was
`3162740428`; the event was recorded once at frame 10 in each profile with
zero overflow. The short run measured 12.39 fps for each profile, recorded as
regression context rather than a representative performance benchmark.

The paired report recorded `pass: true` and a matching source-tree fingerprint
`3CAF64F9D800B2CB61A9367842A9AEF9374196D57462E68C10089CB03E16D840`. Its
temporary files were written beneath
`out/render-parity-vparsedamage-20261010-1`; those validation outputs are
removed after the recorded checks to conserve disk space.

## i486 machine-code evidence

The strict C-reference profile decoded 167,457 source-object instructions and
205,754 linked/runtime instructions. The strict assembly profile decoded
168,311 source-object instructions and 206,608 linked/runtime instructions.
Both profiles reported zero instructions above i486, unknown instructions,
undecoded linked bytes, or instruction exemptions. The actual linked
executables mapped all 363 code contributions to source-bound ranges. The
startup image's 529 code rows, its 489 executed instructions, the 33 `sbrk16`
instructions, the 7 `exit16` instructions, and the 9,207-instruction CWSDPMI
provider proof also passed with zero exemptions. These audits were bound to
the same source-tree fingerprint as the paired capture.

## Traceability and reproduction

| Reference behavior | Assembly implementation | Correctness evidence | Compatibility evidence |
| --- | --- | --- | --- |
| `src/view.c:V_ParseDamage_C` | `src/v_damageparse.s:V_ParseDamage_asm486` | `src/bench486_vdamage.h`; paired `demo2-svcDamage-event` | Strict C and ASM i486 profile builds, including linked executable, startup, and CWSDPMI proofs |

From `quake/`, reproduce the direct state fixture and paired rendering run
with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -DamageParseImplementation asm -DamageParseOnly -NoBootstrap
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -ReferenceProfile tools/renderer-profiles/i486-vparsedamage-c.json -CandidateProfile tools/renderer-profiles/i486-vparsedamage-asm.json -ScenarioFile tools/render-scenarios-svcdamage.json -Scenario demo2-svcDamage-event -CpuTarget i486 -NoBootstrap
```

The assembly selector remains opt-in and C remains the default. This accepts
the `V_ParseDamage` slice only; full-renderer ownership, broad gameplay parity,
long-running stability, and the remaining renderer subsystems are still open.
