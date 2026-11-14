#!/usr/bin/env python3
"""Host-side contract checks for generated renderer stack budgets."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> int:
    checker = ROOT / "tools" / "renderer-stack-budget.py"
    result = subprocess.run([sys.executable, str(checker), "--self-test"],
                            cwd=ROOT, check=False, capture_output=True, text=True)
    if result.returncode != 0 or "PASS" not in result.stdout:
        fail("renderer stack-frame parser self-test failed: " + result.stderr.strip())

    source = (ROOT / "src" / "renderer" / "r_main.c").read_text(encoding="latin-1")
    dispatch = source[source.rindex("void R_RenderViewDispatch ("):
                      source.index("#ifdef FRAME_CONTROL_RESTORE_EDGE_SELECTOR")]
    checks = [
        ("normal requirement precedes warp storage", dispatch.index("R_RenderStackRequirement (&normal_required)") < dispatch.index("if (r_warpbuffer_storage)")),
        ("normal bounds precede warp storage", dispatch.index("R_RenderStackHasRoom (normal_required") < dispatch.index("if (r_warpbuffer_storage)")),
        ("forced capacity applies only to warp fallback", "allow_forced_short && r_bench_warp_force_short_stack" in source),
        ("normal low-stack behavior skips the renderer", "render skipped; normal path requires" in dispatch and "return;" in dispatch),
        ("actual DJGPP stack limits are checked", "stack_pointer < __djgpp_stack_limit" in source and "stack_pointer > __djgpp_stack_top" in source),
    ]
    for name, passed in checks:
        if not passed:
            fail(f"renderer stack-boundary contract failed: {name}")

    build = (ROOT / "tools" / "build-dos-experimental.ps1").read_text(encoding="latin-1")
    if "renderer-stack-budget.py" not in build or "--instrumented" not in build:
        fail("the DOS build does not enforce the stack budget for instrumented profiles")

    print("renderer stack budget source and parser checks: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
