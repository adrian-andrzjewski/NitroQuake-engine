# VESA wait gates and status-port polling i486 assembly port (2026-10-19)

## Behavior and selector

`VesaWaitImplementation=asm` selects i486 assembly for
`VID_ExtraWaitDisplayIfRequested`, `VID_ExtraWaitVsyncIfRequested`, and
`VID_ExtraDisplayStartWaitFlags`. The two wait entries gate on the exact
`vid_wait` bit patterns and poll VGA status port `0x3DA`; the display-start
entry returns the VBE wait flag. The C entries remain available as the parity
oracle and in the C-reference profile. The C oracle now uses the same bit-exact
mode checks, including for non-finite values.

VESA discovery, the one-time retrace capability probe, and BIOS operations
remain in C. The port covers the per-frame wait gates, not VESA setup or the
full video update state machine.

## Direct C/assembly parity

The `asm-fixture` selector replaces hardware reads with deterministic status
samples and compares direct and ABI-probed C/assembly calls across nine float
bit patterns and both capability flags (36 cases). It checks wait-gate
decisions, polling counts, display-start flags, and callee ABI state. The first
run exposed a C-oracle NaN comparison that entered a polling loop; switching
the C gate to a raw-bit comparison made that case safely reject the mode. The
final DOSBox-X run reported:

```text
VESA wait: 36 exact C/assembly gate, polling and ABI cases PASS (0 failures)
VESA wait gates and retrace-port C/ASM parity PASS (36 exact cases, failure mask 0x0)
486 benchmark correctness PASS
```

Run report: `out/dos-bench-20261019-052147/bench-result.json`.

This deterministic fixture does not measure FPS or establish full-scene
framebuffer parity.

## Strict i486 release verification

The non-BENCH release executable passed the project-object audit at 123,619
instructions across 167 objects and the linked executable audit at 161,916
instructions across 402 objects. The linked-image proof checked all 161,916
opcodes from 235 runtime inputs and 420 source-bound contributions, covering
1,445 CODE ranges and 35 DATA ranges. Startup and provider proofs also passed.
There were zero instructions above i486, unknown encodings, exemptions, or
unclassified bytes.

Release output: `out/profile-41090bd4aa6cb655/quake.exe`.

## Ownership and remaining scope

The 139-entry assembly selector profile now owns these three wait entries.
The C oracle remains selectable. One-time retrace probing, VESA discovery,
BIOS palette/mode operations, and the outer `VID_Update` state machine remain
C-owned. No full-scene capture or performance result is claimed by this
fixture.

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/vid_ext.c:VID_ExtraWaitDisplayIfRequested_C` | `src/vid_vesawaitasm.s:VID_ExtraWaitDisplayIfRequested` | 36 exact mode/capability, polling, and ABI cases | DOSBox-X fixture and strict non-BENCH i486 release gates pass |
| `src/vid_ext.c:VID_ExtraWaitVsyncIfRequested_C` | `src/vid_vesawaitasm.s:VID_ExtraWaitVsyncIfRequested` | 36 exact mode/capability, polling, and ABI cases | DOSBox-X fixture and strict non-BENCH i486 release gates pass |
| `src/vid_ext.c:VID_ExtraDisplayStartWaitFlags_C` | `src/vid_vesawaitasm.s:VID_ExtraDisplayStartWaitFlags` | 36 exact mode/capability and ABI cases | DOSBox-X fixture and strict non-BENCH i486 release gates pass |
