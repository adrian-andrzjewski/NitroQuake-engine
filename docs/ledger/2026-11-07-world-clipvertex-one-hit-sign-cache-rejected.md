# World clip-vertex one-hit sign cache rejected (2026-11-07)

Status: rejected. The cache preserved the tested color and Z output and passed
the complete strict i486 audit, but its matched uninstrumented mean was 0.4612%
slower than control. The runtime cache and one-hit shortcut were removed.

## Candidate and motivation

The direct-address table stores one exact distance sign per world vertex and
view clip plane for the current frame. When both endpoint signs are cached and
equal, the clipper skips both distance calculations. When one sign is cached,
it calculates the other endpoint first and skips the cached endpoint's distance
if the signs match; opposite signs still calculate both exact distances for
intersection interpolation.

The preceding PROFILE486 census modeled 1,561,871 skipped endpoint dot
calculations, about 60% of world endpoint evaluations. This was a work-count
estimate, not a performance result.

## Exact output and i486 compatibility

The candidate used the pinned DOSBox-X 2026.08.31 i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, `host_framerate 0.0783`, and `con_notifytime -1`. Its
fixed-step replay completed 969 timed frames. All 970 framebuffer checksum
rows, all 970 Z checksum rows, and the captured frame-482 PCX matched control.
The output hashes were:

| Output | SHA-256 |
| --- | --- |
| Framebuffer checksum stream | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

The final framebuffer checksum was `1047377823`. The strict audit covered 403
exact project/runtime objects, 315,627 linked instructions across 435 CODE
ranges, 529 DOS startup code rows, and 9,207 DPMI provider instructions. It
reported zero above-i486, unknown, or exempt instructions.

## Matched uninstrumented timing

All runs used the pinned profile and the same 969-frame workload without
per-frame checksum or FPS instrumentation.

| Variant | FPS samples | Mean FPS | Mean elapsed seconds |
| --- | --- | ---: | ---: |
| Control | 16.897615, 16.897610, 16.897617 | 16.897614000 | 57.345374 |
| One-hit sign cache | 16.819689, 16.819689, 16.819688 | 16.819688667 | 57.611054 |

The candidate was **0.4612% slower** by mean FPS. The additional endpoint
lookups and sign branches outweighed the avoided dot calculations. Reject the
cache for this workload; the modeled hit count does not justify retaining the
runtime structure. DOSBox-X results do not establish physical 486 performance.

## Artifacts

- Strict build: `out/local-clipvertex-sign-cache-onehit-20261107`.
- Exact parity replay: `out/dos-timedemo-20261106-235801`.
- Matched timing runs: `out/dos-timedemo-20261107-000029`.
