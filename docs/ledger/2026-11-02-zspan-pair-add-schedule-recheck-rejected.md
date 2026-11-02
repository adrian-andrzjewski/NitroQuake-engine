# Z-span paired depth-add schedule recheck (2026-11-02)

Status: rejected after two matched five-run screens on the current combined 320x200 renderer. The original `SHLD; ROR; ADD; STOSL` schedule remains.

## Candidate

The current-source recheck moved the second `addl %ebx,%edx` in `ZSPAN_ADD_PAIR_NONNEGATIVE` between `shldl $16,%edx,%eax` and `rorl $16,%eax`. This was the same instruction schedule tested on 2026-10-30, now measured on top of the recent Z-span setup and alias-span optimizations.

The reorder is exactly equivalent: `SHLD` reads the old `%edx` and writes the packed word to `%eax`; the add advances `%edx`; `ROR` then reads only `%eax`. The add's flags are not consumed, and its updated `%edx` value is still used by the next sample. The packed Z values and subsequent sample sequence are unchanged.

## Benchmarks

All runs used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, CWSDPMI, `demo1`, and the same data root. Each run rendered 969 frames, ended at checksum `1047377823`, and produced identical event traces.

| Variant | FPS samples | Median FPS |
| --- | --- | ---: |
| Current combined control | 16.346934 / 16.346968 / 16.346972 / 16.346934 / 16.346960 | 16.346960 |
| Recheck candidate screen A | 16.346954 / 16.346968 / 16.228361 / 16.346954 / 16.346957 | 16.346954 |
| Recheck candidate screen B | 16.346950 / 16.346940 / 16.346960 / 16.346964 / 16.346944 | 16.346950 |

Screen A contains one host hitch. The pooled candidate median is 16.346954 FPS, **0.000006 FPS slower (-0.0000367%)** than the fresh control median. The nine non-hitch candidate runs average 16.346954556 FPS, only 0.000000956 FPS above the control's five-run mean; the two candidate screens move in opposite directions around that level. This is below run-to-run spread and does not establish a repeatable gain.

- Fresh current-source control: `out/dos-timedemo-20261102-072121/timedemo-result.json`
- Candidate screen A: `out/dos-timedemo-20261102-073931/timedemo-result.json`
- Candidate screen B: `out/dos-timedemo-20261102-074616/timedemo-result.json`
- Control build and audit: `out/local-span-zpair-current-control-20261102/`
- Candidate build and audit: `out/local-span-zpair-recheck-candidate-20261102/`

## Compatibility and disposition

The candidate passed the complete executable i486 gate: 314,349 linked instructions, one i486 instruction, zero above-i486, unknown, exempt, or unaccounted instructions; 529 startup rows; 9,207 provider instructions; and 403 exact source proofs. All timedemo checksum and event gates passed. Because the small positive direction did not repeat across the two candidate screens, the original instruction order was restored.

- Control source fingerprint: `4DEBF11DBCE0577A3ED23142921B3CB79644EB4C35E21EEC07A8B992ADC302D7`
- Candidate source fingerprint: `EAC66CC57BBD42B9234ED9B2349DBF39DBC7681811D796A85512312D44751747`

