# VESA resource lifecycle moves to i486 assembly (2026-10-19)

## Behavior and selector

`VesaLifecycleImplementation=asm` now selects assembly for
`VID_ExtraReleaseMode`, `VID_ShutdownExtra`, and `VID_ExtraPaletteOK` in the
i486 profile. The C-reference profile keeps the C implementation; BENCH builds
also retain named C oracle entries. Release clears the mapping, video base, and
current mode, restores the palette-ready flag, and shutdown frees the palette
buffer when present.

## Direct C/assembly parity

The focused DOSBox-X fixture passed 18 cases: both palette-ready values and the
release/shutdown state matrix for mapped/unmapped state, present/absent palette,
video base, and current mode. It compares resulting state, resource-release
order and pointers, mapping contents, and callee-saved registers/stack. Result:
18 cases, zero failures.

Run the focused fixture with:

```powershell
tools/bench-dos.ps1 -VesaLifecycleImplementation asm-fixture `
  -VesaLifecycleOnly -CpuTarget i486 -NoBootstrap -SkipIsaAudit `
  -TimeoutSeconds 240
```

`-SkipIsaAudit` makes that run a diagnostic runtime check; the release gate
below provides the strict i486 instruction proof.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -CpuTarget i486 -NoBootstrap
```

The release build passed the complete executable ISA gate: 161,923 linked
instructions, 529 startup CODE rows, and 9,207 runtime-provider instructions,
with zero above-i486 instructions, unknown instructions, or exemptions. The
project and runtime proofs covered 166 and 235 exact objects respectively; 401
exact native/annotated object proofs passed.

The refreshed non-BENCH inventory at
`out/profile-a3c280898cb47905/renderer-ownership-release-20261019-vesalifecycle.json`
contains 412 directly reachable renderer entries, 13 direct C owners, and 38
unresolved direct callees. Its assembly-owned share is 399/412, or 96.8%, by
reachable-symbol count. The graph remains incomplete and does not weight
functions by size or complexity.

## Scope and remaining work

This slice covers the VESA cleanup state machine and palette-ready query. The
DPMI mapping and DOS-memory release routines remain external system calls.
VESA discovery, BIOS palette programming, hardware mode changes, and the wider
renderer ownership/call-graph review remain open. This work establishes neither
FPS improvement nor full-scene visual parity.
