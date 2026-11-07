# World clip-vertex inline sign cache rejected (2026-11-07)

Status: rejected. After correcting all 12-byte assembly vertex strides, the
inline per-vertex cache preserved the tested color and Z output and passed the
complete strict i486 audit. Its three-run uninstrumented mean was 0.30731%
slower than control, so the cache and expanded vertex layout were removed.

## Candidate and layout correction

The candidate added a 32-bit frame/plane sign word to `mvertex_t`, growing each
world vertex from 12 to 16 bytes. The assembly clipper used that word to skip
endpoint dot products when a same-frame sign was available. This avoided a
separate address-to-slot lookup, but added per-endpoint cache checks and stores
and expanded the vertex working set by one third.

The first parity replay exposed remaining 12-byte strides in the assembly
`R_RenderFace`, `R_RenderPoly`, and brush-model clipping paths. Those model
vertex address calculations and the clipped brush-model vertex offsets were
updated to 16 bytes; temporary clip pages and edge records remain 12 bytes.
Parity below is from the corrected candidate.

## Exact output and i486 compatibility

The corrected fixed-step replay used the pinned DOSBox-X 2026.08.31 i486
profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, `host_framerate 0.0783`, and `con_notifytime -1`. All 970
framebuffer checksum rows, all 970 Z checksum rows, and the captured frame-482
PCX matched control. Their hashes were:

| Output | SHA-256 |
| --- | --- |
| Framebuffer checksum stream | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

The final framebuffer checksum was `1047377823`. The strict audit covered 403
exact native/annotated object proofs, 315,567 linked instructions across 435
CODE ranges, 529 DOS startup code rows, and 9,207 DPMI provider instructions.
It reported zero above-i486, unknown, or exempt instructions.

## Matched uninstrumented timing

All runs used the same pinned profile, i486 aggressive benchmark selectors,
data, fixed host frame step, and 969 timed frames. Timed runs did not enable
per-frame checksum or FPS instrumentation.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.897615, 16.897610, 16.897617 | 16.897614 |
| Inline sign cache | 16.845682, 16.845689, 16.845687 | 16.845686 |

The candidate was 0.30731% slower. A later control rerun measured 16.897615 FPS,
and a candidate rerun immediately afterward measured 16.845684 FPS. The control
rate remained stable; the slowdown was not caused by a transient slow sample.

## Decision

The same-side endpoint reuse was correct, but the lookup branches, generation
checks, cache stores, and larger vertex records cost more than the avoided
floating-point dot products. The inline cache and `mvertex_t` size increase
were removed. No physical 486 performance claim follows from DOSBox-X timing.

## Artifacts

- Strict i486 build: `out/local-clipvertex-inline-sign-cache2-20261107`.
- Corrected framebuffer/Z/PCX parity replay: `out/dos-timedemo-20261107-005658`.
- Three uninstrumented candidate runs: `out/dos-timedemo-20261107-010244`.
- Fresh control: `out/worktree-bmodel-endpoint-cache-control-20261106/out/dos-timedemo-20261107-011344`.
- Candidate recheck: `out/dos-timedemo-20261107-011523`.
- Initial replay before fixing the vertex strides: `out/dos-timedemo-20261107-003548`.
