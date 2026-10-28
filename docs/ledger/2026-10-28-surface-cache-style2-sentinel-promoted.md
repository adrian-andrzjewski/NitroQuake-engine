# Surface-cache second style sentinel check (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

On a `D_CacheSurface` cache hit, the `styles[2]` byte is now checked for the
terminating sentinel (`255`) before reading `d_lightstylevalue`. If it is the
sentinel, the active style list has ended, so both that lookup and the later
`styles[3]` lookup are unnecessary. The miss path still resolves and stores
all four light-style values. `MAX_LIGHTSTYLES` is 64, so table slot 255 is
outside the runtime light-style range.

## Matched timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, and the
pinned 32 MB i486 profile `tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261028-032913/timedemo-result.json` | 16.229634 / 16.229628 / 16.229629 | 16.229630333 | 16.229629 |
| Strict candidate | `out/dos-timedemo-20261028-043201/timedemo-result.json` | 16.229704 / 16.229715 / 16.229718 | 16.229712333 | 16.229715 |

The candidate gained **0.000082 FPS (+0.000505%)**. Each run completed 969
frames with framebuffer checksum `1047377823`. The three candidate samples
were all above the three strict control samples.

## i486 proof

The strict candidate has `visualParityOnly=false` and
`isaAuditStatus=PASS`. The linked audit verified 314,235 instructions, plus
529 startup code rows and 9,207 provider instructions, with zero above-i486,
unknown, or exempt instructions. The source map verified 403 exact native or
annotated object proofs and 435 source-bound contributions across 2,376 CODE
ranges and 35 DATA ranges.

- Source fingerprint: `740D0CB7E5DC1B95AF2A85929B9F4D6B9F26A79501E25C5D6007F435F0B07B67`
- Source-tree fingerprint: `B5717A41CA775F4244CEEC5375DD32DB31A31A1C0F27873DF802C41F6D0F8295`
- Build manifest SHA-256: `94B70CF901B36D5D5ADADBBF8E9C1B42D3C5030CA151B86DD1F06AC0B7D3B8ED`
- Executable SHA-256: `B2BEA9758A9B69726E34E7E532C6A5E6D4C97E1AA04821604599181F1418B8DA`
- Linked report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`
- Final strict report: `out/profile-107ff6406936b458/isa-qbench/relocated-20261028-052607239/strict-isa.json`

## Display diagnostic

A separate visual-only capture at frame 512 is stored at
`out/dos-timedemo-20261028-043546/runs/run-01/frame.png`. The 320x200 Quake
frame contains the map and HUD, 129 distinct RGB colors, and about 19.2% pure
black pixels; its mean RGB is approximately `(19, 14, 8)`. The generated
`CONFIG.CFG` used `gamma 1.0`, which leaves the darkest presentation. This
capture reads Quake's framebuffer and does not capture DOSBox-X's host window,
so it cannot confirm whether the visible window itself is black.
