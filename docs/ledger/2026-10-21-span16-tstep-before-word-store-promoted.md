# Span16 T-step addition before word store promoted (2026-10-21)

Status: promoted in `src/d_draw16.s` under the any-positive pooled mean rule.

In the default Span16 word-store path, the next pixel's T-step addition now
runs immediately before the current destination word store. The store and
following source-byte load preserve flags, so the T carry remains available to
the later `sbb`. This overlaps the independent accumulator step with the
destination store without changing pixel order. The timedemo retained exact
output parity.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-194229` | 15.564257 / 15.564260 / 15.564252 | 15.564256333 | 0.000008 |
| T-step/store candidate, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| Active control, strict | `out/dos-timedemo-20261021-200635` | 15.564258 / 15.564264 / 15.564252 | 15.564258000 | 0.000012 |
| T-step/store candidate, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |

The strict candidate mean is **+0.000002333 FPS (+0.00001499%)** over the
active control. Its parity-screen mean was **−0.000004667 FPS** against
control, but the matched strict mean is positive and qualifies under the user's
rule. Each strict run completed 969 frames with framebuffer checksum
`1047377823`.

The complete strict i486 gate passed: 313,315 relocated instructions across
435 executable ranges, 529 startup code rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. The strict candidate
executable SHA-256 is
`154C7F443F15DFF7D5BBA3E96FB0E23CD0CDDAD1FE27106D6762B1868E76B97C`; the
source fingerprint is
`916ABB2670B607AA79F18155F4573A97001135E1BA7E4A397DCC83797C6F8C29` and the
source-tree fingerprint is
`DB27F40690187D296BAB82BCB2BACFDB10BA309F34B3E5054BC7E22FE5E30689`.
