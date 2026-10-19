# DOS video-mode menu renderer in i486 assembly

## Video mode menu behavior and selector

`VID_MenuDraw` now renders the DOS video-mode list in `screen_overlaysasm.s`.
It preserves the existing mode enumeration rules: skip mode 1, discard null
descriptions, merge duplicate descriptions with the original mode-zero rule,
cap the list at 33 entries, mark the selected mode, draw the testing/default
messages, and place the animated cursor in the same column layout. The
`M_Video_Draw` callback wrapper also selects assembly and calls the active
`vid_menudrawfn` indirectly, matching the existing C wrapper.

Both entries follow `ScreenOverlaysImplementation=asm`, which is selected in
the current i486 assembly profile. The original implementations remain
available as `VID_MenuDraw_C` and `M_Video_Draw_C` in BENCH builds. A shared
`vid_menu_mode_description_t` layout now has compile-time checks for its 12-byte
stride and the `desc` and `iscur` field offsets used by assembly.

## Direct C/ASM parity matrix

`Bench486VIDMenuDrawCases` compares four synthetic mode lists under three x87
precision settings and four rounding modes, for 48 exact C/assembly cases. The
cases cover duplicate and missing descriptions, the mode cap and three-column
layout, single-column cursor placement, selected and testing modes, four video
widths, and cursor timing near a rounding boundary. It compares the final mode
table, cache and picture event order, glyph positions and values, ABI state,
and x87 control word. The separate dispatcher check verifies that both
`M_Video_Draw` versions invoke the active callback once.

Focused reproduction:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -ScreenOverlaysOnly -ScreenOverlaysImplementation asm -CpuTarget i486 `
  -SkipIsaAudit -NoBootstrap -TimeoutSeconds 180
```

Result: the video-menu fixture passed all 48 cases and the complete focused
screen-overlay suite reported `486 benchmark correctness PASS`. The diagnostic
run skipped its ISA audit; the strict release gate below supplies that proof.

## Strict i486 release audit and current ownership

Strict reproduction:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/build-dos.ps1 `
  -ScreenOverlaysImplementation asm -CpuTarget i486 -NoBootstrap
```

The release completed all source, linked-executable, startup, and provider
proofs. The linked audit verified 161,353 opcodes with zero above-i486,
unclassified, exempt, or relocation-data exceptions. It proved 402 exact
native/annotated objects, 420 source-bound contributions, 1,443 CODE ranges,
35 DATA ranges, 529 startup CODE rows, and 9,207 provider instructions.

The refreshed ownership inventory contains 605 renderer entries, with 415
directly reachable and 7 directly C-owned: 408/415, or 98.3%, are
assembly-owned by reachable-symbol count. The graph still has 38 unresolved
direct callees and is incomplete; this count is a profile-specific estimate,
not a size- or complexity-weighted measure. The seven remaining direct C owners
are `_Con_DPrintf`, `_Con_DebugLog`, `_Con_Printf`, `_M_LanConfig_Draw`,
`_M_Search_Draw`, `_M_SerialConfig_Draw`, and `_M_ServerList_Draw`.

## Remaining video-menu port scope

This closes the C-owned video-menu renderer and callback wrapper. The cache and
zone-heap paths already select assembly in the current profile. The remaining
direct C menu and console paths, unresolved callees, full-scene parity, and
performance measurement remain open. No FPS result is claimed.
