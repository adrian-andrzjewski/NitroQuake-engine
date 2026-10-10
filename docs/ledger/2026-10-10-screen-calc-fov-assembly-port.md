# `CalcFov` -> i486 assembly port (2026-10-10)

## Original C behavior and selector boundary

`src/screen.c:CalcFov` validates horizontal FOV in the inclusive range 1 to 179
degrees, computes the horizontal projection scale with `tan`, derives the
vertical angle with `atan`, and converts the result back to degrees. The live
caller is `SCR_CalcRefdef`, which uses this value to configure the view after a
screen or FOV change.

`ViewControlImplementation=asm` now selects
`src/screen_fovasm.s:CalcFov_asm486`. The default remains C. In BENCH builds the
original C body is retained as `CalcFov_C`, and its fatal-error call is replaced
with a capture hook so invalid values can be compared without terminating the
fixture process.

## Assembly mapping

The assembly keeps the reference's x87 operation order and binary32/binary64
constants: range comparisons, multiply by `1/360`, multiply by pi, `FPTAN`,
reverse divides for width and height, `FPATAN`, multiply by 360, and multiply
by `1/pi`. Its error path preserves the promoted double argument and resumes
the same calculation if the BENCH capture hook returns. It uses the 486 integer
ISA and 387 x87 instructions, makes no C math-helper calls, and leaves the
caller's x87 control word unchanged.

## Direct C/assembly and ABI fixture

`src/bench486_viewcontrol.h:Bench486CalcFovCases` checks 17 directed FOV and
dimension inputs under 12 x87 precision/rounding control words (204 paired
calls). It compares result bits, x87 status and control state, captured error
count/message/value, and the assembly call probe's preserved registers, stack,
x87 stack, and canary. All 204 comparisons passed with zero failures in the
i486 DOSBox-X run. The full existing view-control fixture also passed 18,176
paired calls, including 8,192 sequence calls, plus its guard checks.

## i486 instruction evidence

The strict BENCH build decoded 175,381 source-object instructions and 213,678
instructions from linked runtime object contributions. The final relocated
`qbench.exe` audit verified 213,678 instructions across 370 source-bound code
ranges. The only instructions above 386 were one 486 instruction; there were no
instructions above i486, unknown instructions, undecoded bytes, or exemptions.
The same build passed the final-byte startup audit (1,660 loaded bytes, 529
CODE rows, 489 instructions), the primary DJASM host-helper proof, and the
CWSDPMI provider audit (9,207 instructions and one runtime branch variant), all
with zero exemptions.

## Paired framebuffer evidence

The short `demo2-svcDamage-event` scene ran once under the C and assembly
view-control profiles. Each run produced 11 frame checksums and one required
damage event at frame 10. All seven post-warmup checksum comparisons matched;
the captured 320x200 images matched all 64,000 pixel indices and every palette
byte. Both final framebuffer checksums were `3162740428`. The paired run used
`-VisualParityOnly` to avoid repeating the already-passed strict audit; the
strict executable and runtime evidence above came from the separate
`ViewControlImplementation=asm` BENCH build.

## CalcFov traceability and reproduction

| Reference behavior | Assembly implementation | Correctness evidence | Compatibility evidence |
| --- | --- | --- | --- |
| `src/screen.c:CalcFov`; called by `SCR_CalcRefdef` | `src/screen_fovasm.s:CalcFov_asm486` | `src/bench486_viewcontrol.h:Bench486CalcFovCases`; exact `demo2-svcDamage-event` profile pair | Strict i486 BENCH executable, runtime-object, startup and CWSDPMI audits |

From `quake/`, reproduce the strict assembly/ABI fixture and the short exact
frame comparison with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -ViewControlImplementation asm -ViewControlOnly -NoBootstrap
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -ReferenceProfile tools/renderer-profiles/i486-viewcontrol-c.json -CandidateProfile tools/renderer-profiles/i486-viewcontrol-asm.json -ScenarioFile tools/render-scenarios-svcdamage.json -Scenario demo2-svcDamage-event -RunsOverride 1 -CpuTarget i486 -VisualParityOnly -NoBootstrap
rtk python tools/test-rendering.py
rtk python tools/test-build-dos.py
```

This accepts the `CalcFov` helper slice only. Other renderer ownership,
representative full-scene coverage, long-running gameplay stability and the
remaining C renderer paths are still open.
