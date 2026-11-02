# Recheck the non-bmodel sixteen-comparison edge-sort loop

Status: rejected after ten standalone candidate runs and ten additional combined runs. The 14-comparison loop remains in `src/r_edgea.s`.

The standalone test revisited the two-comparison extension on the current 320x200 i486 renderer. Both candidate screens used DOSBox-X 2026.08.31, the pinned `cputype=486` profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, CWSDPMI, `demo1`, the same data root, and five uninstrumented runs. All ten candidate runs rendered 969 frames and ended with framebuffer checksum `1047377823`.

| Variant | FPS samples | Median | Mean | Spread |
| --- | --- | ---: | ---: | ---: |
| 14-comparison control | 16.343255 / 16.343267 / 16.343265 / 16.343260 / 16.216210 | 16.343260 | 16.317851400 | 0.127057 |
| 16-comparison screen A | 16.343257 / 16.343268 / 16.343230 / 16.343264 / 16.343257 | 16.343257 | 16.343255200 | 0.000038 |
| 16-comparison screen B | 16.343254 / 16.343264 / 16.343261 / 16.343248 / 16.343262 | 16.343261 | 16.343257800 | 0.000016 |

The control has one clear host hitch at 16.216210 FPS; its other four samples average 16.343261750 FPS. Both standalone candidate screens averaged below that stable subset by 0.000006550 and 0.000003950 FPS. The ten-candidate mean was 16.343256500 FPS and median 16.343259, versus the control median 16.343260. The small negative direction did not repeat as a positive gain, so the added comparisons were removed.

## Combined interaction recheck

To test whether layout or cache effects changed the result, the same two-comparison suffix was added on top of the promoted alias span triangle-constant setup. The combined variant passed the full strict i486 gate and produced two more five-run screens:

| Combined edge16 + prepared spans screen | FPS samples | Median | Mean |
| --- | --- | ---: | ---: |
| A | 16.345702 / 16.345700 / 16.345690 / 16.345696 / 16.345706 | 16.345700 | 16.345698800 |
| B | 16.345697 / 16.345690 / 16.345709 / 16.345701 / 16.345704 | 16.345701 | 16.345700200 |

The combined ten-run mean was 16.345699500 FPS and pooled median 16.3457005. Compared with the first ten prepared-span-only runs, this is just +0.000004200 FPS by mean and +0.0000045 by median, below the individual screen spreads. A bracketed five-run prepared-span-only control after reverting edge16 measured 16.345703 median, faster than either combined screen median. The edge16 interaction therefore did not show a repeatable advantage and was removed; the prepared-span optimization remains.

All combined and bracketed-control runs rendered 969 frames with checksum `1047377823` and the same event trace. The combined build audit passed with 314,351 linked instructions, one i486 instruction, zero above-i486/unknown/exempt/unaccounted bytes, 529 startup code rows, 9,207 provider instructions, and 403 source proofs.

- Original control: `out/dos-timedemo-20261031-095456/timedemo-result.json`
- Standalone candidate A: `out/dos-timedemo-20261031-101413/timedemo-result.json`
- Standalone candidate B: `out/dos-timedemo-20261031-102042/timedemo-result.json`
- Combined candidate A: `out/dos-timedemo-20261101-183825/timedemo-result.json`
- Combined candidate B: `out/dos-timedemo-20261101-184425/timedemo-result.json`
- Bracketed prepared-span-only control: `out/dos-timedemo-20261101-185046/timedemo-result.json`
- Combined build and audit: `out/local-alias-prepared-spans-edge16-20261101/`
- Combined source fingerprint: `51ACB01B9337C0D9C5942520CAD164E2B06D45C2CCF3788DB3A094DFCE17DC2D`
- Standalone 16-comparison source fingerprint: `F0558A17EFE7C0B845BCDDAC82802D60621BF9A86A148B992CDC8F122BBCDDBB`
- Standalone 16-comparison executable SHA-256: `1B9662AC605A50C28077D528FDCD06EB273DD712FA3C5484C85F79E73E55E175`
