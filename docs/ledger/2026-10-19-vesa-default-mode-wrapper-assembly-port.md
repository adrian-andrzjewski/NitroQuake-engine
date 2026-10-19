# VESA default-mode wrapper moves to i486 assembly (2026-10-19)

## Behavior and selector

`VID_ExtraDefaultMode` now loads the active VESA mode list and the
`VID_ExtraInitMode` function pointer in assembly, then calls the existing
assembly selector. The C-reference profile retains its original C selection
path, and BENCH builds retain `VID_ExtraDefaultMode_C` as the reference
wrapper. The assembly implementation is selected with
`VesaDefaultModeImplementation=asm`.

## Direct C/assembly parity

The focused DOSBox-X VESA default-mode fixture passes. In addition to the
existing selector matrix, four wrapper cases exercise the public assembly
entry against the C oracle using the live `pvidmodes` pointer. The cases cover
an empty list, banked fallback selection, a later linear-mode preference, and
size-mismatched entries. They verify the selected index, read-only state, and
callee-saved register/stack integrity.

Run the focused fixture with:

```powershell
tools/bench-dos.ps1 -VesaDefaultModeImplementation asm-fixture `
  -VesaDefaultModeOnly -CpuTarget i486 -NoBootstrap -SkipIsaAudit `
  -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the i486 instruction proof.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -VesaDefaultModeImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed the 165-object project proof, 235 runtime source
proofs, 400 exact object proofs, and the complete linked executable gate. It
verified 162,463 relocated instructions, 529 startup rows, and 9,207 CWSDPMI
provider instructions with no above-i486, unknown, exempt, or unclassified
instructions or bytes. The production ownership report confirms
`_VID_ExtraDefaultMode` is owned by `vid_vesadefaultmodeasm.s` as assembly.

The refreshed report contains 409 directly reachable renderer entries, of
which 26 remain C-owned: 383/409, or 93.6%, are assembly-owned by
reachable-symbol count. The ownership scanner now recognizes `vid_*.s`
assembly sources, so the exported video entry is included in the source
inventory. The call graph remains incomplete, with 38 unresolved direct
callees. This is a profile-specific symbol-count estimate, not a weighted
measure of implementation effort.

## Scope and remaining work

This ports the public VESA default-mode wrapper; it does not port the BIOS
mode scan, hardware mode setup, or video cleanup paths. It does not measure FPS
or establish full-scene visual parity. The broader renderer port and
call-graph review remain open.
