# Visibility support assembly ownership

## Original behavior and direct tests

`src/renderer/r_visibilityasm.s` owns `Mod_PointInLeaf`, `Mod_DecompressVis` and
`Mod_LeafPVS`. The maintained assembly follows the original BSP plane traversal,
zero-run decompression and solid-leaf PVS selection. Point tests preserve x87
evaluation order, extended intermediate precision and the strict positive-child
rule. An already-terminal leaf does not read the point argument. Decompression
preserves the original row calculation, zero-count packets, do/while boundary
behavior, persistent-buffer tail and canonical `mod_novis` identity.

Seventeen layout assertions are in `src/renderer/asm_visibility.h`. The benchmark checks
all 1,024 persistent buffer bytes, input/model/leaf immutability, exact leaf and
PVS pointer identity, register/stack/x87 ownership and both guard bands. It
passed 9,216 direct cases under twelve x87 settings and an 8,192-step continuous
sequence, including leaf widths through 8,192 bits, 255-byte zero runs, empty
packets, deep trees, plane ties and extreme coordinates. Deliberately damaged
leading/trailing guards exercise the detector. Evidence:
`out/visibility-worktree-20261007/out/dos-bench-20261007-183825`.

## Scene acceptance and integration

The focused actual-selector pair passed demo1 VGA, demo2 entities and demo3
world workloads, twice per profile. All 6,058 post-warmup checksums and six
indexed/palette captures matched exactly. Source tree SHA256:
`578CA2871BBF115AC90E08EAC321A8EB6886D91C5B36EBF719B5DEF263F6D135`. The candidate manifest verifies
`VisibilityImplementation=asm`; the reference verifies `c`. Evidence:
`out/visibility-worktree-20261007/out/render-parity-visibility-verified-selection-20261007`.

The accepted candidate executable SHA256 is
`7DF5619B12F2D38ACA4731078BDBA6A588CE25BA384DDF63D1CA9023572BC949`. Its existing linked
ISA gate verified 224,972
instruction sites. Candidate medians were approximately 12.68, 12.78 and 12.17
FPS, matching the reference workload rate. Performance is secondary to this
exact comparison.

Integration preserves an explicit allowlist and preimages in
`out/visibility-integration-preimages-20261007/manifest.json`. The switch defaults
to C and the all-selectable profile selects assembly. The complete renderer,
indirect support closure and stronger runtime ISA proof are still in progress.
