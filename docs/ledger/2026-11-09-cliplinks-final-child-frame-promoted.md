# Reuse the final collision area-child frame (2026-11-09)

## Change and invariant

SV_ClipToLinks reuses its current assembly frame when descending into child 1,
whose only continuation was a return. Child 0 recursion and traversal order are
unchanged. EAX carries the next node and EBX the existing clip. The per-node
entry refreshes current node, clip pointer, x87 control word and entity-list
successor exactly as before. Each logical entry still increments the BENCH
counter. Caller argument slots, entity filters and floating-point operations
are untouched. The root invocation restores its original saved registers once.

## Native correctness and compatibility

Only sv_cliptolinks_asm.inc differs across 435 normalized C/H/S/INC sources
against 682998a8a3eb. Its SHA-256 is
`bf1bc57fd26ef03d646ab0945789b0af4d78502a46f8bad49e3f9f4b195fc015`.

The native old-assembly/new-assembly fixture passes 6,912 cases: balanced trees
and deep left/right stress trees, 96 filtering/trace scenarios, twelve x87 modes
and empty/two-value caller FPU stacks. It compares the complete clip, helper
call order and bounds, error messages, node counters, saved EBP/EBX/ESI/EDI,
ESP, DF, CW, TOP, tag and preloaded values. Trace helpers are explicit native
stubs; actual local-game tests complement this focused control-flow evidence.
Both native assembly objects use the BENCH486 and ASM486_CLIP_TO_LINKS defines.

The isolated BENCH486 build passes complete i486 auditing: 316,308 relocated
instructions, 529 startup rows and 9,207 provider instructions, zero above-target,
unknown or exempt instructions. No new ISA, runtime allocation or cache is added.

## Independent matched timing screen

Three alternating e1m2-silent pairs measure 256 local-server frames after 64
warm-up frames at 320x200, fixed simulation step from startup, god/forward/fire,
the same DOSBox-X 486/x87 fixed-33445 profile, PAKs and maintained provider.
Profiling, per-frame FPS and diagnostic logging are disabled. All six captures
match final framebuffer/selected simulation checksums and full QuakeC counts.

Control samples: 11.688973, 11.688972, 11.688967 seconds.
Candidate samples: 11.683053, 11.683049, 11.683044 seconds.
Median FPS: 21.900985 -> 21.912088; pooled FPS gain **+0.050689%**.
Paired gains: +0.050672%, +0.050697%, +0.050697%. This population is one scripted
map/device case; the broader independent matrix is recorded by the suite.

## Acceptance and integration boundary

Accept one final-child frame-reuse optimization attempt for combined integration.
Broader map/audio comparisons and all final combined replay, normal-release,
compatibility and matched runtime gates must pass before main promotion. The
benchmark suite records them in docs/I486-COLLISION-OPTIMIZATION-20261109.md.
The two independent deltas are not added to claim a measured combined gain.

Native evidence is benchmarks/out/cliplinks-tail-native-fixture-20261109/;
screen evidence is benchmarks/out/cliplinks-tail-screen-20261109/. The audited
screen session SHA-256 is
`834F308BD1CA8694C0C440C923A6D9F833A5D36CAED02063646FE55CF64386DF`.
Stack traffic is removed by construction; no physical 486 cycle/cache or FPS
claim follows from the emulator measurement alone. Build identity is automatic.
