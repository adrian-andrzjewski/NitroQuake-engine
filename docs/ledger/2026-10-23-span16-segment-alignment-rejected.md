# Reject sixteen-byte alignment of the Span16 segment loop (2026-10-23)

The candidate added `.p2align 4,,15` immediately before `LNotLastSegment` in
`src/renderer/d_draw16.s`. This aligns the repeated 16-pixel segment entry. The candidate
retained exact output and passed the complete strict i486 gates, but was slower
than a fresh control. The directive has been removed.

Both variants used the same uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI,
and pinned 32 MB i486 profile
`out/dosbox-x-486-high-32mb-profile.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Each
ran three times; every run rendered 969 frames with framebuffer checksum
`1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Fresh control | 15.626485, 15.626521, 15.626484 | 15.626496667 | 0.000037 |
| Aligned candidate | 15.615725, 15.615745, 15.615735 | 15.615735000 | 0.000020 |

The candidate delta is **−0.010761667 FPS (−0.06886%)**. All output checksums
matched. The complete strict i486 audit passed with zero above-i486, unknown,
or exempt instructions; the candidate's linked audit verified 313,895
instructions across 435 executable ranges, plus 529 startup rows and 9,207
DPMI-provider instructions.

Artifacts:

- Fresh control: `out/dos-timedemo-20261023-194427/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261023-193937/timedemo-result.json`
- Candidate build and ISA reports: `out/local-dos-timedemo-span16-align-20261023/`

Candidate source-tree fingerprint:
`E07D45AF069A1A18633792FB231385CD9E003C6D7734312E3C6077EA1ACF003C`.
