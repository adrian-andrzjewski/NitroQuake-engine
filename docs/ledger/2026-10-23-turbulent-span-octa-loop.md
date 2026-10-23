# Promote eight-pixel turbulent span loop (opt-in)

The `octa` selector renders eight turbulent pixels per main-loop branch and
handles remaining pixels with a grouped 4/2/1 tail. It reuses the existing
pixel calculation and remains opt-in; the checked-in i486 profile keeps its
prior default until the full release selector set is measured directly.

## Matched timedemo

The `demo1` timedemo compared `octa` against the four-pixel `quad` loop. Both
variants used the same source tree, all other selectors, data root, DOSBox-X
2026.08.31 profile, cycle count, and run options. The normalized profile
SHA-256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` and the
source-tree fingerprint was
`24DCC8B22ECC8B453D358BE1782432A3CC96311287F59EDA8C3BF21B34C82477`.

| Variant | Timedemo artifact | FPS samples | Mean FPS | Spread |
|---|---|---|---:|---:|
| Four-pixel `quad` control | `out/dos-timedemo-20261023-014459` | 15.602514 / 15.602509 / 15.602515 | 15.602512667 | 0.000006 |
| Eight-pixel `octa` candidate | `out/dos-timedemo-20261023-012212` | 15.606197 / 15.606208 / 15.606220 | 15.606208333 | 0.000023 |

The candidate gains **0.003695667 FPS (+0.023686%)** over `quad`; every
candidate sample exceeded every control sample. Each run completed 969 frames
with framebuffer checksum `1047377823`.

## Strict i486 validation

Both variants passed the full source-bound i486 ISA gate. The `octa` candidate
contained 313,623 linked instructions across 435 executable ranges; the audit
found zero above-i486, unknown, exempt, or unenforced instructions. Its 529
startup instructions and 9,207 external DPMI-provider instructions also passed
with zero exemptions. The `quad` control contained 313,471 linked instructions
and passed the same gates.

Artifacts:

- Candidate timedemo: `out/dos-timedemo-20261023-012212/timedemo-result.json`
- Control timedemo: `out/dos-timedemo-20261023-014459/timedemo-result.json`
- Candidate strict build: `out/local-local-turbulent-octa-strict-20261023/`
- Control strict build: `out/local-local-turbulent-octa-quad-control-strict-20261023/`
