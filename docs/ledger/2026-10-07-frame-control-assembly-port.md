# Frame control instruction ownership

## Accepted frame-control equivalence (2026-10-07)

`FrameControlImplementation=asm` selects the fourteen `r_main.c` entries owned
by `src/r_framecontrolasm.s`, with separate maintained release and PROFILE486
instruction bodies. The C definitions remain independent BENCH486 oracles;
ordinary selected release builds retain their shared data declarations without
executing C frame-control forwarding entries. The selector remains C by default
while complete-renderer integration is tested.

The instruction baseline was imported once from the pinned i486 C reference.
Normal builds assemble the checked-in instruction text and do not regenerate it
with a compiler. Expression/variable comments retain the original evaluation
and x87 store order. Typed constants reside in data. The module specifies cdecl
arguments, preserved registers and stack reservations, and 99 compile-time
layout/constant assertions reject incompatible shared structures. The original
GPL notice, baseline C source and function/proof mapping are retained in
[frame-control provenance](../renderer-assembly/frame-control-provenance.json)
and [baseline source](../renderer-assembly/frame-control-reference.c).

The direct report `out/dos-bench-20261007-162447/bench-result.json` passes all
22,528 exact comparisons. It covers viewport quantization and aliases, fov and
aspect boundaries, refdef/frustum/driver state, rotated and unrotated brush
bounds, extreme coordinates, compressed visibility, parent marking and the
unchanged-leaf early return. Twelve x87 settings, ABI probes and guards pass.
An 8,192-iteration uninterrupted visibility/bounds sequence crosses the signed
frame-counter boundary; no state or memory difference is accepted.

The paired report is
`out/render-parity-frame-control-verified-selection-20261007/render-parity-result.json`.
Demo1 VGA, demo2 entities and demo3 world traversal each run twice per profile
on the configured 486 emulator. Actual manifests verify the focused candidate
selects frame-control assembly and that the reference selects C. Both use
source-tree SHA256
`F19C4188E0F63E91B938BA6724FF1FFC30B2C8E339B84F626203E4E088A874C2`.
All 6,058 post-warmup checksums and six complete captures match exactly. Each
capture compares 64,000 palette indices and all 768 palette bytes. Six leading
startup frames per run are excluded from this documented post-warmup stream;
there is no pixel, palette or arithmetic tolerance.

The candidate executable SHA256 is
`DF8B40AF8815859AB4694C20364391CD2501600E311F1B6BBA86EF954E61EF0D`,
and its verified manifest SHA256 is
`DDD5E6AC6E5B265D7A604E1EA44E7980042EB8219F540CE1E24A50834C15BC50`.
The linked gate covers 109 selected objects, 344 closure inputs, 235 runtime
members and 226,706 linked instructions, with no enforced post-i486 or
unclassified instruction and no linked opcode mismatch. The separate frame
object has 1,928 instructions and needs no data exemptions. External DPMI-host
and MZ-loader proof remains open.

Reference/candidate median FPS is 12.682151/12.6439025 for demo1,
12.781614/12.781615 for demo2 and 12.174849/12.1748575 for demo3. The demo1
candidate repeats span 12.605694 to 12.682111 FPS; that variability is retained
in the report. The observed median reduction is about 0.3%, with no significant
regression motivating algorithm or instruction-order changes.

After this accepted pair, only original copyright/provenance comments were
added to the frame assembly sources. Subsequent full-profile builds record
their own new source fingerprint; this report continues to identify its exact
tested tree. Combined all-selector parity, expanded scenes, full-frame soak and
human visual/gameplay acceptance remain separate gates.

## Reproducing the frame-control gates

Run `tools/bench-dos.ps1 -NoBootstrap -FrameControlImplementation asm
-FrameControlOnly` for direct comparisons, then `tools/render-parity-dos.ps1
-NoBootstrap -ReferenceProfile tools/renderer-profiles/i486-c-reference.json
-CandidateProfile tools/renderer-profiles/i486-asm-frame-control.json
-Scenario demo1-vga-full,demo2-entity-workload,demo3-world-workload
-RunsOverride 2` for complete-frame comparisons. Supply the same explicit
`-DataRoot` for isolated checkouts. The normal build audits the selected objects,
runtime inputs and relocated executable bytes before either runner executes.
