# D_DrawZSpans negative-gradient endpoint overflow guard (2026-10-24)

Status: rejected at the three-run parity screen; the original 64-bit endpoint
proof remains active.

The candidate replaced the negative-gradient fast path's 64-bit product and
carry chain with a signed 32-bit multiply and overflow check, followed by an
endpoint sign check. It retained the original per-pair sign-checking fallback.
The parity-only build did not prove i486 compatibility.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, committed positive-gradient guard | `out/dos-timedemo-20261024-101516/timedemo-result.json` | 61.180931 / 61.180882 / 61.180939 | 15.838268 / 15.838281 / 15.838266 | 15.838271837615 | 969 / `1047377823` every run |
| Screen, negative-gradient guard | `out/dos-timedemo-20261024-102409/timedemo-result.json` | 61.180929 / 61.180946 / 61.180903 | 15.838269 / 15.838264 / 15.838275 | 15.838269594023 | 969 / `1047377823` every run |

The screen mean decreased by **0.000002243592 FPS**. Exact frame and checksum
parity held, but the negative mean rejects the candidate before strict
validation. The original 64-bit endpoint proof was restored.

- Candidate source fingerprint:
  `F6548787163D6529636C75127ADF905AE38EBC259D7AC500349F61A81C0FFDED`.
- Candidate source tree fingerprint:
  `B34E054A927CC164896E2443FB83C71305D3E7DBC0730A3B199C6D58A9894142`.
- Parity-only build: `out/visual-parity-profile-9eea9650c5c9c4f1/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly -NoBootstrap
```
