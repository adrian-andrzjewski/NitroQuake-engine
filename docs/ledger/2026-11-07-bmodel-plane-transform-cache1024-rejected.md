# Brush-model splitter-plane cache expansion to 1,024 rejected (2026-11-07)

Status: rejected before release timing. The 1,024-entry profile cache recorded
exactly the same hit and miss counts as the promoted 512-entry cache, while
doubling its BSS footprint from 14,336 to 28,672 bytes. It eliminated no
additional plane transforms.

## Candidate

The brush-model clipper uses a direct-mapped transformed splitter-plane cache
keyed by plane pointer, current entity, and frame. The candidate grew each of
its four arrays from 512 to 1,024 entries and changed the hash mask from 511 to
1,023. It added no lookup probes or comparisons; its only expected benefit was
fewer direct-map collisions.

## Profile and strict i486 audit

The pinned DOSBox-X 2026.08.31 i486 profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and fixed host frame step produced 41,158 cache requests:

| Capacity | Hits | Misses | BSS bytes |
| ---: | ---: | ---: | ---: |
| 512 | 31,160 | 9,998 | 14,336 |
| 1,024 | 31,160 | 9,998 | 28,672 |

The instrumented 1,024-entry run completed 969 frames and ended at framebuffer
checksum `1047377823`; its profile timing is diagnostic only. The strict i486
audit covered 403 exact native/annotated object proofs, 322,920 linked
instructions across 435 CODE ranges, 529 DOS startup code rows, and 9,207 DPMI
provider instructions. It reported zero above-i486, unknown, or exempt
instructions.

## Decision

The larger table preserved its cache lookup behavior but did not improve the
hit rate or avoid any additional transform. Since the 512-entry table already
passed exact color/Z parity and uninstrumented timing, the 1,024-entry version
was removed without a release timing A/B. Retain the 512-entry cache. DOSBox-X
profiling does not establish physical 486 cache behavior.

## Artifacts

- Instrumented strict build: `out/local-bmodel-plane-cache1024-profile-20261107`.
- Profile run: `out/dos-timedemo-20261107-013525`.
- 512-entry control evidence: `docs/ledger/2026-11-06-bmodel-plane-transform-cache512-promoted.md`.
