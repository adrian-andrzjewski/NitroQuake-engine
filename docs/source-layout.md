# Source layout and ownership

Production sources are grouped under `src/` by subsystem: `assets`, `audio`,
`client`, `collision`, `core`, `memory`, `network`, `platform/dos`, `renderer`,
`server`, and `video`. Assembly implementations stay beside their owning
subsystem; C reference implementations and their selectors remain independent.

The public headers `render.h`, `vid.h`, `zone.h`, `client.h`, and `server.h`
define the renderer, video, memory, client, and server entry points. The narrow
`host.h` exposes startup parameters, host lifecycle and frame entry points,
host timing, and shared palette state to other subsystems.
Subsystem headers use `q_types.h` for primitive engine types and `q_shared.h`
for limits shared across wire, client, model, and sound interfaces. `common.h`
selects game-side BSP declarations for engine translation units. `quakedef.h`
remains the compatibility umbrella for legacy translation units that still
depend on cross-module state.
New translation units should include the smallest subsystem interfaces they use.
The renderer's existing shared state remains in place while individual callers
move off the compatibility header.

`tools/test-header-dependencies.py` compares production C includes of
`quakedef.h` against `docs/legacy-quakedef-includes.txt`. A translation unit may
leave that inventory only after it switches to its owning interfaces; new
production files must not add umbrella dependencies silently. Profiling
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
records repository-relative paths in the build manifest. The historical path
map is in `source-layout-map.json`.
