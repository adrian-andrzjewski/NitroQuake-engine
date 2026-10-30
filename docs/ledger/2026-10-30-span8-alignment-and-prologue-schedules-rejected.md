# 8-bit span alignment and prologue schedules rejected (2026-10-30)

Status: no candidate retained. The repeated-body alignment had no measured
speed benefit. Reordering the `D_DrawSpans8` span-row load or next-span push
failed exact per-frame checksum parity, despite preserving the final checksum.

All runs used DOSBox-X 2026.08.31, `demo1`, the pinned
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), and
the 320x200 VGA mode. Control source-tree fingerprint:
`FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D`.

The uninstrumented timing command was:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -VisualParityOnly -NoBootstrap
```

The checksum screens used the same command with `-FrameChecksums`; the
combined schedule used `-Runs 3`, and each isolated schedule used `-Runs 1`.

## Repeated 8-pixel body alignment

Adding `.p2align 4,,15` before `LNotLastSegment` in `src/d_draw.s` changed code
placement only. The uninstrumented three-run control at
`out/dos-timedemo-20261030-210749/timedemo-result.json` measured
16.328454 / 16.328482 / 16.328483 FPS (mean 16.328473). The aligned candidate
at `out/dos-timedemo-20261030-212604/timedemo-result.json` measured
16.328469 / 16.328470 / 16.328466 FPS (mean 16.328468333), a delta of
**-0.000004667 FPS (-0.0000286%)**. All six runs completed 969 timedemo frames
with framebuffer checksum `1047377823`. The aligned source tree was
`28BAEAD5E7D732972CF825EA8235C49FC59BB439F6FC9F6AF18B742CB5B6B257`.
Because the result was slightly slower and inside run spread, the alignment
was removed.

## Span-row load and next-span push schedules

Three isolated schedules were screened with `-FrameChecksums` against the
control stream in `out/dos-timedemo-20261030-212012/quake/FRAMECHE.TXT`. The
checksum-instrumented runs are **not timing evidence**: the control fell to
12.746630 FPS from about 16.328 FPS uninstrumented. The replays each reported
970 frame checksums without overflow, and each ended at `1047377823`, but the
per-frame streams differed:

| Candidate | Source-tree fingerprint | Changed frames | First changed frame | Artifact |
|---|---|---:|---:|---|
| Move row-index load and next-span push into initial x87 setup | `E921E0B42F85B0B5FF293C4FB65808A017C1BE496B7BCCE8102B7C74F1317C14` | 32 | 99 | `out/dos-timedemo-20261030-213148/` |
| Move only `espan_t_v` row-index load between the initial FILDs and remaining x87 setup | `0972C59193EB5AF1F6224258BA24380EA0AA16C1E2BCA7E319D6D89A7CD19D75` | 9 | 102 | `out/dos-timedemo-20261030-213803/` |
| Move only the next-span pointer push between the initial FILDs and remaining x87 setup | `11605AB0763BB6302CF806D7EA56D280963BC5ED4576CAC1C0BC9F8A9B2745D3` | 18 | 102 | `out/dos-timedemo-20261030-214106/` |

The `TIMEDEMO.TXT` event traces and final frame checksums match the control.
The intermediate differences are enough to reject all three; no pixel-level
capture was taken to classify those frames. The exact reason for the sparse
differences is unresolved. The existing instruction order was restored, and
its current source-tree fingerprint again matches the control fingerprint.

The parity screens used `-VisualParityOnly`, so their build reports explicitly
skip the linked ISA audit. No new opcode was introduced by these candidates.
