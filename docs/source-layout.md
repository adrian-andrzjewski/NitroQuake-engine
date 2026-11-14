# Source layout and ownership

Production sources are grouped under `src/` by subsystem: `assets`, `audio`,
`client`, `collision`, `core`, `memory`, `network`, `platform/dos`, `renderer`,
`server`, and `video`. Assembly implementations stay beside their owning
subsystem; C reference implementations and their selectors remain independent.

The public headers `render.h`, `vid.h`, `zone.h`, `client.h`, and `server.h`
define the renderer, video, memory, client, and server entry points. They use
`q_types.h` for primitive engine types and `q_shared.h` for limits shared across
wire, client, model, and sound interfaces. `quakedef.h` remains the compatibility
umbrella for legacy translation units that still depend on cross-module state.
New translation units should include the smallest subsystem interfaces they use.
The renderer's existing shared state remains in place while individual callers
move off the compatibility header.

Native BENCH486 fixtures live under `src/tests/bench486/`. The fixtures are still
included by the BENCH build and do not become standalone objects. Release and
profile include schedules remain separate.

`tools/build-dos-experimental.ps1` discovers production C and assembly sources
recursively, preserves their unique basename ordering and object names, and
records repository-relative paths in the build manifest. The historical path
map is in `source-layout-map.json`.
