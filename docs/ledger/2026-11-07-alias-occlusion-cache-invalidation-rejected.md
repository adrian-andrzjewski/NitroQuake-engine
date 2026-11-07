# Alias occlusion cache invalidation after model draws rejected (2026-11-07)

Status: rejected. Refreshing cached tile minima after alias models wrote Z
changed intermediate framebuffer and Z output. The candidate was removed
without an uninstrumented timing run.

## Candidate

The existing 4-by-4 tile cache keeps a conservative minimum for the rest of the
frame. This experiment deferred invalidating the projected tile rectangle of a
model that passed the occlusion test until the next alias query. The next query
would therefore rescan those tiles against Z values written by the previous
alias model. The intent was to let one alias model provide occlusion for later
models while preserving draw order.

## Correctness results

The strict i486 audit passed, and both runs retained 969 timed frames and final
framebuffer checksum `1047377823`. The instrumented candidate did not preserve
the intermediate output streams:

| Stream | Differing rows | Candidate SHA-256 | Control SHA-256 |
|---|---:|---|---|
| Framebuffer checksums | 462 of 971 | `69F4F9869D9AACD9704085EA984DE4E95226795F56615209B26F0B07D11D6883` | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z-buffer checksums | 141 of 971 | `3C886D24243FCE937F3EF483F723B2CD3389C9C54B84EAD8625C59F2A0F874F3` | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |

The captured frame 482 PCX differed as well: candidate SHA-256
`75CB732FEC8E8091007F46B0057624A2E0601EDCCD52B0214AEEB0A082EAF7BD`, versus
control SHA-256
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`.

## Work saved and decision

The candidate kept 1,627 of 4,503 alias model queries culled, the same total as
the retained cache. It performed 36,938 tile checks and 532,575 Z samples;
control performed 36,940 tile checks and 530,082 Z samples. Thus invalidation
added 2,493 Z samples without adding a cull. The candidate is rejected for
incorrect intermediate output and no release timing was run.

Evidence is preserved in `out/dos-timedemo-20261107-075525` and compared with
`out/dos-timedemo-20261106-205613`. Keep the accepted conservative cache
behavior; do not refresh cached tiles after alias Z writes without a new
exactness proof.
