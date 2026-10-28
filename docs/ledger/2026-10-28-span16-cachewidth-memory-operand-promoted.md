# D_DrawSpans16 cachewidth memory operands (2026-10-28)

Status: promoted after a positive three-run mean, exact framebuffer parity, and
the complete strict i486 ISA gate.

## Change

In the nonzero-T Span16 setup, multiply and add now read `cachewidth` directly
from memory instead of loading it into `%ebx` and reusing the register. This
removes one explicit move while preserving the same address arithmetic.

## Timedemo

Control and candidate used `demo1`, DOSBox-X 2026.08.31, the aggressive
optimization profile, `TextureSpanStores=word`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All six runs produced 969 frames, framebuffer checksum `1047377823`, and
identical recorded event traces.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Control | `out/dos-timedemo-20261028-043201/timedemo-result.json` | 16.229704 / 16.229715 / 16.229718 | 16.229712333 | 16.229715 |
| Memory-source cachewidth | `out/dos-timedemo-20261028-052618/timedemo-result.json` | 16.238095 / 16.238076 / 16.238022 | 16.238064333 | 16.238076 |

The candidate gained **0.008352 FPS (+0.05146%)**. The control and candidate
record different `dataRoot` paths. The control's temporary staged PAK links
were removed during the authorized output cleanup, so their hashes cannot now
be rechecked. The candidate PAK hashes match the canonical test data:

- `pak0.pak`: `35A9C55E5E5A284A159AD2A62E0E8DEF23D829561FE2F54EB402DBC0A9A946AF`
- `pak1.pak`: `94E355836EC42BC464E4CBE794CFB7B5163C6EFA1BCC575622BB36475BF1CF30`

## i486 audit

The full strict gate passed with zero above-i486, unknown, or exempt
instructions: 314,234 linked instructions, 529 startup rows, and 9,207 DPMI
provider instructions. The executable SHA-256 is
`1484F3AFA093A9630574639364594209308E0469E14C323DFFFD47D9E6881C7F`.

The timedemo checksum verifies Quake's rendered framebuffer. It does not
verify DOSBox's host window presentation; the reported black display remains
unresolved. The candidate selected `VgaPresentationImplementation=asm`.

Follow-up: one source of VGA gaps was traced to `VGA_UpdateLinearScreen`
dropping dirty-rectangle row tails. The low-level transfer is fixed and covered
by an independent expected-buffer fixture; host-window visual acceptance is
still pending. See the
[`VGA linear copy tail-fix ledger`](2026-10-28-vga-linear-copy-tail-fix.md).
