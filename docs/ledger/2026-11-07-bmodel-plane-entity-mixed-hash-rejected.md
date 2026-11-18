# Brush-model splitter-plane entity-mixed hash rejected (2026-11-07)

## Candidate

The 512-slot transformed splitter-plane cache originally hashes only the BSP
plane pointer, while validating the plane, current entity, and frame as exact
tags. This profile-only candidate mixed `currententity >> 4` with
`plane_pointer >> 2` before masking to 511. It retained the same four arrays,
capacity, transformed values, and tag checks. The intent was to reduce
cross-entity direct-map conflicts without increasing the 14,336-byte BSS cost.

## Profile and strict i486 audit

The candidate ran the 969-frame 320x200 `demo1` workload under DOSBox-X
2026.08.31 with the pinned i486 profile hash
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
It recorded **31,160 hits and 9,998 misses across 41,158 requests**, exactly
the same totals as the promoted 512-entry pointer-only hash. The run ended at
framebuffer checksum `1047377823`, but framebuffer and Z per-frame checksums
were disabled; this is not an exact-output parity result. The 11.325716 FPS
profile timing is instrumentation-heavy and is not performance evidence.

The complete strict i486 gate passed: 322,924 linked instructions across 435
CODE ranges, 529 startup CODE rows, and 9,207 DPMI-provider instructions, with
zero above-i486, unknown, or exempt instructions. All 403 native and annotated
object proofs matched.

## Decision

Reject the entity-mixed hash before release parity or timing. It avoided no
additional transforms and adds entity-load/hash work to every request. Restore
the promoted plane-pointer hash. No FPS gain or exact-output claim is made.

## Artifacts and reproduction

- Profile build: `out/local-bmodel-plane-entity-mix-20261107/`.
- Profile run: `out/dos-timedemo-20261107-021324/`.
- Base revision: `a84fb16c3bb39c657bbc5f2f6ce0d3203f3115dd`.

The profile run used the build and timedemo scripts with
`-Instrumentation -NoBootstrap -Runs 1`, data root
`out/dos-timedemo-20261106-222828/quake/id1`, and
`-BmodelPolygonClipImplementation asm`.
