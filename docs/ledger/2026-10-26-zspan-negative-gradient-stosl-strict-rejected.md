# Negative-gradient Z-span pair store with STOSL (2026-10-26)

Status: rejected and restored after exact framebuffer parity and a passing
strict i486 audit, because the three-run mean was below the matched control.

In the nonnegative fast path for negative Z gradients,
ZSPAN_SUB_PAIR_NONNEGATIVE changed its packed-pair store from MOV plus LEA to
STOSL. The optional leading-word store already aligns EDI, and the i386 fallback
was kept unchanged. The candidate did not improve the strict mean, so the MOV
and LEA sequence is restored.

The matched runs used DOSBox-X 2026.08.31, demo1, three uninstrumented runs,
CWSDPMI, and the pinned 32 MB i486 profile SHA
532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA. Each run
rendered 969 frames with framebuffer checksum 1047377823.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | out/dos-timedemo-20261026-193850/timedemo-result.json | 16.085452 / 16.085471 / 16.085456 | 16.085459667 | 16.085456 |
| Parity screen | out/dos-timedemo-20261026-195138/timedemo-result.json | 16.085469 / 16.085464 / 16.085456 | 16.085463000 | 16.085464 |
| Strict candidate | out/dos-timedemo-20261026-201658/timedemo-result.json | 16.085457 / 16.085461 / 16.085454 | 16.085457333 | 16.085457 |

The strict mean was 0.000002333 FPS below control. All candidate runs retained
the exact 969-frame checksum. The complete strict i486 gate passed: 314,339
relocated instructions, 529 startup code rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. Source mapping covered
435 source-bound contributions, 2,376 CODE ranges, and 35 DATA ranges. The
result records visualParityOnly=false and isaAuditStatus=PASS.
