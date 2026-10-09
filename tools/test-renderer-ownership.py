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


def combined_asm_fixture(root: Path, extra_setter_listing: str = "") -> tuple[dict, str, Path]:
    objects = root / "obj"
    (root / "src").mkdir()
    objects.mkdir()
    object_names = ("r_entry", "asm486_experiments", "d_driverasm", "d_draw", "d_draw16")
    for name in object_names:
        (objects / f"{name}.obj").touch()

    def object_header(name: str) -> str:
        return f"{objects / (name + '.obj')}: file format coff-go32\n"

    def symbol(index: int, name: str) -> str:
        return f"[ {index:2d}](sec  1)(fl 0x00)(ty 0)(scl 2)(nx 0) 0x00000000 {name}\n"

    listing = (
        object_header("r_entry")
        + symbol(0, "_R_RenderView")
        + "00000000 <_R_RenderView>:\n"
        + "   0: e8 00 00 00 00 call 5 <_R_RenderView+0x5>\n"
        + "            1: DISP32 _D_DrawSurfaces\n"
        + "   5: e8 00 00 00 00 call a <_R_RenderView+0xa>\n"
        + "            6: DISP32 _D_SetupFrame\n"
        + "   a: c3 ret\n"
        + object_header("asm486_experiments")
        + symbol(0, "_D_DrawSurfaces")
        + symbol(1, "_d_drawspans")
        + "00000000 <_D_DrawSurfaces>:\n"
        + "   0: a1 00 00 00 00 mov 0x0,%eax\n"
        + "            1: dir32 _d_drawspans\n"
        + "   5: ff d0 call *%eax\n"
        + "   7: c3 ret\n"
        + object_header("d_driverasm")
        + symbol(0, "_D_SetupFrame")
        + "00000000 <_D_SetupFrame>:\n"
        + "   0: 75 07 jne 9 <_D_SetupFrame+0x9>\n"
        + "   2: b8 00 00 00 00 mov $0x0,%eax\n"
        + "            3: dir32 _D_DrawSpans16\n"
        + "   7: eb 05 jmp e <_D_SetupFrame+0xe>\n"
        + "   9: b8 00 00 00 00 mov $0x0,%eax\n"
        + "            a: dir32 _D_DrawSpans8\n"
        + "   e: a3 00 00 00 00 mov %eax,0x0\n"
        + "            f: dir32 _d_drawspans\n"
        + "  14: c3 ret\n"
        + extra_setter_listing
        + object_header("d_draw")
        + symbol(0, "_D_DrawSpans8")
        + "00000000 <_D_DrawSpans8>:\n"
        + "   0: c3 ret\n"
        + object_header("d_draw16")
        + symbol(0, "_D_DrawSpans16")
        + "00000000 <_D_DrawSpans16>:\n"
        + "   0: c3 ret\n"
    )
    manifest = {
        "cSources": [],
        "assemblySources": [name + ".s" for name in (
            "r_entry", "asm486_experiments", "d_driverasm", "d_draw", "d_draw16")],
        "surfaceDrawImplementation": "asm",
        "drawingDriverImplementation": "asm",
    }
    return manifest, listing, objects


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

    def test_combined_asm_profile_resolves_only_assembly_span_targets(self):
        with tempfile.TemporaryDirectory(prefix="quake-drawspans-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = combined_asm_fixture(root)
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                report = ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                              ["_R_RenderView"], [])

            self.assertEqual(report["summary"]["selectedSetterTargetSets"], 1)
            proof, = report["selectedSetterTargetSets"]
            self.assertEqual(proof["pointer"], "_d_drawspans")
            self.assertEqual(proof["consumer"], "_D_DrawSurfaces")
            self.assertEqual(proof["callSiteOffset"], "0x5")
            self.assertEqual(proof["setter"], "_D_SetupFrame")
            self.assertEqual(proof["setterObject"], "d_driverasm.obj")
            self.assertEqual(proof["selectionAssignments"], [
                {"target": "_D_DrawSpans16", "offset": "0x2"},
                {"target": "_D_DrawSpans8", "offset": "0x9"},
            ])
            self.assertEqual(proof["pointerStoreOffset"], "0xe")
            self.assertEqual(proof["targets"], [
                {"symbol": "_D_DrawSpans16", "source": "d_draw16.s", "object": "d_draw16.obj", "language": "assembly"},
                {"symbol": "_D_DrawSpans8", "source": "d_draw.s", "object": "d_draw.obj", "language": "assembly"},
            ])
            self.assertIn("does not enumerate writers outside the selected setter", proof["proof"])
            self.assertIn("_D_DrawSurfaces", [entry["symbol"] for entry in report["directlyReachableIndirectTransfers"]])

    def test_combined_asm_profile_rejects_an_additional_span_target(self):
        with tempfile.TemporaryDirectory(prefix="quake-drawspans-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = combined_asm_fixture(
                root, "  15: b8 00 00 00 00 mov $0x0,%eax\n            16: dir32 _D_DrawSpans32\n")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "unexpected span targets: _D_DrawSpans32"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_noncombined_profile_does_not_claim_span_target_closure(self):
        with tempfile.TemporaryDirectory(prefix="quake-drawspans-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = combined_asm_fixture(root)
            manifest["drawingDriverImplementation"] = "c"
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                report = ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                              ["_R_RenderView"], [])
            self.assertEqual(report["selectedSetterTargetSets"], [])
            self.assertEqual(report["summary"]["selectedSetterTargetSets"], 0)

    def test_combined_asm_profile_rejects_based_pointer_load(self):
        with tempfile.TemporaryDirectory(prefix="quake-drawspans-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = combined_asm_fixture(root)
            listing = listing.replace("mov 0x0,%eax", "mov 0x0(%ebx),%eax")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "unexpected _D_DrawSurfaces pointer load"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_combined_asm_profile_requires_absolute_dir32_relocations(self):
        with tempfile.TemporaryDirectory(prefix="quake-drawspans-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = combined_asm_fixture(root)
            listing = listing.replace("1: dir32 _d_drawspans", "1: disp32 _d_drawspans")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "requires a DIR32 relocation"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])


if __name__ == "__main__":
    unittest.main()
