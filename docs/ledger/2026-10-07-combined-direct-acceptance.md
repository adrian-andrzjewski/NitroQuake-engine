# Combined direct tests after visibility integration

## Exact algorithms, continuous state and ABI checks

The main all-selectable benchmark passed with every requested implementation
verified against the built manifest before DOSBox-X execution. This includes
the integrated sprite/orientation and math, animated and point lighting,
frame control, palette, math support and visibility ports, alongside the
previous surface, span, alias and dynamic-light kernels. Every direct comparison
is exact; the ABI, state, guard and deliberate fault-detector checks passed.

The newer fixtures cover 252 math cases, 2,648 sprite-orientation cases,
14,336 animated-light frames, 1,600 point-light cases, 22,528 frame-control
cases plus 8,192 continuous visibility steps, 480 direct palette cases and
9,728 palette frames, 29,184 math-support cases plus 8,192 sequential matrix
frames, and 9,216 visibility cases plus an 8,192-step sequence. The alias
line-scan and edge-table checks passed 16,416 and 1,372 cases respectively.
The aggregate ended normally with checksum `3755475462` and zero failures.

Evidence: `out/dos-bench-20261007-193404/bench-result.json`. Its accepted
executable, manifest, linked audit and actual execution binding are retained
in `accepted-artifact-snapshot`. Executable SHA256:
`25B9D53544E7B5343E697DC8E75F6ED93A69043E2521EC64C38B1F933A7E64A6`.
Manifest SHA256:
`071D6B8D9806CEFECC555D9C726ED8F661CCB1021982F93449654F2D54D68ED8`.
Linked report SHA256:
`C0C572441B1216E088EF1CFD49A53E5D5D684137436E3FCEA2346C5C001A4719`.

## Reproduction and current ownership limits

Run the shared benchmark runner with the selectors in
`tools/renderer-profiles/i486-asm-selectable.json`, the intended test-data root,
and `TimeoutSeconds=1800`. The aggregate needs more than the old 600-second
limit on this host; the earlier timed-out run is retained in
`out/dos-bench-20261007-191937` and is not acceptance evidence. The forwarding
test verifies that the runner exposes all selected particle and sprite switches.

The following release rebuild passed the existing project and linked ISA
gates. Its ownership inventory is
`out/renderer-ownership-after-visibility-20261007.json`: 294 renderer entries,
292 directly reachable entries, 69 reachable C renderer dependencies and
29 unresolved direct callees. All three public model-visibility entries are
owned by `r_visibilityasm.s`. These counts do not prove an indirect call graph
or complete renderer conversion. Stronger code/data and runtime-provider proof,
remaining assembly ports and final full-frame stability acceptance remain open.

The subsequent combined run after public-entry integration also passes:
`out/dos-bench-20261007-210151`. All requested selectors were verified against
the actual executable. Thirty-one public transfers and 6,144 sprite-hook calls
pass along with every earlier direct and continuous state fixture. Emulator
exit is zero, exact-result/ABI/guard failures are zero, and the final checksum
remains `3755475462`. The executable, manifest, linked audit and execution binding
are retained in that run's `accepted-artifact-snapshot`. Executable SHA256:
`731FA76570C05AEAA117CBF8B64960DDE544E1076C504173DBAEB103131AE038`; manifest SHA256:
`D123FCD53496830C5FB39178F6F6B1C1BBEDD2580F7A9BAA6359ED7154AD9653`; linked audit SHA256:
`A4042AF321A3529F424691B2A0331171480D553F8A35766EA040F7A35A1A3C67`.
This incremental aggregate acceptance precedes the sky conversion.
