# Surface-cache unused style lookup removed (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

In `D_CacheSurface`, the cache-hit check for `styles[1]` now tests the unused
style sentinel (`255`) before indexing `d_lightstylevalue`. The old order read
`d_lightstylevalue[255]` and discarded that value on single-style surfaces.
The new order skips that table read for the unused-style case. Cache misses
still resolve and store all four light-style values, and the existing
`D_CacheSurfaceHit_asm486` reference already checks the sentinel before reading
the second style key.

## Matched timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI
`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`, the
pinned 32 MB i486 profile `tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), and
the local benchmark data root `out/benchmark-data-20261028-aliasx`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261028-023932/timedemo-result.json` | 16.229258 / 16.229257 / 16.229257 | 16.229257333 | 16.229257 |
| Candidate parity screen | `out/dos-timedemo-20261028-030306/timedemo-result.json` | 16.229632 / 16.229637 / 16.229638 | 16.229635667 | 16.229637 |
| Strict candidate | `out/dos-timedemo-20261028-032913/timedemo-result.json` | 16.229634 / 16.229628 / 16.229629 | 16.229630333 | 16.229629 |

The strict candidate gained **0.000373 FPS (+0.0022983%)** over the strict
control. Its six-micro-FPS spread is stable, and every candidate sample exceeds
every control sample. All runs completed 969 frames with framebuffer checksum
`1047377823`. A fresh parity-only control block immediately before the change
had median `16.229252` FPS and one slow `16.106616` FPS sample; its median
agrees with the prior strict control.

## i486 proof

The strict candidate has `visualParityOnly=false`, `diagnosticOnly=false`, and
`isaAuditStatus=PASS`. The complete gate verified 314,234 linked instructions,
529 startup code rows, and 9,207 provider instructions, with zero above-i486,
unknown, or exempt instructions. The source map verified 403 exact native or
annotated object proofs and 435 source-bound contributions across 2,376 CODE
ranges and 35 DATA ranges.

- Source fingerprint: `E5EC11EB5C7E3711FF1D3BAFBDF963080904F14D4260D99E144C6AA4D04BDC56`
- Source-tree fingerprint: `26907093DFB4EA6FE60BE0541538768F410DDF0CA04482558FAB623F7B30E1F3`
- Build manifest SHA-256: `449FD35DD42EFB09A89D281D824E3D4979225581CD541373030884B75391ACF6`
- Executable SHA-256: `BC9162816D92C608A8A4FF400A72FC8FCCBB0B91FB2F70B298160616721BEF20`
- Linked report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`
- Final strict report: `out/profile-107ff6406936b458/isa-qbench/relocated-20261028-042314981/strict-isa.json`

The timedemo stored no host-window image (`frameCaptureIndex` is null). Its
checksum establishes framebuffer parity but does not verify the visible DOSBox
window or resolve the reported black display.
