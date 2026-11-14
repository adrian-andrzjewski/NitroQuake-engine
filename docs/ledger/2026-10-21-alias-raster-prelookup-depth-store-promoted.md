# Alias-raster pre-lookup depth store promoted (2026-10-21)

Status: historically promoted under the positive-mean rule. A 2026-10-26
current-source recheck found a negative mean, so the active source keeps the
control schedule; details are below.
For every passing pixel, the assembly stores the Z word immediately after the
texture texel load and before selecting the light byte and looking up the
colormap. Each self-modifying `LPatch*` label remains immediately after its
colormap lookup.

The comparison used three alternating control/candidate pairs on the pinned
DOSBox-X 2026.08.31 i486 `demo1` profile, with CWSDPMI and per-frame FPS
collection disabled. The control is the preceding promoted schedule, which
stores Z after the colormap lookup. All samples completed 969 frames and
produced framebuffer checksum `1047377823`.

| Pair | Control seconds | Control FPS | Candidate seconds | Candidate FPS | Paired delta |
|---:|---:|---:|---:|---:|---:|
| 1 | 62.366096 | 15.537288 | 62.366043 | 15.537301 | +0.000013 FPS |
| 2 | 62.366080 | 15.537292 | 62.366085 | 15.537291 | −0.000001 FPS |
| 3 | 62.366094 | 15.537289 | 62.366069 | 15.537295 | +0.000006 FPS |

The control mean was **15.537289667 FPS** and the candidate mean was
**15.537295667 FPS**, a pooled gain of **+0.000006 FPS (+0.0000386%)**. The
gain is smaller than the run-to-run spread and one pair was marginally slower;
the positive pooled mean qualifies under the current rule.

The measured diagnostic candidate was
`out/alias-raster-store-after-texel-candidate/qbench.exe`, SHA-256
`897157F273AD8700682CF47D63B0338E8C0F08FEEDBC8AD34A1F4DFE1EE7046B`. The
strict build produced `out/profile-c86686d2e5e2448c/qbench.exe`, SHA-256
`5F7D255C0E6E19CEAF1E3B755C3FBAB3CC6389ED33F53AF86D9364A48C7A69D8`. Both
files are 1,451,520 bytes and differ only in seven ASCII digits in two embedded
`Exe:` build-time strings. The strict executable passed a direct pinned-profile
parity run at **15.537297 FPS**, 969 frames, checksum `1047377823`.

The strict linked i486 audit passed with 313,316 relocated instructions across
435 executable ranges and zero above-i486, unknown, or exempt instructions.
The final source map covered 2,377 CODE and 35 DATA ranges. Embedded startup
proof covered 1,660 loaded bytes and 529 code rows with zero exemptions; the
exact CWSDPMI provider passed its 9,207-instruction audit with zero exemptions.
Manifest: `out/profile-c86686d2e5e2448c/build-manifest-bench.json`.

The A/B summary and run reports are in
`out/alias-raster-store-after-texel-ab-label-fixed-20261021/`; the strict-binary
runtime result is in `out/alias-raster-store-after-texel-strict-parity-20261021/`.
The measured comparison used the pinned root
`out/dos-timedemo-20261020-224647/`, profile template SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and
generated A/B config SHA-256
`212CCD7575B966E9067A67F3B16380322502CFB7BD577C5245D19BCC35777FEC`.

## Current-source recheck (2026-10-26)

The candidate was compared again after the committed edge-surface setup change.
The control restored the original Z-store schedule in `src/renderer/d_polysa.s`; the
candidate recheck differed only by moving the store after the texel load and
before light/colormap work. Both used the pinned profile above, aggressive
selectors, and 969-frame `demo1` runs with checksum `1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS | ISA audit |
|---|---|---|---:|---:|---|
| Current-source control | `out/dos-timedemo-20261026-014533/timedemo-result.json` | 15.942837 / 15.942841 / 15.942879 | 15.942852333 | 15.942841 | PASS |
| Pre-lookup candidate, prior strict run | `out/dos-timedemo-20261026-005503/timedemo-result.json` | 15.942846 / 15.942847 / 15.942840 | 15.942844333 | 15.942846 | PASS |

The current-source control mean is higher by **0.000008 FPS (0.00005018%)**.
The same-direction parity screen was also negative for the candidate:
15.942851667 FPS versus 15.942862333 FPS for control. The strict control's
source-tree fingerprint is
`55E9EF2E87DAB15E6D91A16AF984ED9D6C3A3151BB5A11E2ACD6C8A124EFB5B9`; the
candidate fingerprint is
`4083E4EB3B822EE8B1CB9963B728E839068CDC8C7B315C11F42D67B27A4D8595`.
The schedule is therefore not retained in the current source.
