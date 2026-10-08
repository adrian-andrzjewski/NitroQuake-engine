# Combined lighting and sprite integration parity

The fresh paired run completed on 2026-10-07 after the interrupted restart
checkpoint. Its completion criterion was i486 compatibility and exact C output,
not a speed increase. It validates the five selected assembly paths together;
it does not establish completion of the full renderer port.

Candidate profile: `i486-asm-promoted-renderers-spriteframe`. The selected
assembly paths are dynamic-light push, mark-lights, sprite-frame selection,
sprite drawing and sprite setup. All other selectable paths use the C reference
settings in this profile.

Both profiles used the same source-tree SHA256:
`D337BF8DBBFDCB679228B4EFBBBC18FE33F44D5A8F28A7CEE8EF2327912B0AD8`.
The normal build gates inspected selected objects, the linked input/runtime
closure and the corresponding linked executable opcodes. The candidate gate
verified 221385 linked opcodes with no enforced instruction above i486 and no
opcode mismatch.

## Exact output evidence

Each scenario ran twice per profile on the configured DOSBox-X i486 target.
The paired gate excluded the existing six leading warmup checksums per run.

| Scenario | Compared checksums per run | Captured index differences | Captured palette-byte differences |
|---|---:|---:|---:|
| Demo 1 VESA, full viewport | 964 | 0 | 0 |
| Demo 1 VGA, full viewport | 964 | 0 | 0 |
| Demo 1 fullbright | 964 | 0 | 0 |
| Demo 1 viewsize 50 | 964 | 0 | 0 |
| Demo 2 entity workload | 980 | 0 | 0 |
| Demo 3 world workload | 1085 | 0 | 0 |

All 11842 compared frame checksums matched. All twelve paired captures matched
exactly in their 64000 indexed pixels and 768 palette bytes. Both input suites
passed repeat stability, and the paired report records `pass: true`.

The paired runner deliberately disables console notifications with
`con_notifytime -1`. Demo 3's final checksum is 3722973491 in both profiles;
this paired evidence does not authorize replacing a historical golden generated
with different console settings.

Report: `out/render-parity-after-restart-20261007-2/render-parity-result.json`.
Reproduce from the recorded source snapshot with:

```powershell
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -NoBootstrap `
  -ReferenceProfile tools/renderer-profiles/i486-c-reference.json `
  -CandidateProfile tools/renderer-profiles/i486-asm-promoted-renderers-spriteframe.json `
  -RunsOverride 2 -OutputRoot out/render-parity-after-restart-20261007-2
```

Startup-frame equivalence, dedicated extreme-coordinate and palette-transition
cases, an uninterrupted long rendering soak, remaining C ownership and the
complete assembly profile remain separate gates. Timing from this run is useful
regression evidence, but concurrent host work makes it unsuitable for deciding
small performance differences. Human visual/gameplay acceptance remains pending.
