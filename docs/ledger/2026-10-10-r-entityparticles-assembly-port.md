# `R_EntityParticles` -> i486 assembly port (2026-10-10)

## Reference behavior and assembly mapping

`src/r_part.c:R_EntityParticles` lazily initializes 162 three-axis angular
velocities with 486 calls to `rand()`, then walks the 162 vertex normals. For
each normal it computes two angles, their sine/cosine values, and the forward
vector. It stops immediately if the free particle list is empty; otherwise it
moves one node to the active-list head, assigns `die = (float)cl.time + 0.01`,
color `0x6f`, type `pt_explode`, and the three source-ordered origin sums.

`src/r_entityparticlesasm.s:R_EntityParticles_asm486` implements that loop and
is selected by `EntityParticlesImplementation=asm`; C remains the default and
the differential oracle. The assembly keeps the reference x87 sine/cosine and
intermediate ordering through the final single-precision origin stores. It
uses cdecl, preserves ESI and EBX, and declares `.arch i486` plus `.arch .387`.
The FPU requirement means this port targets 486DX-class machines; it does not
claim support for FPU-less 486SX systems.

## Direct C/assembly fixture

`src/bench486_entityparticles.h` builds guarded particle/entity fixtures and
compares all observable state after the C and assembly calls: complete particle
storage and padding, free/active list pointers and order, velocity-table bytes,
random-call count and continuation, entity/input preservation, stack/register
preservation, and guard regions. Seven cases exercise initialization, warm
calls, changing time and beam length, empty and exhausted lists, and scripted
values spanning signed and byte-boundary inputs. The DOSBox-X i486 run passed
all 7 cases across cold and two warm calls (21 paired calls), with exact state
and RNG continuation and zero failures. Its report is
`out/dos-bench-20261010-011023/bench-result.json`.

## Paired rendered-frame parity

`tools/render-scenarios-entityparticles.json` uses a short `demo2` prefix and
requests one deterministic `EF_BRIGHTFIELD` entity-particle dispatch at
rendered frame 10. The benchmark hook applies it to the first model-backed
entity updated that frame, then restores its network-visible effects. Both
i486 profiles passed twice.
Each run emitted 11 checksum records with zero overflow; the event was recorded
once at frame 10 in both C and assembly. The harness excludes the first four
startup checksum records and compared the remaining seven exactly in every
run. Both 320x200 captures matched across all 64,000 palette indices and every
palette byte. The final framebuffer checksum was `2152468316`; the measured
median was 12.29 fps for each profile, recorded only as regression context.

The pair report is `out/render-parity-20261010-012940/render-parity-result.json`.
It records `pass: true`, exact checksum-stream and image parity, the expected
event frame in both profiles, and a matching source-tree fingerprint
`5EFF198C43A026C3D4C3E2CC3D655B78841E4488D00D1A7626BE1E0E8ABC5BF9`.

## i486 machine-code evidence

The source-bound benchmark C executable passed the relocated-code gate at
`out/profile-1981d7617a5f4c91/isa-qbench/relocated-20261010-031931436/strict-isa.json`:
205,229 instructions, of which 205,228 are i386 and one is i486; there are no
unknown, post-i486, or exempt instructions. The assembly executable passed at
`out/profile-efe6d40ea2c2064c/isa-qbench/relocated-20261010-030639437/strict-isa.json`:
205,872 instructions, of which 205,871 are i386 and one is i486, again with no
unknown, post-i486, or exempt instructions. Both benchmark build manifests
bind these audits to the tested source snapshot. The build also verified the
529-instruction startup image and the maintained 9,207-instruction DPMI
provider with zero ISA exemptions.

## Traceability and reproduction

| Reference behavior | Assembly implementation | Correctness evidence | Compatibility evidence |
| --- | --- | --- | --- |
| `src/r_part.c:R_EntityParticles` | `src/r_entityparticlesasm.s:R_EntityParticles_asm486` | `src/bench486_entityparticles.h`; paired `demo2-entityparticles-event` | Source-bound C/assembly qbench strict i486 reports above |

From `quake/`, reproduce the direct state/RNG fixture and paired rendering run
with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -EntityParticlesImplementation asm -EntityParticlesOnly -NoBootstrap
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -ReferenceProfile tools/renderer-profiles/i486-entityparticles-c.json -CandidateProfile tools/renderer-profiles/i486-entityparticles-asm.json -ScenarioFile tools/render-scenarios-entityparticles.json -Scenario demo2-entityparticles-event -CpuTarget i486 -NoBootstrap
```

The host fixture, selector/profile contract, event-record parser, and paired
report checks are registered in `tools/run-tests.ps1`. The whole-renderer
migration remains in progress; this accepts the `R_EntityParticles` leaf only.
