# `d_drawspans` dispatch closure and parity (2026-10-09)

## Original dispatch path

`D_DrawSurfaces` invokes the global `_d_drawspans` function pointer. The
selected assembly `D_SetupFrame` assigns that pointer to `D_DrawSpans16` when
`d_subdiv16` is enabled and to `D_DrawSpans8` when it is disabled. The kernels
remain the existing routines in `src/d_draw16.s` and `src/d_draw.s`; this slice
adds executable ownership evidence and deterministic coverage for both modes.

The ownership report resolves the consumer load and indirect call, the two
relocation-backed target assignments and their shared pointer store, and the
assembly definitions of both targets. Its proof is deliberately bounded to the
selected `_D_SetupFrame`: it does not enumerate other possible writers to
`_d_drawspans`.

## Verification

The ownership audit on the combined 84-selector profile reported 614 renderer
entries, 370 directly reachable entries, 18 reachable C entries and 41
unresolved direct C callees. The span-dispatch proof found one selected setter
target set, with `_D_DrawSpans8` owned by `d_draw.s` and `_D_DrawSpans16` owned
by `d_draw16.s`. Its report was
`out/renderer-ownership-drawspans-20261009.json`.

The reference executable and the combined assembly executable both passed the
full i486 executable/runtime instruction audit with zero above-i486 or unknown
instructions and zero exemptions. The assembly audit covered 245,179 relocated
instructions, 529 startup rows and 9,207 provider instructions. The focused
ownership and rendering-manifest tests also passed.

## Reference parity

The deterministic DOSBox-X i486 comparison passed for both dispatch choices.
For `demo1-vesa-full` (`d_subdiv16 1`, `D_DrawSpans16`), all 964 post-warmup
frame checksums in each repeated run matched; the timedemo checksum was
`1047377823`. For `demo1-drawspans8` (`d_subdiv16 0`, `D_DrawSpans8`), all 964
post-warmup checksums matched and the timedemo checksum was `3987640479`.
Frame 169 in each scenario matched all 64,000 palette indices and the complete
palette exactly. The separate committed golden for span8 also passed both the
C-reference and assembly single-run validation with zero changed pixels and
zero channel tolerance.

Measured median frame rates were 12.68 / 12.55 FPS (C / assembly) for the
16-pixel mode and 11.77 / 11.66 FPS for the 8-pixel mode. These paired scene
measurements show no material regression in this slice; they are not a broad
performance survey.

The reproducible paired comparison command is:

```powershell
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-c-reference.json `
  -CandidateProfile tools/renderer-profiles/i486-asm-selectable-84.json `
  -Scenario demo1-vesa-full,demo1-drawspans8 `
  -OutputRoot out/render-parity-drawspans-20261009 `
  -CpuTarget i486 -TimeoutSeconds 600 -NoBootstrap
```

The accepted results are recorded in
`out/render-parity-drawspans-20261009/render-parity-result.json`.

## Scope boundary

This checkpoint verifies and tests the selected span-kernel dispatch path. It
does not convert either span kernel in this change and does not complete the
renderer migration. Further renderer subsystems and whole-program compatibility
closure remain open.
