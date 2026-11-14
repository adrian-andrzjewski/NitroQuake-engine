# Fold turbulent T-index scaling into its shift and mask (2026-10-27)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 audit.

The turbulent pixel macro formed the T texel coordinate with a right shift by
16, a mask to 6 bits, and a left shift by 6. The new sequence shifts right by
10 and masks the already-positioned index bits. It selects the same original
bits 16 through 21 while removing one instruction from each sampled pixel.

Both variants used DOSBox-X 2026.08.31, `demo1`, and the pinned 32 MB i486
profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Pooled FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261027-071815/timedemo-result.json` | 16.178397 / 16.178429 / 16.178426 | 16.178417750 |
| Fused T index | `out/dos-timedemo-20261027-085048/timedemo-result.json` | 16.194468 / 16.194497 / 16.194488 | 16.194484449 |

The pooled gain was **+0.016066699 FPS (+0.099309%)**. All six runs rendered
969 frames with framebuffer checksum `1047377823`.

The full strict i486 gate passed: 403 exact object proofs, 314,271 linked
instructions, 529 startup instructions, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. The build reduced the linked
instruction count by 29 versus control. The change is active in
`src/renderer/d_scana.s`; audit and timedemo artifacts remain under `out/`.
