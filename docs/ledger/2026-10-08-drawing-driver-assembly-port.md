# Drawing driver assembly ownership

## Driver algorithms and direct fixtures

`src/d_driverasm.s` implements thirteen drawing-driver entries from `d_init.c`,
`d_modech.c`, `d_part.c`, `d_surf.c` and `d_edge.c`. The module preserves setup,
row-pointer caching, mip selection, viewport and particle bounds, the original
process-lifetime writable-code latch and surface-cache owner invalidation.
Original no-op entries remain simple returns. Twenty-one layout assertions bind
the assembly constants to the C structures. Pinned original functions, hashes
and independently compiled test oracles are recorded in
`docs/renderer-assembly/drawing-driver-provenance.json`.

The normal and profiling fixtures each passed 18,176 exact cases under twelve
x87 control words, including 8,192 uninterrupted sequence calls. Fixtures cover
all row-table entries, guarded indexed and 16-bit buffers, cached stride/base
reuse, zero/maximum valid heights, large viewport values, aliasing owner links,
typed outgoing calls, preserved registers and stack state. Forty deliberate
detector failures are required to be observed. Normal evidence is in
`out/driver-worktree-20261008/out/dos-bench-20261007-233557`; profiling evidence
is indexed by this integration's preimage manifest.

The strict release module audit decoded 247 instructions: all i386-compatible,
with zero unknowns, post-486 instructions or exemptions. Release inspection
proves the thirteen public entries are assembly-owned, and all 32 preceding
assembly modules retain identical allocated bytes and normalized relocations.

## Drawing driver scene acceptance and reviewed integration

The identical-source three-scene pair ran each profile twice and passed all
6,058 post-warmup frame checksums and six complete indexed/palette captures.
Evidence is in
`out/driver-worktree-20261008/out/render-parity-drawing-driver-verified-selection-20261008`.
Source tree SHA256:
`E3024D1D8467017A104F1384D65A3C7A831265DDEBD45FFCD5FD9C6FC7F68312`.
Reference and candidate executable SHA256 values are
`31C2650AC21BACB085EE9BB576F892A049BD12D74AE26117F367E5C3073E5199` and
`4F918ADD33C52DED040EAD671461F6C62402F28D03CD4ED9A79B687AF6FFD1F4`.
Execution-bound hashes and executable snapshots are indexed in
`accepted-artifacts.json`.

| Scene | C driver FPS | Assembly driver FPS |
|---|---:|---:|
| demo1-vga-full | 12.5559605 | 12.5559250 |
| demo2-entity-workload | 12.7082480 | 12.7082335 |
| demo3-world-workload | 11.9319270 | 11.9319310 |

The measurements show no material performance regression. Integration checks
every edited preimage against the accepted dispatch parent, retains newer main
documentation, and records its explicit allowlist in
`out/driver-integration-preimages-20261008/manifest.json`.
`DrawingDriverImplementation` defaults to C; the complete candidate profile
selects assembly. The release inventory finds 29 reachable C renderer routines.
Indirect targets and compiler clones still require a closure review; full
renderer ownership, strict automatic runtime verification, dedicated scene and
full-frame soak/gameplay acceptance remain outstanding.

## 2026-10-12 outgoing-call stack-alignment follow-up

`D_Init` and `D_Patch` now establish aligned cdecl call frames before invoking
the C registration and writable-code helpers, then restore the exact incoming
stack pointer. The benchmark-only call observer reserves its stack-alignment
slot while preserving the arguments recorded by the C oracle.

The focused i486 `DrawingDriverImplementation=asm` run passed 18,176 exact
state comparisons over thirteen entries, twelve x87 control words, 8,192
sequence calls, and forty guard checks, with zero failures. The selected build
passed the object, linked-runtime, relocated executable, startup, and provider
ISA gates: 173,277 project-object instructions, 211,574 linked instructions,
529 startup CODE rows, and 9,207 provider instructions; zero post-i486,
unknown, or exempt instructions.

The paired C-reference/assembly profile run used identical sources and passed
`demo1-vga-full`, `demo2-entity-workload`, and `demo3-world-workload` twice
each. All 6,058 post-warmup frame checksums and six indexed framebuffer plus
palette captures matched exactly. Evidence is in
`out/render-parity-driver-stack-20261012`. That pair was run with
`-VisualParityOnly`; its own ISA status is SKIPPED. The separate focused build
above supplies the strict ISA proof for this drawing-driver source change.
