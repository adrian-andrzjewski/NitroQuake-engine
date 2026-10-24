# Span16 S-add before first A-half high-byte fetch promoted (2026-10-21)

Status: promoted in `src/d_draw16.s` under the any-positive pooled mean rule.

In the A half of the default Span16 word-store path, the first high-byte texel
fetch now follows `addl %ebp,%ebx`. The intervening `movb (%esi),%ah` preserves
the S-step carry for the following `adcl`, while allowing the S-fraction add to
overlap the source-byte load. The timedemo retained exact output parity.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-191132` | 15.564267 / 15.564265 / 15.564244 | 15.564258667 | 0.000023 |
| S-add candidate, parity screen | `out/dos-timedemo-20261021-194229` | 15.564257 / 15.564260 / 15.564252 | 15.564256333 | 0.000008 |
| Active control, strict | `out/dos-timedemo-20261021-193519` | 15.564265 / 15.564246 / 15.564259 | 15.564256667 | 0.000019 |
| S-add candidate, strict | `out/dos-timedemo-20261021-200635` | 15.564258 / 15.564264 / 15.564252 | 15.564258000 | 0.000012 |

The strict candidate mean is **+0.000001333 FPS (+0.00000857%)** over the
active control. The screen mean was **−0.000002333 FPS** against its control,
but the matched strict mean is positive and qualifies under the user's rule.
Each strict run completed 969 frames with framebuffer checksum `1047377823`.

The complete strict i486 gate passed: 313,315 relocated instructions across
435 executable ranges, 529 startup code rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. The strict candidate
executable SHA-256 is
`5EEC96FD00B30E476484F627968B88B0972177F8D06BD7A1833173539FE9CA1F`; the
source fingerprint is
`7044ECC822588369D9C659B796FCDA3E4ADF45EF0A55693B5F14D997AAD9EE50` and the
source-tree fingerprint is
`96D755856AD375E50BC2121D1973AEC0E659D4B09C1EEFB50FB290495D49AA1A`.
