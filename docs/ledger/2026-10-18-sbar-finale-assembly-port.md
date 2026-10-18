# Finale overlay composition moves to i486 assembly (2026-10-18)

## Behavior and selector

`Sbar_FinaleOverlay` now selects its assembly entry in the default i486 status-
bar draw profile. It sets `scr_copyeverything`, loads `gfx/finale.lmp` through
`Draw_CachePic`, and calls `Draw_TransPic` at y=16 using the original centering
expression. The C body remains available as the BENCH oracle and in the
C-reference profile.

`vid.width` is unsigned. Therefore `(vid.width-pic->width)/2` uses modulo-32-bit
unsigned subtraction before division. The assembly preserves that legacy
behavior with subtraction followed by a logical right shift. For a picture wider
than the viewport, the resulting large positive x coordinate is intentional C
parity.

## Direct C/assembly parity

The focused status-bar fixture now recognizes the finale cache path and gives it
a dedicated `qpic_t`. Six exact C/ASM cases compare cache and draw events,
centering, state, and ABI:

- 320-wide standard centered image;
- 640-wide image in a widescreen viewport;
- odd, one-pixel, and even unsigned-underflow width differences;
- positive odd width difference.

All six passed under DOSBox-X. The checks also confirm one cache request for
`gfx/finale.lmp`, one transparent draw at y=16, `scr_copyeverything=1`, preserved
`scr_fullupdate`, unchanged scoreboard state, and a clean ABI check. The full
status-bar draw fixture passed all existing draw, face, mini-scoreboard,
deathmatch, and intermission cases as well.

## Strict i486 verification

Reproduce the focused BENCH build and fixture with:

```powershell
tools/bench-dos.ps1 -SbarDrawOnly -SbarDrawImplementation asm-fixture -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

The strict BENCH gate passed with 251,637 project-object instructions and
289,934 linked instructions. The final executable proof bound 431 source
contributions to 2,298 CODE ranges and 34 DATA ranges; the gate also checked 529
startup rows and 9,207 provider instructions. Above-i486, unknown, and exempt
instruction counts were zero.

The production, non-BENCH release path was built and audited with:

```powershell
tools/build-dos.ps1 -SbarDrawImplementation asm -CpuTarget i486 -NoBootstrap
```

That gate passed 124,682 project-object instructions and 162,979 linked
instructions, with 417 source-bound contributions, 1,461 CODE ranges, 34 DATA
ranges, 529 startup rows, and 9,207 provider instructions. It also reported
zero above-i486, unknown, or exempt instructions.

The refreshed full-profile BENCH ownership report lists 366 directly reachable
renderer entries and 47 directly reachable C dependencies: 319/366, or 87.2%,
are assembly-owned by reachable-symbol count. The report still has 82 unresolved
direct callees and `completeCallGraph=false`; this percentage remains a rough
profile-specific progress estimate rather than a complete ownership proof.

## Scope and remaining work

This slice ports the finale overlay entry point. It does not measure FPS or
establish full-scene visual/gameplay parity. Full-scene checks, FPS measurement,
the incomplete renderer call graph, and the remaining C-owned screen, menu,
video, and console services remain open.
