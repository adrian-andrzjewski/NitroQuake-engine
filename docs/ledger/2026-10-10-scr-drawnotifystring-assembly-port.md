# `SCR_DrawNotifyString` -> i486 assembly port (2026-10-10)

`SCR_DrawNotifyString` in `src/client/screen.c` prints the centered notify block by
walking newline-delimited text, positioning the character cursor, and calling
`Draw_Character`. `src/client/screen_notifyasm.s` now provides the selectable
`SCR_DrawNotifyString_asm486` implementation. The `ScreenNotifyImplementation`
selector keeps C as the default; the assembly path is opt-in so scene-level
selection remains a separate acceptance step.

The port preserves the reference's integer width/height behavior, x87
truncation and rounding state, character order, line consumption and draw
limits. The direct fixture covers 19 inputs across four x87 rounding-control
settings, with all three precision-control settings also exercised for the
high-bit width/height cases. It compares the C oracle, direct assembly entry
and public selector for character-call traces, the complete bounded indexed
framebuffer and guards, video state, x87 control word and ABI preservation.

Validation for the committed slice:

- `python tools/test-rendering.py`: 84 tests passed.
- `python tools/test-build-dos.py`: passed with the assembly source pinned in
  the i386 and i486 build manifests.
- Strict project-object audit: 138 objects and 170,383 instructions; zero
  above-i486, unclassified or exempted instructions.
- Linked/runtime audit: 373 objects and 208,680 instructions; zero
  above-i486, unclassified, exempted or undecoded instructions. The complete
  executable audit covered 208,680 relocated instructions, 368 source-bound
  CODE contributions, 1,667 CODE ranges and 13 DATA ranges.
- Startup and external provider checks passed: 529 startup CODE rows / 1,660
  loaded bytes, and 9,207 CWSDPMI instructions, with no violations or
  exemptions.
- The same i486-targeted executable passed under DOSBox-X: all 19 notify cases
  passed with zero failures.

This establishes the selected slice's direct parity and instruction-set
compatibility. It does not establish combined-profile or full-scene parity, and
it makes no performance claim. `Draw_Character`, other console and notify
paths, menu/status overlays, and `_SCR_UpdateScreen` remain separately owned
work. The relevant source-to-test mapping is `SCR_DrawNotifyString` ->
`SCR_DrawNotifyString_asm486` -> `src/tests/bench486/bench486_screennotify.h`.

To reproduce the host checks, run `rtk python tools/test-rendering.py` and
`rtk python tools/test-build-dos.py`. To rebuild, audit and execute the focused
fixture on the i486 DOSBox-X profile, run:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -ScreenNotifyOnly `
  -ScreenNotifyImplementation asm -CpuTarget i486 -NoBootstrap `
  -TimeoutSeconds 300
```
