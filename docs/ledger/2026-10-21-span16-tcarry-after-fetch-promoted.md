# Span16 T-carry extraction after low-byte fetch promoted (2026-10-21)

Status: promoted in `src/d_draw16.s` under the user's any-positive pooled-mean
rule.

In the default `ASM486_SPAN16_WORD_STORES` path, the T-carry extraction
`sbbl %ecx,%ecx` now follows each low-byte source fetch `movb (%esi),%al` in the
A and B halves. The load preserves flags, so SBB consumes the same carry from
`addl tstep,%edx`; the subsequent S-step add, address ADC, and DDA arithmetic
are unchanged. All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Timing and parity

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control, 3 runs | `out/dos-timedemo-20261021-123303` | 15.537284 / 15.537298 / 15.537285 | 15.537289000 | 0.000014 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-132030` | 15.537290 / 15.537291 / 15.537295 | 15.537292000 | 0.000005 |
| Parity-screen control, 3 runs | `out/dos-timedemo-20261021-120454` | 15.537292 / 15.537300 / 15.537292 | 15.537294667 | 0.000008 |
| Parity-screen candidate, 3 runs | `out/dos-timedemo-20261021-125419` | 15.537309 / 15.537297 / 15.537300 | 15.537302000 | 0.000012 |

The strict candidate mean is **+0.000003000 FPS (+0.00001931%)** above the
strict control mean. The parity-screen mean is also positive by
**+0.000007333 FPS (+0.00004720%)**. The strict gain is below the observed
spread, but it qualifies under the user's rule. All eight timedemo samples
completed 969 frames with framebuffer checksum `1047377823`.

The strict candidate result is
`out/dos-timedemo-20261021-132030/timedemo-result.json`; it records
`isaAuditStatus=PASS`, profile hash
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
source-tree fingerprint
`737A8DC7779F8E724FADF32BB5D0EC84FAD1ADC0992190DC771100D9C642195B`, and
executable SHA-256
`7A986AB4D555C768A9F391A238E169F536E4D9331F520CDA1337717345841C4A`.

## Strict i486 audit

The complete strict gate passed: 403 exact native/annotated object proofs,
313,315 linked instructions across 435 executable text ranges, zero above-i486,
unknown, or exempt instructions, and final mapping of 2,377 CODE ranges plus 35
DATA ranges. Startup proof covered 1,660 loaded bytes and 529 code rows; the
CWSDPMI provider audit verified 9,207 instructions with zero exemptions.
