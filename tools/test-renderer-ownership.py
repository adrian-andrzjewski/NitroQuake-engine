"""Check renderer ownership across compiler clones and direct-call traces."""
from __future__ import annotations

import importlib.util
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("renderer_ownership", Path(__file__).with_name("renderer-ownership.py"))
assert spec and spec.loader
ownership = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ownership)


class RendererOwnershipTests(unittest.TestCase):
    def test_visibility_clones_remain_renderer_owned(self):
        for function in ownership.RENDER_SUPPORT:
            for suffix in ("", ".part.0", ".constprop.3", ".isra.1", ".cold", ".split.4", ".constprop.1.isra.2"):
                with self.subTest(function=function, suffix=suffix):
                    symbol = "_" + function + suffix
                    self.assertEqual(ownership.original_function(symbol), function)
                    self.assertTrue(ownership.renderer_source("model.c", symbol))
        self.assertFalse(ownership.renderer_source("model.c", "_Mod_LoadBrushModel.constprop.0"))

    def test_clone_callee_is_reported_with_its_root_trace(self):
        with tempfile.TemporaryDirectory(prefix="quake-ownership-") as directory:
            root = Path(directory)
            (root / "src").mkdir()
            (root / "obj").mkdir()
            (root / "src/model.c").write_text(
                "void Mod_DecompressVis(void) {}\nint dispatch_table[4];\n", encoding="ascii")
            for name in ("r_entry", "model"):
                (root / "obj" / (name + ".obj")).touch()
            listing = f"""{root / 'obj/r_entry.obj'}: file format coff-go32
[  0](sec  1) 0x00000000 _R_RenderView
00000000 <_R_RenderView>:
   0: e8 00 00 00 00 call 5 <_R_RenderView+0x5>
            1: DISP32 _Mod_DecompressVis.constprop.0
   5: c3 ret
{root / 'obj/model.obj'}: file format coff-go32
[  0](sec  1) 0x00000000 _Mod_DecompressVis.constprop.0
[  1](sec  1) 0x00000010 _dispatch_table
00000000 <_Mod_DecompressVis.constprop.0>:
   0: ff d0 call *%eax
   2: c3 ret
00000010 <_dispatch_table>:
  10: c3 ret
"""
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                report = ownership.inventory(
                    {"cSources": ["model.c"], "assemblySources": ["r_entry.s"]},
                    root / "obj", root, root / "objdump.exe", ["_R_RenderView"], [])
            self.assertFalse(report["completeCallGraph"])
            self.assertEqual(report["summary"]["directlyReachableRendererC"], 1)
            self.assertEqual(report["directlyReachableRendererC"][0]["directRootTrace"],
                             ["_R_RenderView", "_Mod_DecompressVis.constprop.0"])
            self.assertEqual(report["directlyReachableIndirectTransfers"][0]["symbol"], "_Mod_DecompressVis.constprop.0")
            self.assertNotIn("_dispatch_table", [entry["symbol"] for entry in report["rendererEntries"]])


if __name__ == "__main__":
    unittest.main()
