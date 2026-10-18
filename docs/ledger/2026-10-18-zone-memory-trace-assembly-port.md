# Zone, cache, and hunk diagnostic traces move to i486 assembly (2026-10-18)

## Behavior and selector

The default i486 `ZoneHeapImplementation=asm` path now owns the trace adapters
used by `Z_Print`, `Cache_Print`, `Cache_Report`, and `Hunk_Print`:
`Zone_PrintTrace`, `Zone_CachePrintTrace`, `Zone_CacheReportTrace`,
`Zone_HunkPrintTrace`, and `Zone_HunkPrintError`. The assembly adapters preserve
the existing console format strings and argument order. C implementations stay
available in the C-reference profile and as independent BENCH oracles.

## Exact C/ASM fixture

Reproduction command:

```powershell
tools/bench-dos.ps1 -ZoneHeapOnly -ZoneHeapImplementation asm-fixture -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

The DOSBox-X fixture passed with failure mask `0x0`. Its direct comparisons
include six zone-print cases, three cache-print cases, eight hunk-print cases,
and eight cache-report cases. BENCH keeps C trace oracles separate from the
assembly callbacks, so both traversal and event arguments are compared.

## Strict i486 verification

The BENCH strict gate passed: 253,050 project-object instructions, 291,347
linked-object and linked-executable instructions, 431 source-bound
contributions, 2,268 CODE ranges, 529 startup rows, and 9,207 provider
instructions; zero above-i486, unknown, or exempt instructions.

The production, non-BENCH release path was also built with
`tools/build-dos.ps1 -ZoneHeapImplementation asm -CpuTarget i486 -NoBootstrap`.
Its real console-formatting assembly branches passed the complete strict gate:
162,980 linked-object and executable instructions, 417 source-bound
contributions, 1,463 CODE ranges, 529 startup rows, and 9,207 provider
instructions; zero above-i486, unknown, or exempt instructions.

## Scope and remaining work

The cache, zone-heap, and hunk algorithms and their diagnostic trace adapters
now select assembly in the i486 release profile. The adapters still call the
shared C console services `Con_Printf`, `Con_DPrintf`, and `Sys_Error`; those
services are separate remaining console ownership work. This diagnostic slice
does not measure FPS or establish full-scene parity. See also the
[zone heap and cache algorithms ledger](2026-10-17-zone-heap-assembly-port.md).
