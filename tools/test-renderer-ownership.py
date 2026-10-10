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


def pdrawfunc_fixture(root: Path, extra_setter_listing: str = "",
                      extra_consumer_listing: str = "",
                      clobber_forward_register: bool = False,
                      duplicate_pointer_load_relocations: bool = False,
                      with_local_setter_labels: bool = False,
                      extra_span_alias: str = "") -> tuple[dict, str, Path]:
    objects = root / "obj"
    (root / "src").mkdir()
    objects.mkdir()
    object_names = ("r_entry", "r_worldcontrolasm", "asm486_experiments",
                    "r_edgea", "r_publicbindingsasm")
    for name in object_names:
        (objects / f"{name}.obj").touch()

    def object_header(name: str) -> str:
        return f"{objects / (name + '.obj')}: file format coff-go32\n"

    def symbol(index: int, name: str, address: int = 0, storage_class: int = 2,
               section: int = 1) -> str:
        return f"[ {index:2d}](sec {section:2d})(fl 0x00)(ty 0)(scl {storage_class})(nx 0) 0x{address:08x} {name}\n"

    listing = (
        object_header("r_entry")
        + symbol(0, "_R_RenderView")
        + symbol(1, "_R_ScanEdges_asm486", section=0)
        + "00000000 <_R_RenderView>:\n"
        + "   0: e8 00 00 00 00 call 5 <_R_RenderView+0x5>\n"
        + "            1: DISP32 _R_BeginEdgeFrame\n"
        + "   5: e8 00 00 00 00 call a <_R_RenderView+0xa>\n"
        + "            6: DISP32 _R_ScanEdges_asm486\n"
        + "   a: c3 ret\n"
        + object_header("r_worldcontrolasm")
        + (symbol(10, "wc_edges_release_L17", 0x7, 6) if with_local_setter_labels else "")
        + (symbol(11, "wc_edges_release_L25", 0x10, 6) if with_local_setter_labels else "")
        + symbol(0, "_R_BeginEdgeFrame")
        + "00000000 <_R_BeginEdgeFrame>:\n"
        + "   0: 74 0e je 10 <_R_BeginEdgeFrame+0x10>\n"
        + "   2: bb 00 00 00 00 mov $0x0,%ebx\n"
        + "            3: DIR32 _R_GenerateSpans\n"
        + ("00000007 <wc_edges_release_L17>:\n" if with_local_setter_labels else "")
        + ("   7: 89 c3 mov %eax,%ebx\n" if clobber_forward_register else
           "   7: 90 nop\n   8: 90 nop\n")
        + "   9: 89 1d 00 00 00 00 mov %ebx,0x0\n"
        + "            b: DIR32 _pdrawfunc\n"
        + "   f: c3 ret\n"
        + ("00000010 <wc_edges_release_L25>:\n" if with_local_setter_labels else "")
        + "  10: bb 00 00 00 00 mov $0x0,%ebx\n"
        + "           11: DIR32 _R_GenerateSpansBackward\n"
        + "  15: 90 nop\n"
        + "  16: eb f1 jmp 9 <_R_BeginEdgeFrame+0x9>\n"
        + "  18: c3 ret\n"
        + extra_setter_listing
        + object_header("asm486_experiments")
        + symbol(0, "_R_ScanEdges_asm486")
        + symbol(1, "_R_GenerateSpansBackward_asm486", 0x1000)
        + "00000000 <_R_ScanEdges_asm486>:\n"
        + "   0: a1 00 00 00 00 mov 0x0,%eax\n"
        + "            1: DIR32 _pdrawfunc\n"
        + ("            1: DIR32 _pdrawfunc\n" if duplicate_pointer_load_relocations else "")
        + "   5: ff d0 call *%eax\n"
        + "   7: a1 00 00 00 00 mov 0x0,%eax\n"
        + ("" if duplicate_pointer_load_relocations else "            8: DIR32 _pdrawfunc\n")
        + "   c: ff d0 call *%eax\n"
        + "   e: c3 ret\n"
        + extra_consumer_listing
        + "00001000 <_R_GenerateSpansBackward_asm486>:\n"
        + "1000: c3 ret\n"
        + object_header("r_edgea")
        + symbol(0, "_R_GenerateSpans")
        + symbol(1, "_R_GenerateSpans_asm486")
        + (symbol(2, extra_span_alias) if extra_span_alias else "")
        + "00000000 <_R_GenerateSpans>:\n"
        + "   0: c3 ret\n"
        + object_header("r_publicbindingsasm")
        + symbol(0, "_R_GenerateSpansBackward")
        + "00000000 <_R_GenerateSpansBackward>:\n"
        + "   0: e9 00 00 00 00 jmp 5 <_R_GenerateSpansBackward+0x5>\n"
        + "            1: DISP32 _R_GenerateSpansBackward_asm486\n"
        + "   5: c3 ret\n"
    )
    manifest = {
        "cSources": [],
        "assemblySources": [name + ".s" for name in object_names],
        "worldControlImplementation": "asm",
        "scanEdgesImplementation": "asm",
        "backwardSpansImplementation": "asm",
    }
    return manifest, listing, objects


class RendererOwnershipTests(unittest.TestCase):
    def test_benchmark_runner_binds_ownership_report_to_verified_manifest(self):
        script = Path(__file__).with_name("bench-dos.ps1").read_text(encoding="utf-8")

        self.assertIn("$selectorVerification.manifest", script)
        self.assertIn("$ownershipManifest.objectRoot", script)
        self.assertIn("renderer-ownership-{0}.json", script)
        self.assertNotIn("'build-manifest-bench.json'", script)

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
[  0](sec  4)(fl 0x00)(ty 0)(scl 2)(nx 0) 0x00000000 _R_RenderView
00000000 <_R_RenderView>:
   0: e8 00 00 00 00 call 5 <_R_RenderView+0x5>
            1: DISP32 _Mod_DecompressVis.constprop.0
   5: c3 ret
{root / 'obj/model.obj'}: file format coff-go32
[  0](sec  1)(fl 0x00)(ty 0)(scl 2)(nx 0) 0x00000000 _Mod_DecompressVis.constprop.0
[  1](sec  1)(fl 0x00)(ty 0)(scl 2)(nx 0) 0x00000010 _dispatch_table
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

    def test_selected_edge_span_dispatch_has_static_target_closure(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(root)
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                report = ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                              ["_R_RenderView"], [])

            self.assertEqual(report["summary"]["selectedIndirectTargetSets"], 1)
            proof, = report["selectedIndirectTargetSets"]
            self.assertEqual(proof["pointer"], "_pdrawfunc")
            self.assertEqual(proof["consumer"], "_R_ScanEdges_asm486")
            self.assertEqual(proof["callSiteOffsets"], ["0x5", "0xc"])
            self.assertEqual(proof["setter"], "_R_BeginEdgeFrame")
            self.assertEqual(proof["selectionAssignments"], [
                {"target": "_R_GenerateSpans", "offset": "0x2"},
                {"target": "_R_GenerateSpansBackward", "offset": "0x10"},
            ])
            self.assertEqual(proof["targets"], [
                {"symbol": "_R_GenerateSpans", "source": "r_edgea.s",
                 "object": "r_edgea.obj", "language": "assembly"},
                {"symbol": "_R_GenerateSpansBackward", "source": "r_publicbindingsasm.s",
                 "object": "r_publicbindingsasm.obj", "language": "assembly"},
            ])
            self.assertEqual(proof["implementations"], [
                {"symbol": "_R_GenerateSpans_asm486", "source": "r_edgea.s",
                 "object": "r_edgea.obj", "language": "assembly"},
                {"symbol": "_R_GenerateSpansBackward_asm486", "source": "asm486_experiments.s",
                 "object": "asm486_experiments.obj", "language": "assembly"},
            ])
            entries = {entry["symbol"]: entry for entry in report["rendererEntries"]}
            self.assertEqual(entries["_R_GenerateSpans_asm486"], {
                "symbol": "_R_GenerateSpans_asm486", "source": "r_edgea.s",
                "object": "r_edgea.obj", "offset": "0x0", "language": "assembly",
                "rendererOwned": True, "calls": [], "indirectTransfers": [],
            })
            self.assertEqual(entries["_R_GenerateSpans"]["offset"],
                             entries["_R_GenerateSpans_asm486"]["offset"])

    def test_pdrawfunc_closure_rejects_an_unexpected_private_span_alias(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(
                root, extra_span_alias="_R_GenerateSpansFast_asm486")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(
                        ValueError,
                        "unexpected span aliases: _R_GenerateSpansFast_asm486"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_local_assembly_labels_do_not_truncate_selected_function(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-local-labels-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(
                root, with_local_setter_labels=True)
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                report = ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                              ["_R_RenderView"], [])

            proof, = report["selectedIndirectTargetSets"]
            self.assertEqual(proof["selectionAssignments"], [
                {"target": "_R_GenerateSpans", "offset": "0x2"},
                {"target": "_R_GenerateSpansBackward", "offset": "0x10"},
            ])

    def test_unclassified_disassembly_header_fails_closed(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-unknown-class-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(root)
            listing = listing.replace(
                "(scl 2)(nx 0) 0x00000000 _R_BeginEdgeFrame",
                "(scl 9)(nx 0) 0x00000000 _R_BeginEdgeFrame")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "unclassified or unsupported COFF storage class 9"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_pdrawfunc_closure_rejects_an_additional_span_assignment(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(
                root, "  19: bb 00 00 00 00 mov $0x0,%ebx\n            1a: DIR32 _R_GenerateSpansFast\n")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "unexpected span targets: _R_GenerateSpansFast"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_pdrawfunc_closure_rejects_an_unpaired_indirect_call(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(
                root, extra_consumer_listing="  10: ff d0 call *%eax\n")
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "expected two indirect calls"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_pdrawfunc_closure_rejects_a_duplicate_pointer_load_relocation(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(
                root, duplicate_pointer_load_relocations=True)
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "duplicate pointer-load relocation"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_pdrawfunc_closure_rejects_a_selected_register_clobber(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(root, clobber_forward_register=True)
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                with self.assertRaisesRegex(ValueError, "selected-register clobber"):
                    ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                        ["_R_RenderView"], [])

    def test_unselected_pdrawfunc_path_does_not_claim_target_closure(self):
        with tempfile.TemporaryDirectory(prefix="quake-pdrawfunc-ownership-") as directory:
            root = Path(directory)
            manifest, listing, objects = pdrawfunc_fixture(root)
            manifest["backwardSpansImplementation"] = "c"
            with patch.object(ownership.subprocess, "run", return_value=SimpleNamespace(stdout=listing)):
                report = ownership.inventory(manifest, objects, root, root / "objdump.exe",
                                              ["_R_RenderView"], [])
            self.assertEqual(report["selectedIndirectTargetSets"], [])
            self.assertEqual(report["summary"]["selectedIndirectTargetSets"], 0)

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
