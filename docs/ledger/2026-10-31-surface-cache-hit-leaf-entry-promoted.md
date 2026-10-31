# Static surface-cache hit leaf entry recheck promoted (2026-10-31)

## Change

`D_CacheSurface` now probes eligible static-texture hits before saving the
callee-saved registers and allocating its 52-byte local frame. The probe uses
only caller-saved registers and compares the same texture, light-style, cache,
and dynamic-light keys as the full path. Animated textures, misses, mismatched
keys, current-frame dynamic-light cases, and profile builds enter the existing
routine unchanged. A valid hit returns the existing cache pointer directly.

## 320x200 performance

The uninstrumented `demo1` timedemos used DOSBox-X 2026.08.31, `cputype=486`,
fixed 33,445 cycles, the pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and
`-stdvid`.

| Variant | FPS samples | Mean FPS |
|---|---|---:|
| Control | 16.336056 / 16.336052 / 16.336056 | 16.336054667 |
| Candidate | 16.339183 / 16.339188 / 16.339183 | 16.339184667 |

The candidate gained **0.003130 FPS (+0.019160%)**. Every run rendered 969
frames and ended at framebuffer checksum `1047377823`; the recorded timedemo
event traces matched.

## Deterministic output and i486 gates

The repository render-validation step `host_framerate 0.0783` was supplied
through DOS autoexec for parity-only captures. The baseline stream matched both
candidate streams across all 970 rendered frames. The captured frame 169 PCX
was byte-identical in all three runs (SHA-256
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`).

The strict linked audit passed 314,334 executable instructions (314,333 i386,
one i486, zero above i486, unknown, or exempt). The exact source/runtime proof
covered 403 objects; startup proof covered 529 code rows and the provider proof
covered 9,207 instructions, with zero exemptions. Candidate source fingerprint:
`D589BCA387E776D89B9487A5CA25877FCAF5684816BB0C7517DC69B1837B2ACB`.

This is a measured DOSBox-X gain under the pinned emulated profile. It does not
predict the size of the gain on physical 486 cache or FPU implementations.

## Artifacts

- Control timing: `out/dos-timedemo-20261030-223441/timedemo-result.json`
- Candidate timing: `out/dos-timedemo-20261030-231008/timedemo-result.json`
- Deterministic control capture: `out/dos-timedemo-20261030-231851/`
- Deterministic candidate captures: `out/dos-timedemo-20261030-231531/`
- Strict build and audit: `out/local-i486-cache-entry-strict-20261030/`
