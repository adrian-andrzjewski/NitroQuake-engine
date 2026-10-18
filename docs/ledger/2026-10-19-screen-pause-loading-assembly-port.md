# Pause and loading overlays move to i486 assembly (2026-10-19)

## Behavior and selector

`SCR_DrawPause` and `SCR_DrawLoading` now resolve to assembly entries when
`ScreenOverlaysImplementation=asm`. The C implementations remain available as
the BENCH oracle and through the C-reference profile. Both assembly paths retain
the existing `Draw_CachePic` and `Draw_Pic` calls, path strings, visibility
conditions, and centered placement.

`SCR_DrawPause` tests `scr_showpause.value` with the same x87 compare/status-bit
sequence emitted by the i486 C build, then checks `cl.paused`. This preserves the
compiled C behavior for positive and negative zero and unordered NaN values.
Both overlays use unsigned 32-bit subtraction before halving the horizontal and
vertical placement expressions, including the original underflow behavior when
an image exceeds the viewport.

## Direct C/assembly parity

The DOSBox-X fixture passes 10 exact C/ASM cases: pause positive-zero, negative-
zero and not-paused suppression; standard odd-size centering; unsigned viewport
underflow; the C build's NaN comparison branch; loading suppression; widescreen
centering; positive odd truncation; and unsigned underflow. Every visible case
compares the exact cache path, single draw, picture pointer, x/y coordinates,
preserved globals, x87 control word, and ABI. The existing eight-case screen
overlay dispatch fixture passes in the same run.

Run the focused parity fixture with:

```powershell
tools/bench-dos.ps1 -SkipIsaAudit -ScreenOverlaysOnly -ScreenOverlaysImplementation asm -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the i486 instruction proof.

## Strict i486 release verification

The non-BENCH release executable was built with:

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm -CpuTarget i486 -NoBootstrap
```

The strict gate passed 124,689 project-object instructions and 162,986 linked
instructions. It verified 400 exact objects, 418 source-bound runtime inputs,
1,459 CODE ranges and 35 DATA ranges, plus 529 startup rows and 9,207 maintained
CWSDPMI provider instructions. Above-i486, unknown, and exempt instruction
counts were zero; the linked audit reported zero non-instruction bytes and
relocation data sites.

The production ownership inventory reports 405 directly reachable renderer
entries, of which 32 remain C-owned: 373/405, or 92.1%, are assembly-owned by
reachable-symbol count. The call graph remains incomplete, with 38 unresolved
direct callees and `completeCallGraph=false`. This is a production-profile symbol
count estimate, not a weighted measure of implementation effort.

## Scope and remaining work

This slice owns pause/loading visibility and placement logic in assembly. The
asset-cache and raster calls remain delegated to the existing drawing interface.
It does not establish complete-scene image parity or measure FPS. Those checks,
the unresolved renderer graph, menu and video C dependencies, and broader
long-run coverage remain open.
