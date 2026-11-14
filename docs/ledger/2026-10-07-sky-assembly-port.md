# Sky generation and frame assembly ownership

## Original algorithms and exact direct tests

`src/renderer/r_skyasm.s` owns the five original sky functions: initialization, cached
composition, 8-bit and 16-bit tile generation, and frame-time calculation.
The maintained assembly preserves zero-index masking, the 131-byte wrapped
bottom rows, unaligned four-pixel operations, the packed tile layout and the
original cache early return. Both sampling shifts deliberately use `skyspeed`,
as in the current renderer. Frame-time reduction retains the x87 intermediate
period and changes the control word only for the original truncating casts.

Nine layout assertions, typed public entries and independent original C
oracles support the port. The focused fixture passed 3,072 scalar cases,
1,440 direct compositor cases, an 8,192-frame time sequence and 2,048
uninterrupted composited frames. All twelve x87 precision/rounding settings,
unaligned input/output offsets, complete canonical arrays, cache state, palette
words, source immutability, registers, stack and guard bands compare exactly.
Six deliberately damaged guards exercise the failure detector. Evidence:
`out/sky-worktree-20261007/out/dos-bench-20261007-212728`.
Its executable, manifest, linked audit and execution binding are retained.

An initial fixture used negative inputs outside the original GCD algorithm's
returning domain and did not finish. That rejected run remains retained in
`dos-bench-20261007-211920`; it is not acceptance evidence. The corrected cases
cover nonnegative speeds, zero/nonzero pairs, wrapped integer periods, negative
and large times, sampling wraps and fractional boundaries without tolerances.
The isolated stricter ISA audit of the new module decoded 245 instructions:
all i386-compatible, zero post-486 instructions, zero unknowns and zero
instruction exemptions.

## Scene acceptance and reviewed integration

The actual-selector pair passed three scenes twice per profile. Every one of
the 6,058 post-warmup frame checksums and six indexed framebuffers, including
palette bytes, matched exactly. The six leading checksum entries follow the
existing startup/warmup contract. Source tree SHA256:
`7DD733ACAE82319479DA708B0102D756152EE2F748AB2C8E0F9BA626C5C5DBDB`. Evidence:
`out/sky-worktree-20261007/out/render-parity-sky-verified-selection-20261007`.
Reference and candidate executable SHA256 values are
`BEA5E5B80CF64D1421A54285BB2A7AF465E78FE425F950D5E3C662C7F839D342` and
`BEC2CF6303C117038BFD66646DD7FEC8D7609D3591B264F1EE905675FD5DB73B`. Executables, manifests, linked
reports and execution bindings are retained in `accepted-artifact-snapshot`.

| Scene | C sky | Assembly sky |
|---|---:|---:|
| demo1-vga-full | 12.5538505 | 12.5538390 |
| demo2-entity-workload | 12.7062655 | 12.7062535 |
| demo3-world-workload | 11.9310440 | 11.9304875 |

These measurements show no significant performance regression. Compatibility
and exact output remain the acceptance priorities. Release inspection requires
all five entries to be assembly-owned and the thirty preceding assembly
modules to retain identical allocated bytes and normalized relocations.
Integration records an explicit allowlist and preimages in
`out/sky-integration-preimages-20261007/manifest.json`; the new switch defaults
to C and the complete selection profile uses assembly. Remaining renderer C
ownership, full runtime/provider ISA proof and complete gameplay/soak acceptance
are still outstanding.
