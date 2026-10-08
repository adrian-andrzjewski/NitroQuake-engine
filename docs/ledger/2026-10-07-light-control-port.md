# Animated styles and point-light sampling

## Accepted animated-style and point-light equivalence (2026-10-07)

The C `R_AnimateLight`, `RecursiveLightPoint`, and `R_LightPoint` algorithms now
have independently selectable i486 assembly implementations in
`src/r_lightcontrolasm.s`. The two selectors remain C by default until the
complete renderer profile is accepted. The assembly entries bind the public
symbols directly; release builds do not execute C forwarding wrappers for
these entries. `src/asm_lightcontrol.h` defines the shared layout constants,
and `src/r_light.c` checks them against the C structures at compile time.

The implementation preserves the 64 independent animated-style cursors,
empty-style reset, signed style bytes, time-step modulo behavior, recursive
front/back BSP traversal, x87 intermediate precision, texture-coordinate order,
four style-plane accumulation, missing-light-data behavior and ambient floor.
It uses the existing cdecl register rules, restores the x87 control word, and
returns integers in EAX. The retained C implementations are independent test
oracles in BENCH486 builds.

`src/bench486_lightcontrol.h` compares 14,336 style-animation frames and 1,600
recursive/public point-light cases under 12 x87 control words. It covers
continuous state, time jumps, negative times, all style slots, sampled/null/tiled
surfaces, oblique planes, a 128-node chain, extreme coordinates, immutable input
guards and the ABI probe. The isolated fixture report is
`out/lighting-worktree-20261007/out/dos-bench-20261007-141350/bench-result.json`;
all cases passed.

The accepted paired integration report is
`out/lighting-worktree-20261007/out/render-parity-light-control-verified-selection-20261007-3/render-parity-result.json`.
It covers demo1 VGA, demo2 entities and demo3 world traversal twice per profile
on the configured 486 emulator. Actual build manifests verify both new selectors
as assembly. Both profiles used source tree
`711E74C5C2C161BD6B25E05EA92AF6166CD2703ACC4FDB9F75DA4B8D6BB3073E`.
All 6,058 compared frame checksums and six captures matched exactly; each capture
compares 64,000 palette indices and all 768 palette bytes. The six leading
checksum frames excluded by the harness are documented startup/warmup frames.
There is no pixel or palette tolerance.

The candidate executable SHA256 is
`EDA5E7E7C7BACE722F129AA1B67A65A930BA82865F5E2A1DB01B35B23672EFDA`.
The linked audit checks renderer/support objects and selected runtime archive
members and confirms the mapped final executable bytes. It reports no enforced
post-i486 or unclassified instructions. External DPMI-host and MZ-loader ISA
verification remains a separate completion gap.

Reference/candidate median FPS was 12.682126/12.702573 for demo1,
12.7816155/12.7941075 for demo2, and 12.174848/12.1824255 for demo3.
These small differences are regression observations, not an optimization or
completion criterion. Full combined-profile, extended scene, soak and human
visual/gameplay acceptance remain pending.

The earlier `render-parity-light-control-20261007` report is invalid acceptance
evidence: its runner failed to forward the new selectors and exercised C twice.
Its original report is retained with the invalidation record. Automatic selector
forwarding and actual build-manifest checks now prevent this failure.

The main-workspace integration allowlist and file preimages are recorded in
`out/light-control-integration-preimages-20261007/manifest.json`. No unrelated
files were reset, staged, committed or pushed.
