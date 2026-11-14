# View control assembly ownership

## View algorithms and direct fixtures

`src/client/v_viewcontrolasm.s` owns thirteen view, camera, gun, roll, bob, pitch-drift
and stereo control entries. Its separate release and profiling includes retain
the unchanged C reference's x87 instruction and store order. This is maintained,
inspectable assembly pinned once from the reference; normal builds do not
generate it from C. Original functions, hashes and purpose are recorded in
`docs/renderer-assembly/view-control-provenance.json`. Sixty compile-time layout
assertions bind the client, entity, viewport, command and cvar fields.

The normal and profiling fixtures each pass 18,176 exact cases under twelve x87
control words, including 8,192 uninterrupted sequence calls. Cases cover drift
latches, bob limits, extreme valid coordinates, gun lag, damage/death roll,
stair smoothing, multiplayer offsets, pause/intermission/console branches,
crosshair/chase/stereo call order, complete state snapshots and ABI preservation.
Sixteen deliberate guard failures are required to be detected. Execution-bound
artifact snapshots are indexed by
`out/view-control-worktree-20261008/out/view-control-direct-accepted-20261008.json`.

All thirteen public entries are assembly-owned. All 33 preceding assembly
modules retain identical allocated bytes and normalized relocations. The strict
release, benchmark and profiling module audits decode 1,144, 1,159 and 1,169
instructions respectively; every instruction is i386-compatible, with no
unknowns, post-486 instructions or exemptions.

## View scene acceptance and reviewed integration

The identical-source three-scene pair runs both profiles twice and passes all
6,058 post-warmup frame checksums and six complete indexed/palette captures.
Evidence and immutable execution-bound snapshots are in
`out/view-control-worktree-20261008/out/render-parity-view-control-verified-selection-20261008`.
Source tree SHA256:
`5A6A77B1E882FB5F9C0541D6B6F844807632149F7DFAB017203CDFBBEC2C9F97`.
Reference and candidate executable SHA256 values:
`FDAA16432D37611C5D80D128A703C10FA37048122A9D515D791C8D67E07EDD54` and
`C2E69D22CEF1E6B94D7D34FA1B0E622F5D55ADD9F5DB03B98E9E011F630C1DEF`.

| Scene | C view FPS | Assembly view FPS |
|---|---:|---:|
| demo1-vga-full | 12.5559540 | 12.5184350 |
| demo2-entity-workload | 12.7082430 | 12.7082005 |
| demo3-world-workload | 11.9319260 | 11.9318900 |

The first candidate scene contains one slower sample; its other sample and the
remaining scenes match the reference timing closely. There is no material
performance regression. Performance does not determine acceptance.

`ViewControlImplementation` defaults to C; the complete candidate profile
selects assembly. Integration checks every preimage against the accepted
drawing-driver parent, preserves newer main edits and records its allowlist in
`out/view-control-integration-preimages-20261008/manifest.json`.
The earlier three-root inventory finds 21 reachable C routines. The expanded
inventory includes the screen compositor, chase support, view assembly modules
and compiler clones and finds 32 reachable C entries. Remaining ownership,
indirect targets, automatic strict runtime/startup verification and dedicated
full-frame soak/gameplay acceptance remain outstanding.
