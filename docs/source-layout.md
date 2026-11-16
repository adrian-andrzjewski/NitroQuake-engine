# Source layout and ownership

Production sources are grouped under `src/` by subsystem: `assets`, `audio`,
`client`, `collision`, `core`, `memory`, `network`, `platform/dos`, `renderer`,
`server`, and `video`. Assembly implementations stay beside their owning
subsystem; C reference implementations and their selectors remain independent.
The former large `asm486_experiments.s` unit is split into renderer units for
alias, BSP, edges, lighting, memory, particles, rasterization, sky and warp,
sprite rendering, surface cache, surface drawing, and world rendering, plus a
collision unit.

The public headers `render.h`, `vid.h`, `zone.h`, `client.h`, and `server.h`
define the renderer, video, memory, client, and server entry points. The narrow
`host.h` exposes startup parameters, host lifecycle and frame entry points,
host timing, and shared palette state to other subsystems.
Subsystem headers use `q_types.h` for primitive engine types and `q_shared.h`
for limits shared across wire, client, model, and sound interfaces. `common.h`
selects game-side BSP declarations for engine translation units. `quakedef.h`
remains available as a compatibility umbrella for downstream and reference
code. The checked production inventory currently has no translation units that
include it; the compatibility header stays in place while public subsystem
interfaces continue to stabilize.
New translation units should include the smallest subsystem interfaces they use.
Renderer shared state remains broad despite the header migration; continue
introducing narrow interfaces incrementally without changing legacy symbols or
calling conventions.

`tools/test-header-dependencies.py` compares production C includes of
`quakedef.h` against `docs/legacy-quakedef-includes.txt`. That inventory is
currently empty, and the test prevents production files from adding umbrella
dependencies silently. New translation units should use their owning
interfaces. Profiling
declarations live in `src/tests/bench486/bench486_profile.h`; fixture-specific
assembly adapters and C-oracle declarations live with their BENCH486 interfaces,
such as `src/tests/bench486/bench486_drawing_iface.h`. Consumers include those
narrow interfaces directly instead of inheriting benchmark declarations from
the umbrella or a production assembly contract. BENCH-only sprite observation
hooks are declared in `src/tests/bench486/bench486_sprite_hooks.h`, not in the
private renderer header.

Native BENCH486 fixtures live under `src/tests/bench486/`. The fixtures are still
included by the BENCH build and do not become standalone objects. Release and
profile include schedules remain separate.

`tools/build-dos-experimental.ps1` discovers production C and assembly sources
recursively, preserves their unique basename ordering and object names, and
records repository-relative paths in the build manifest. The path map in
`source-layout-map.json` records the original flat paths and supports
one-to-many mappings where a source was later split by subsystem.
