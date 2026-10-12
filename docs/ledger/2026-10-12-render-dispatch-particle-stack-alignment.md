# Render-dispatch particle wrapper call-frame alignment (2026-10-12)

## C reference and assembly boundary

The selectable C oracle for the particle list update and draw loop is
`R_DrawParticles_C` in `src/r_part.c`. The renderer entry `R_DrawParticles`
wraps that behavior with the particle start/end hooks and, in PROFILE486
builds, particle and gib-trail counters plus elapsed-time accounting. When
render dispatch and particle update assembly are selected, the wrapper lives
in `src/r_renderdispatchasm.s`; the loop implementation is
`R_DrawParticles_asm486` in `src/asm486_experiments.s`, which calls the
existing `D_DrawParticle` backend.

This slice corrects the wrapper's outgoing call alignment. It does not change
particle equations, iteration order, lifetime checks, ramp selection, or
rasterization.

## Call-frame contract

In PROFILE486 builds, the wrapper keeps profiling locals at fixed EBP-relative
offsets, aligns ESP down to 16 bytes before outgoing calls, and includes eight
bytes of padding before passing six argument words to the particle loop. The
call cleanup accounts for that padding and all six arguments. `leave` restores
the caller's stack from EBP.

In ordinary builds, the wrapper reserves twelve bytes before its no-argument
start hook. It then passes the four original argument words to the assembly
loop and removes those arguments plus the reserved stack space. The end hook
uses the same aligned call frame. These changes keep the cdecl argument order
and preserve the existing renderer state while satisfying the selected
DJGPP/GCC call-site alignment convention.

## Tracked integration profile and exact parity

`tools/renderer-profiles/i486-frame-particle-dispatch-integration.json`
selects assembly for FrameControl, RenderDispatch, ParticleUpdate, and
ParticleDraw. The other 82 selector entries remain on the C/reference or
control paths. `tools/render-scenarios-i486-particle-dispatch-integration.json`
pins the VGA demo, 969 timedemo frames, checksum `1047377823`, capture frame
169, the fixed host timestep, and transient-notification suppression.

The strict paired run at
`out/frame-particle-dispatch-repeatable-parity-20261012/render-parity-result.json`
passed under the DOSBox-X i486 profile. The C reference and assembly candidate
had the same source-tree fingerprint. All 964 post-warmup frame checksums
matched. Their 320x200 indexed framebuffers at frame 169 matched exactly:
zero differing pixel indices across 64,000 pixels and zero palette-byte
mismatches. Both runs also recorded the same particle and damage event frames.

| Profile | Frames | Timedemo seconds | FPS |
|---|---:|---:|---:|
| C reference | 969 | 79.761379 | 12.148737 |
| Four-selector assembly mix | 969 | 79.766264 | 12.147993 |

The measured difference is negligible and is not a performance claim.

## i486 instruction and runtime evidence

The candidate completed the strict source-bound build and executable audit.
The relocated linked image contained 213,893 decoded instructions: 213,892
i386 and one i486, with no later-generation, unknown, or exempt instructions.
The startup audit covered 529 code rows. The CWSDPMI provider proof covered
9,207 instructions and reported no later-generation instructions or
exemptions. The timedemo report records the i486 compatibility gate as PASS.

This is an emulator run using the project's i486 DOSBox-X configuration; it
does not establish execution on physical 486 hardware. It also covers this
four-selector integration profile only. The broader 102-assembly-selector
profile still has an unresolved startup/integration failure and is not
accepted by this evidence.

## Traceability and reproduction

| Original reference | Assembly replacement or adapter | Evidence |
|---|---|---|
| `src/r_part.c::R_DrawParticles_C` | `src/asm486_experiments.s::R_DrawParticles_asm486` | Exact deterministic scene pair and strict executable audit |
| `src/r_part.c::R_DrawParticles` call wrapper | `src/r_renderdispatchasm.s::R_DrawParticles` | Four-selector profile integration and exact scene pair |

From the Quake repository root, run with a fresh output path:

    $parityRoot = "out/frame-particle-dispatch-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 `
      -ReferenceProfile tools/renderer-profiles/i486-c-reference.json `
      -CandidateProfile tools/renderer-profiles/i486-frame-particle-dispatch-integration.json `
      -Scenario demo1-vga-full `
      -ScenarioFile tools/render-scenarios-i486-particle-dispatch-integration.json `
      -OutputRoot $parityRoot -CpuTarget i486 -NoBootstrap -RunsOverride 1 -TimeoutSeconds 600
