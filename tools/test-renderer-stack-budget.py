#!/usr/bin/env python3
"""Host-side contract checks for generated renderer stack budgets."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    raise SystemExit(message)


def function_body(source: str, signature: str) -> str:
    cursor = 0
    start = source.find(signature, cursor)
    if start < 0:
        fail(f"renderer stack call-path contract is missing {signature}")
    opening = source.find("{", start)
    while opening >= 0:
        semicolon = source.find(";", start, opening)
        if semicolon < 0:
            break
        cursor = start + len(signature)
        start = source.find(signature, cursor)
        if start < 0:
            fail(f"renderer stack call-path contract has no body for {signature}")
        opening = source.find("{", start)
    if opening < 0:
        fail(f"renderer stack call-path contract has no body for {signature}")
    depth = 0
    for index in range(opening, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[opening + 1:index]
    fail(f"renderer stack call-path contract has an unterminated body for {signature}")


def main() -> int:
    checker = ROOT / "tools" / "renderer-stack-budget.py"
    result = subprocess.run([sys.executable, str(checker), "--self-test"],
                            cwd=ROOT, check=False, capture_output=True, text=True)
    if result.returncode != 0 or "PASS" not in result.stdout:
        fail("renderer stack-frame parser self-test failed: " + result.stderr.strip())

    source = (ROOT / "src" / "renderer" / "r_main.c").read_text(encoding="latin-1")
    bsp_source = (ROOT / "src" / "renderer" / "r_bsp.c").read_text(encoding="latin-1")
    draw_source = (ROOT / "src" / "renderer" / "r_draw.c").read_text(encoding="latin-1")
    dispatch = source[source.rindex("void R_RenderViewDispatch ("):
                      source.index("#ifdef FRAME_CONTROL_RESTORE_EDGE_SELECTOR")]
    view_body = function_body(source, "void R_RenderView_ (void)")
    edge_body = function_body(source, "void R_EdgeDrawing_C (void)")
    world_body = function_body(bsp_source, "void R_RenderWorld_C (void)")
    world_walk_body = function_body(
        bsp_source, "void __attribute__((regparm(2))) R_RecursiveWorldNode_C")
    clip_body = function_body(bsp_source, "void R_RecursiveClipBPoly_C (")
    stack_fallback_body = function_body(source, "static void R_RenderViewStackFallback (")
    checks = [
        ("R_RenderView_ enters edge drawing", "R_EdgeDrawing ();" in view_body),
        ("edge drawing enters world rendering", "R_RenderWorld ();" in edge_body),
        ("edge drawing later renders brush entities", "R_DrawBEntitiesOnList ();" in edge_body),
        ("world renderer enters recursive BSP traversal", "R_RecursiveWorldNode (" in world_body),
        ("C world traversal recursively visits children", world_walk_body.count("R_RecursiveWorldNode_C (") >= 2),
        ("world traversal has a polygon path", "R_RenderPoly (" in world_walk_body),
        ("clipped-bmodel traversal recurses", "R_RecursiveClipBPoly_C (" in clip_body),
        ("polygon path transforms vertices and draws", "TransformVector (" in draw_source and "D_DrawPoly ();" in draw_source),
        ("normal requirement precedes warp storage", dispatch.index("R_RenderStackRequirement (&normal_required)") < dispatch.index("if (r_warpbuffer_storage)")),
        ("normal bounds precede warp storage", dispatch.index("R_RenderStackHasRoom (normal_required") < dispatch.index("if (r_warpbuffer_storage)")),
        ("forced capacity applies only to warp fallback", "allow_forced_short && r_bench_warp_force_short_stack" in source),
        ("normal low-stack behavior skips the renderer", "render skipped; normal path requires" in dispatch and "return;" in dispatch),
        ("actual DJGPP stack limits are checked", "stack_pointer < __djgpp_stack_limit" in source and "stack_pointer > __djgpp_stack_top" in source),
        ("fallback owns the warp array and calls renderer", "byte\twarpbuffer[R_WARP_BUFFER_BYTES];" in stack_fallback_body and "render_view ();" in stack_fallback_body),
        ("runtime formula charges both nested returns and dispatch callback", "(3UL * R_WARP_CALL_BYTES)" in source),
        ("runtime formula includes optional iterative BSP frame", "R_WARP_WORLD_WALK_FIXED_BYTES" in source),
    ]
    for name, passed in checks:
        if not passed:
            fail(f"renderer stack-boundary contract failed: {name}")

    build = (ROOT / "tools" / "build-dos-experimental.ps1").read_text(encoding="latin-1")
    if ("renderer-stack-budget.py" not in build or "--instrumented" not in build or
            "-DASM486_BSP_WALK" not in build or "--asm-bsp-walk" not in build):
        fail("the DOS build does not enforce generated stack budgets for instrumented and BSP-walk profiles")

    documentation = (ROOT / "docs" / "renderer-assembly" / "warp-scratch.md").read_text(encoding="utf-8")
    for term in ("Call-path ledger", "R_RecursiveWorldNode_C", "R_RecursiveWorldNode_asm486",
                 "R_RecursiveClipBPoly", "R_RenderPoly", "TransformVector",
                 "R_RenderViewStackFallback", "dispatch callback return",
                 "preprocessed runtime formula"):
        if term not in documentation:
            fail(f"renderer stack documentation is missing call-path term: {term}")

    print("renderer stack budget source and parser checks: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
