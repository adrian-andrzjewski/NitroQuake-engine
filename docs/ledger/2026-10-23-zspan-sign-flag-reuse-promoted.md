# D_DrawZSpans sign-flag reuse

Status: promoted after a fresh three-run control and strict i486 validation.

## Measurement

The paired `demo1` timedemos used the pinned DOSBox-X profile `out/dosbox-x-486-high-32mb-profile.conf` with SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Both source snapshots completed 969 frames with framebuffer checksum `1047377823` on every run.

| Version | Source tree fingerprint | Run FPS | Mean FPS |
| --- | --- | --- | ---: |
| Control | `698D0B85BF0C5FFDEC9DAB65FB769A17E068C30F1F5B2210E6C49CC35A1FF7AF` | 15.626483, 15.626488, 15.626491 | 15.626487 |
| Candidate | `B2278EDD8CF908A54273F056F817BF2AE11888BFC3461AAB792888CF2ED4BE8C` | 15.750052, 15.750072, 15.750062 | 15.750062 |

Gain: `+0.123575 FPS` (`+0.7908%`). The control median was 15.626488 FPS; candidate median was 15.750072 FPS.

- Control result: `out/dos-timedemo-20261023-201957/timedemo-result.json`
- Candidate result: `out/dos-timedemo-20261023-201441/timedemo-result.json`
- Strict candidate build: `out/local-dos-timedemo-zspan-sign-carry-full-20261023/`

## Change

The 16-pixel ZSpan loop's positive and negative pair macros no longer retest the accumulator sign before every pair. Each group's first pair tests `%edx`; the final `addl` or `subl` in each pair then supplies the sign flag for the next pair. The pointer advance uses `leal`, which preserves that flag. Group entry checks remain for the 16-, 8-, 4-, and 2-pixel chunks.

This source change builds on the existing 16-pixel ZSpan unroll in the control snapshot, so the commit includes that complete unroll together with sign-flag reuse.

## Validation

- Candidate timedemo parity: PASS, 969 frames and checksum `1047377823` for all three runs.
- Strict i486 audit: PASS; 275,570 object instructions and 313,867 linked instructions across 435 executable ranges; 529 startup rows; 9,207 DPMI-provider instructions; zero above-i486, unknown, or exempt instructions.
- Final source mapping: PASS; 2,375 CODE and 35 DATA ranges.
- Pinned profile hash matched for both control and candidate.
