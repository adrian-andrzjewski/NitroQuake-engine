# Expanded 83-selector i486 VESA checkpoint (2026-10-09)

## Candidate identity and strict machine-code gate

The opt-in `i486-asm-selectable-83` profile selects `asm` for all 83 declared
renderer selectors. It extends the accepted 77-selector profile with dispatch,
drawing-driver, view-control, framebuffer-drawing, chase-camera and world-control
entries. The candidate executable SHA-256 is
`26BB3236B17E310E5376157DBA8DF8372BAE36DAD15259A756164C97D1822234`.

The paired DOSBox-X run used `CpuTarget=i486`. Exact source proofs covered all
123 project objects and 235 installed runtime objects. The candidate passed
the linked and independently relocated executable checks over 240,817
instructions, the 1,660 loaded startup bytes / 529 code rows, and 9,207
CWSDPMI instructions. The final mapping contained 352 source-bound code
contributions and 1,821 relocated ranges. All stages reported zero
post-i486 instructions, unknown instructions, exemptions, or opcode
mismatches. The profile and matching C reference share source-tree fingerprint
`7C94D1854C15A26AFE15725E2FE799596C02D2D848978247A5692BCDB964C8EB`.

## Exact parity for the VESA scene

The reference and candidate each completed `demo1-vesa-full` once. Their
frame-checksum streams contained 970 frames; after ignoring six warmup frames,
all 964 compared checksums matched exactly. The selected frame-169 320x200
indexed framebuffer and palette also matched exactly: zero of 64,000 pixel
indices and zero palette bytes differed.

The reference ran at 12.684 FPS and the candidate at 12.557 FPS in this one
measurement, about 1.0% slower. This is a bounded performance observation, not
a completion criterion. This single-scene checkpoint does not replace the
77-selector profile's six-scene comparison or establish broad 83-selector
coverage. The paired report is
`out/render-parity-selectable-83-vesa-strict-20261009/render-parity-result.json`.

## Current ownership inventory and remaining work

The candidate object inventory reports 602 renderer entries, 407 directly
reachable entries and 25 directly reachable renderer C functions. It also
reports 63 reachable entries containing 148 indirect transfer sites and 33
unresolved direct callees. The report explicitly is not a complete call graph;
indirect targets, renderer initialization/debug/support paths and the remaining
C dependencies still require review. See
`out/renderer-ownership-selectable-83-strict-20261009.json`.

The full renderer, broad clipping/extreme-camera scenarios, long-running
stability and memory-corruption checks, wider gameplay coverage, and human
visual/gameplay acceptance remain open. DOSBox-X's i486 target is not a genuine
486 execution result.

## Host-side startup proof helper

The strict gate previously stopped when the optional Windows GCC used to build
the DJASM proof helper was unavailable. The verification bundle now includes a
hash-bound, host-only prebuilt helper fallback. It is used only to reproduce the
embedded startup source; the final DOS executable bytes still undergo the
normal source-bound and instruction audits. Tampering with the helper is
rejected by `tools/test-djgpp-assembler-tool.py`. This Windows helper is not
linked into the 486 target.

## Reproduction command

From the `quake` directory, choose a fresh output root for a rerun:

```powershell
.\tools\render-parity-dos.ps1 `
  -ReferenceProfile 'tools/renderer-profiles/i486-c-reference.json' `
  -CandidateProfile 'tools/renderer-profiles/i486-asm-selectable-83.json' `
  -Scenario demo1-vesa-full -RunsOverride 1 `
  -OutputRoot 'out/render-parity-selectable-83-vesa-strict-20261009' `
  -CpuTarget i486 -TimeoutSeconds 600 -NoBootstrap
```
