# Lightmap dispatcher assembly recheck rejected (2026-10-28)

Status: `LightMapBuildImplementation=c` remains the i486 release default. The
assembly dispatcher stays available as a reference path, but it was slower in
this matched three-run comparison.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. The selector manifests differ only in
`LightMapBuildImplementation` (`asm` control versus `c` candidate). The source
tree fingerprint was identical. All runs completed 969 frames with framebuffer
checksum `1047377823`; both builds passed the strict i486 ISA audit.

| Variant | Artifact | Run FPS | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Assembly dispatcher control | `out/dos-timedemo-20261028-081215/timedemo-result.json` | 16.238097 / 16.238081 / 16.238103 | 16.238093667 | 16.238097 |
| C dispatcher candidate | `out/dos-timedemo-20261028-093735/timedemo-result.json` | 16.240108 / 16.240112 / 16.240134 | 16.240118 | 16.240112 |

The C dispatcher gained **0.002024333 FPS (+0.0124666%)** by mean. Its median
was also higher by `0.002015 FPS`. The full candidate audit verified 313,523
relocated instructions, 529 startup instructions, and 9,207 DPMI-provider
instructions with zero above-i486, unknown, or exempt instructions.

The standard DOS build already selects C by default, so no source-selector
change was needed. This result closes the earlier pending timedemo comparison:
keep C as the release default and leave the assembly dispatcher selectable for
parity and future measurement.
