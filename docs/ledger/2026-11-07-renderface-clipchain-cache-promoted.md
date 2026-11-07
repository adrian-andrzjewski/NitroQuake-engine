# R_RenderFace partial clip-chain cache promoted (2026-11-07)

## Candidate

`R_RenderFace_asm486` now retains the head pointer for the last partial
`clipflags` mask. When the next world face has the same mask, it reuses the
existing `view_clipplanes` links and skips rebuilding them. A miss constructs
the original plane chain in the original 3-to-0 order and caches its mask and
head. The existing prelinked full-mask path remains unchanged.

Brush-model face and polygon paths invalidate the entry before they rewrite the
shared links. The C reference paths do the same. Builds without
`ASM486_TRANSFORM_FRUSTUM` also invalidate after their full-mask path rewrites
the base links. The cache stores no duplicate clip planes and adds two
32-bit globals.

## Profile counts

The instrumented replay at `out/dos-timedemo-20261107-083815` processed 969
timed frames and recorded 215,751 `R_RenderFace` calls. Partial-mask calls
built 19,884 chains and reused one 77,583 times: a 79.6% hit rate across the
97,467 partial-mask calls. The full-mask chain is counted separately and does
not use this cache. The instrumented run's FPS is not release timing evidence.

## Output parity

The candidate at `out/dos-timedemo-20261107-083815` matches the clean
`6747b3d` control at
`out/worktree-renderface-clipchain-control-20261107/out/dos-timedemo-20261107-085849`
for every recorded color and Z row and for the captured frame 482 PCX. Their
SHA-256 values are:

| Output | SHA-256 |
| --- | --- |
| Color checksum stream | `69F4F9869D9AACD9704085EA984DE4E95226795F56615209B26F0B07D11D6883` |
| Z checksum stream | `3C886D24243FCE937F3EF483F723B2CD3389C9C54B84EAD8625C59F2A0F874F3` |
| Frame 482 PCX | `75CB732FEC8E8091007F46B0057624A2E0601AF36FF026E3E43A86C1133F213` |

Each checksum file contains 971 records; there are zero differing rows. An
earlier comparison against `out/dos-timedemo-20261106-205613` used an older
source-tree fingerprint and is not the parity authority for this candidate.

## Strict i486 audit

The release executable passed the complete strict i486 gate: 315,284 relocated
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions;
zero instructions were above i486, unclassified, exempt, or undecoded. All
403 project and runtime source proofs matched. The candidate result records
`isaAuditStatus: PASS`.

## Matched release timing

Both variants used DOSBox-X 2026.08.31, the pinned 320-by-200 `demo1` workload,
969 frames, and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Both
produced framebuffer checksum `1047377823`. Neither timing run used
instrumentation.

The strict-audited control is `out/dos-timedemo-20261107-061826`; the candidate
is `out/dos-timedemo-20261107-091354`.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.756090, 16.756077, 16.756081 | 16.756082667 |
| Clip-chain cache | 16.758520, 16.758503, 16.758497 | 16.758506667 |

The candidate mean is **0.0144664% faster**. Every candidate sample exceeded
every control sample; the smallest gap was 0.002407 FPS. The exact DOSBox-X
gain is small, but positive under the renderer's current acceptance policy.
This result is emulator evidence, not a physical-486 performance claim.
