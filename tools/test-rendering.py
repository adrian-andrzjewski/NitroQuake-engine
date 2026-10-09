"""Host tests for the PCX decoder, tolerant comparison, and frame-log parser."""

from __future__ import annotations

import importlib.util
import io
import json
import re
import struct
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path


TOOL = Path(__file__).with_name("compare-rendering.py")
ROOT = TOOL.parent.parent
SPEC = importlib.util.spec_from_file_location("compare_rendering", TOOL)
assert SPEC and SPEC.loader
rendering = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = rendering
SPEC.loader.exec_module(rendering)


def make_pcx(path: Path, width: int, height: int, pixels: bytes, palette: bytes) -> None:
    assert len(pixels) == width * height
    assert len(palette) == 768
    header = bytearray(128)
    header[0:4] = bytes((0x0A, 5, 1, 8))
    struct.pack_into("<HHHH", header, 4, 0, 0, width - 1, height - 1)
    struct.pack_into("<HH", header, 12, width, height)
    header[65] = 1
    struct.pack_into("<H", header, 66, width)

    encoded = bytearray()
    for value in pixels:
        if value >= 0xC0:
            encoded.extend((0xC1, value))
        else:
            encoded.append(value)
    path.write_bytes(bytes(header) + bytes(encoded) + b"\x0c" + palette)


class RenderingComparisonTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="quake-render-test-")
        self.root = Path(self.temp.name)
        self.palette = bytearray(768)
        self.palette[3:6] = bytes((80, 100, 120))

    def tearDown(self) -> None:
        self.temp.cleanup()

    def capture(self, name: str, width: int = 4, height: int = 3, pixels: bytes | None = None) -> Path:
        path = self.root / name
        make_pcx(path, width, height, pixels or bytes([1] * (width * height)), bytes(self.palette))
        return path

    def test_reads_quake_pcx_and_palette(self) -> None:
        path = self.capture("frame.pcx", pixels=bytes((0, 1, 1, 0) * 3))
        image = rendering.load_pcx(path)
        self.assertEqual((image.width, image.height), (4, 3))
        self.assertEqual(image.pixels, bytes((0, 1, 1, 0) * 3))
        self.assertEqual(image.rgb()[3:6], bytes((80, 100, 120)))

    def test_ignores_subthreshold_channel_noise(self) -> None:
        expected = self.capture("expected.pcx")
        changed_palette = bytearray(self.palette)
        changed_palette[6:9] = bytes((81, 100, 120))
        actual = self.root / "actual.pcx"
        make_pcx(actual, 4, 3, bytes((2,) + (1,) * 11), bytes(changed_palette))
        report = rendering.compare_images(expected, actual)
        self.assertTrue(report["pass"])
        self.assertEqual(report["metrics"]["changedPixels"], 0)

    def test_reports_changed_pixels_and_respects_fraction_limit(self) -> None:
        expected = self.capture("expected.pcx")
        changed_palette = bytearray(self.palette)
        changed_palette[6:9] = bytes((255, 0, 0))
        actual = self.root / "actual.pcx"
        make_pcx(actual, 4, 3, bytes((1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1)), bytes(changed_palette))
        report = rendering.compare_images(
            expected,
            actual,
            channel_tolerance=2,
            max_changed_pixel_fraction=0.0,
            max_mean_absolute_error=255.0,
        )
        self.assertFalse(report["pass"])
        self.assertEqual(report["metrics"]["changedPixels"], 1)

    def test_dimension_mismatch_fails_with_both_sizes(self) -> None:
        expected = self.capture("expected.pcx")
        actual = self.capture("actual.pcx", width=2, height=2)
        report = rendering.compare_images(expected, actual)
        self.assertFalse(report["pass"])
        self.assertFalse(report["metrics"]["dimensionsMatch"])
        self.assertEqual(report["expected"]["width"], 4)
        self.assertEqual(report["actual"]["width"], 2)

    def test_writes_png_diff_and_reads_frame_log(self) -> None:
        image = rendering.load_pcx(self.capture("frame.pcx"))
        diff = self.root / "diagnostics" / "diff.png"
        rendering.write_diff_png(diff, image, image, 2)
        self.assertTrue(diff.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"))

        log = self.root / "framechecksums.txt"
        log.write_text("0 123\n1 456\nframes 2 overflow 0\n", encoding="ascii")
        parsed = rendering.read_frame_checksums(log)
        self.assertEqual(parsed, {"frames": [123, 456], "count": 2, "overflow": 0})

    def test_frame_log_rejects_gaps_and_overflow(self) -> None:
        log = self.root / "framechecksums.txt"
        log.write_text("0 123\n2 456\nframes 2 overflow 0\n", encoding="ascii")
        with self.assertRaisesRegex(ValueError, "expected frame 1"):
            rendering.read_frame_checksums(log)
        log.write_text("0 123\nframes 1 overflow 1\n", encoding="ascii")
        with self.assertRaisesRegex(ValueError, "overflowed by 1"):
            rendering.read_frame_checksums(log)

    def test_compares_frame_checksum_streams_and_can_ignore_startup(self) -> None:
        reference = self.root / "reference-checksums.txt"
        candidate = self.root / "candidate-checksums.txt"
        reference.write_text(
            "0 101\n1 202\n2 303\n3 404\nframes 4 overflow 0\n",
            encoding="ascii",
        )
        candidate.write_text(
            "0 101\n1 999\n2 303\n3 888\nframes 4 overflow 0\n",
            encoding="ascii",
        )

        report = rendering.compare_frame_checksums(reference, candidate)
        self.assertFalse(report["exactMatch"])
        self.assertEqual(report["comparedFrames"], 4)
        self.assertEqual(report["mismatchedFrames"], 2)
        self.assertEqual(report["firstMismatchFrame"], 1)
        self.assertEqual(report["lastMismatchFrame"], 3)

        ignored = rendering.compare_frame_checksums(
            reference, candidate, ignore_leading_frames=2
        )
        self.assertFalse(ignored["exactMatch"])
        self.assertEqual(ignored["ignoredLeadingFrames"], 2)
        self.assertEqual(ignored["comparedFrames"], 2)
        self.assertEqual(ignored["mismatchedFrames"], 1)
        self.assertEqual(ignored["firstMismatchFrame"], 3)

        with redirect_stdout(io.StringIO()):
            strict_exit = rendering.main(
                [str(reference), str(candidate), "--frame-checksums", "--require-exact"]
            )
            exact_exit = rendering.main(
                [str(reference), str(reference), "--frame-checksums", "--require-exact"]
            )
        self.assertEqual(strict_exit, 1)
        self.assertEqual(exact_exit, 0)

    def test_scenario_manifest_has_pinned_references(self) -> None:
        manifest = json.loads((ROOT / "tools/render-scenarios.json").read_text(encoding="utf-8"))
        scenarios = manifest["scenarios"]
        self.assertTrue(scenarios)
        self.assertIn("host_framerate 0.0783", manifest["validationAutoexecCommands"])
        self.assertGreater(manifest["warmupChecksumFrames"], 0)
        self.assertEqual(len({scene["id"] for scene in scenarios}), len(scenarios))
        for scene in scenarios:
            with self.subTest(scene=scene["id"]):
                self.assertGreater(scene["expectedFrames"], 0)
                self.assertGreater(scene["expectedChecksum"], 0)
                self.assertGreaterEqual(scene["repeatRuns"], 2)
                reference = ROOT / scene["reference"]
                image = rendering.load_pcx(reference)
                self.assertEqual((image.width, image.height), (320, 200))

    def test_assembly_selector_profile_uses_supported_i486_paths(self) -> None:
        profile_path = ROOT / "tools/renderer-profiles/i486-asm-selectable.json"
        profile = json.loads(profile_path.read_text(encoding="utf-8"))
        self.assertEqual(profile["schemaVersion"], 1)
        self.assertEqual(profile["id"], "i486-asm-selectable")
        self.assertTrue(profile["description"])

        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        selectors = profile["selectors"]
        self.assertGreaterEqual(len(selectors), 40)
        for name, value in selectors.items():
            with self.subTest(selector=name):
                self.assertTrue(name.endswith("Implementation"))
                parameter = re.search(
                    r"(?m)(?:\[ValidateSet\((?P<choices>[^)]*)\)\]\s*)?"
                    r"\[string\]\$" + re.escape(name) + r"\s*=\s*'(?P<default>[^']*)'",
                    timedemo_source,
                )
                self.assertIsNotNone(parameter, f"{name} is not a timedemo selector")
                choices = parameter.group("choices")
                if choices is None:
                    self.assertEqual(value, parameter.group("default"))
                else:
                    self.assertIn(value, re.findall(r"'([^']*)'", choices))
        self.assertEqual(selectors["AliasClipImplementation"], "asm")
        self.assertEqual(selectors["AliasClipZImplementation"], "asm")
        self.assertEqual(selectors["AliasPrepareImplementation"], "asm")
        self.assertEqual(selectors["AliasMatrixCompositionImplementation"], "asm")
        self.assertEqual(selectors["AliasSetupLightingImplementation"], "asm")
        self.assertEqual(selectors["AliasSetupFrameImplementation"], "asm")
        self.assertEqual(selectors["AliasSetupSkinImplementation"], "asm")
        self.assertEqual(selectors["AliasGradientImplementation"], "asm")
        self.assertEqual(selectors["AliasLineScanImplementation"], "asm")
        self.assertEqual(selectors["AliasEdgeTableImplementation"], "asm")
        self.assertEqual(selectors["AliasSkinTableImplementation"], "asm")
        self.assertEqual(selectors["AliasRasterizeImplementation"], "asm")
        self.assertEqual(selectors["MarkLightsImplementation"], "asm")
        self.assertEqual(selectors["DynamicLightPushImplementation"], "asm")
        reference_selectors = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )["selectors"]
        self.assertEqual(reference_selectors["MarkLightsImplementation"], "c")
        mark_lights_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-marklights.json").read_text(encoding="utf-8")
        )
        self.assertEqual(mark_lights_profile["selectors"]["MarkLightsImplementation"], "asm")
        self.assertEqual(
            {
                name: value
                for name, value in mark_lights_profile["selectors"].items()
                if name != "MarkLightsImplementation"
            },
            {
                name: value
                for name, value in reference_selectors.items()
                if name != "MarkLightsImplementation"
            },
        )
        self.assertEqual(reference_selectors["AliasMatrixCompositionImplementation"], "c")
        self.assertEqual(reference_selectors["AliasSetupLightingImplementation"], "c")
        self.assertEqual(reference_selectors["AliasSetupFrameImplementation"], "c")
        self.assertEqual(reference_selectors["AliasSetupSkinImplementation"], "c")
        self.assertEqual(reference_selectors["AliasGradientImplementation"], "c")
        self.assertEqual(reference_selectors["AliasLineScanImplementation"], "c")
        self.assertEqual(reference_selectors["AliasEdgeTableImplementation"], "c")
        self.assertEqual(reference_selectors["AliasSkinTableImplementation"], "c")
        self.assertEqual(reference_selectors["AliasRasterizeImplementation"], "c")
        self.assertEqual(reference_selectors["AliasPrepareImplementation"], "control")

    def test_particle_update_profile_changes_only_particle_simulation(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = json.loads((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = json.loads(
            (profiles / "i486-asm-particle-update.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["id"], "i486-asm-particle-update")
        self.assertEqual(candidate["selectors"]["ParticleUpdateImplementation"], "asm")
        self.assertEqual(
            set(reference["selectors"]),
            set(candidate["selectors"]),
        )
        self.assertEqual(
            {
                name: value
                for name, value in candidate["selectors"].items()
                if name != "ParticleUpdateImplementation"
            },
            {
                name: value
                for name, value in reference["selectors"].items()
                if name != "ParticleUpdateImplementation"
            },
        )

    def test_mark_lights_fixture_is_independent_of_lightmap_dispatcher(self) -> None:
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn(
            "#if defined(ASM486_MARK_LIGHTS) && defined(BENCH486)\n"
            "static int Bench486MarkLightsParity (void)",
            host_commands,
        )
        self.assertIn(
            "#if defined(ASM486_LIGHTMAP_BUILD) || defined(ASM486_MARK_LIGHTS) || defined(ASM486_DYNAMIC_LIGHT_PUSH)",
            host_commands,
        )
        self.assertNotIn(
            "#if defined(ASM486_MARK_LIGHTS) && defined(ASM486_LIGHTMAP_BUILD) && defined(BENCH486)",
            host_commands,
        )

    def test_dynamic_light_push_profile_and_fixture_are_isolated(self) -> None:
        reference = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-dlight-push.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate["selectors"]["DynamicLightPushImplementation"], "asm")
        self.assertEqual(
            {
                name: value
                for name, value in candidate["selectors"].items()
                if name != "DynamicLightPushImplementation"
            },
            {
                name: value
                for name, value in reference["selectors"].items()
                if name != "DynamicLightPushImplementation"
            },
        )

        source = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn(
            "#if defined(ASM486_DYNAMIC_LIGHT_PUSH) && defined(BENCH486)\n"
            "typedef struct\n{\n\tdouble time;",
            source,
        )
        self.assertIn("Bench486PushDlightsParity (void)", source)
        self.assertIn("0x80000000U", source)

    def test_promoted_renderer_profile_changes_only_verified_i486_paths(self) -> None:
        reference = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-promoted-renderers.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["id"], "i486-asm-promoted-renderers")
        self.assertEqual(set(candidate["selectors"]), set(reference["selectors"]))
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(
            changed,
            {
                "DynamicLightPushImplementation",
                "MarkLightsImplementation",
                "SpriteSetupImplementation",
            },
        )

    def test_promoted_renderer_profile_with_sprite_draw_has_four_assembly_paths(self) -> None:
        reference = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-promoted-renderers-spritedraw.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["id"], "i486-asm-promoted-renderers-spritedraw")
        self.assertEqual(set(candidate["selectors"]), set(reference["selectors"]))
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(
            changed,
            {
                "DynamicLightPushImplementation",
                "MarkLightsImplementation",
                "SpriteDrawImplementation",
                "SpriteSetupImplementation",
            },
        )

    def test_promoted_renderer_profile_with_sprite_frame_has_five_assembly_paths(self) -> None:
        reference = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-promoted-renderers-spriteframe.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["id"], "i486-asm-promoted-renderers-spriteframe")
        self.assertEqual(set(candidate["selectors"]), set(reference["selectors"]))
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(
            changed,
            {
                "DynamicLightPushImplementation",
                "MarkLightsImplementation",
                "SpriteDrawImplementation",
                "SpriteFrameImplementation",
                "SpriteSetupImplementation",
            },
        )

    def test_alias_matrix_composition_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-matrix.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-matrix")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasMatrixCompositionImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasMatrixCompositionImplementation"})

    def test_alias_setup_lighting_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-lighting.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-lighting")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasSetupLightingImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasSetupLightingImplementation"})

    def test_alias_prepare_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-prepare.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-prepare")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasPrepareImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasPrepareImplementation"})

    def test_alias_setup_frame_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-frame.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-frame")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasSetupFrameImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasSetupFrameImplementation"})

    def test_alias_setup_skin_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-skin.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-skin")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasSetupSkinImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasSetupSkinImplementation"})

    def test_alias_gradient_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-gradient.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-gradient")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasGradientImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasGradientImplementation"})

    def test_alias_line_scan_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-line-scan.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-line-scan")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasLineScanImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasLineScanImplementation"})

    def test_alias_edge_table_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-edge-table.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-edge-table")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasEdgeTableImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasEdgeTableImplementation"})

    def test_alias_skin_table_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-skin-table.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-skin-table")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasSkinTableImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasSkinTableImplementation"})

    def test_alias_rasterize_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-alias-rasterize.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-alias-rasterize")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["AliasRasterizeImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"AliasRasterizeImplementation"})

    def test_c_reference_profile_mirrors_assembly_selector_coverage(self) -> None:
        assembly_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-selectable.json").read_text(encoding="utf-8")
        )
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        self.assertEqual(reference_profile["schemaVersion"], 1)
        self.assertEqual(reference_profile["id"], "i486-c-reference")
        self.assertTrue(reference_profile["description"])
        self.assertEqual(set(reference_profile["selectors"]), set(assembly_profile["selectors"]))
        self.assertTrue(
            all(value in {"c", "control", "legacy"} for value in reference_profile["selectors"].values())
        )
        self.assertFalse(any(value == "asm" for value in reference_profile["selectors"].values()))

    def test_sprite_scan_left_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-sprite-scan-left.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-sprite-scan-left")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["SpriteScanLeftImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"SpriteScanLeftImplementation"})

    def test_sprite_scan_right_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-sprite-scan-right.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-sprite-scan-right")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["SpriteScanRightImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"SpriteScanRightImplementation"})

    def test_sprite_draw_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-sprite-draw.json").read_text(encoding="utf-8")
        )
        self.assertEqual(candidate_profile["schemaVersion"], 1)
        self.assertEqual(candidate_profile["id"], "i486-asm-sprite-draw")
        self.assertEqual(set(candidate_profile["selectors"]), set(reference_profile["selectors"]))
        self.assertEqual(candidate_profile["selectors"]["SpriteDrawImplementation"], "asm")
        changed = {
            name for name, value in candidate_profile["selectors"].items()
            if reference_profile["selectors"][name] != value
        }
        self.assertEqual(changed, {"SpriteDrawImplementation"})

    def test_bsp_screening_profile_excludes_measured_regressions(self) -> None:
        assembly_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-selectable.json").read_text(encoding="utf-8")
        )
        screened_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-bsp-c.json").read_text(encoding="utf-8")
        )
        self.assertEqual(screened_profile["schemaVersion"], 1)
        self.assertEqual(screened_profile["id"], "i486-asm-bsp-c")
        self.assertEqual(set(screened_profile["selectors"]), set(assembly_profile["selectors"]))
        self.assertEqual(screened_profile["selectors"]["BspClipImplementation"], "c")
        self.assertEqual(screened_profile["selectors"]["BspPlaneDotImplementation"], "c")
        for name, value in screened_profile["selectors"].items():
            expected = "c" if name in {
                "BspClipImplementation",
                "BspPlaneDotImplementation",
                "ParticleUpdateImplementation",
                "SpriteOrientationImplementation",
                "RenderMathImplementation",
                "AnimatedLightImplementation",
                "PointLightImplementation",
                "FrameControlImplementation",
                "PaletteImplementation",
                "MathClosureImplementation",
                "VisibilityImplementation",
                "PublicBindingsImplementation",
                "SkyImplementation",
            } else assembly_profile["selectors"][name]
            self.assertEqual(value, expected, name)

    def test_surface_alias_profile_keeps_world_edge_paths_on_reference(self) -> None:
        assembly_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-selectable.json").read_text(encoding="utf-8")
        )
        screened_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-surface-alias.json").read_text(encoding="utf-8")
        )
        self.assertEqual(screened_profile["schemaVersion"], 1)
        self.assertEqual(screened_profile["id"], "i486-asm-surface-alias")
        self.assertEqual(set(screened_profile["selectors"]), set(assembly_profile["selectors"]))
        reference_paths = {
            "BspClipImplementation",
            "BspPlaneDotImplementation",
            "BspWalkImplementation",
            "ParticleUpdateImplementation",
            "RenderWorldImplementation",
            "RenderFaceImplementation",
            "RenderBmodelFaceImplementation",
            "BmodelPolygonClipImplementation",
            "SolidClippedSubmodelPolygonsImplementation",
            "SubmodelPolygonsImplementation",
            "ZSubmodelPolygonsImplementation",
            "EdgeDrawingImplementation",
            "ScanEdgesImplementation",
            "EdgeListMaintenanceImplementation",
            "BackwardSpansImplementation",
            "EfragStoreImplementation",
            "EmitCachedEdgeImplementation",
            "RenderPolyImplementation",
            "SpriteOrientationImplementation",
            "RenderMathImplementation",
            "AnimatedLightImplementation",
            "PointLightImplementation",
            "FrameControlImplementation",
            "PaletteImplementation",
            "MathClosureImplementation",
            "VisibilityImplementation",
            "PublicBindingsImplementation",
            "SkyImplementation",
        }
        for name, value in screened_profile["selectors"].items():
            expected = "c" if name in reference_paths else assembly_profile["selectors"][name]
            self.assertEqual(value, expected, name)

    def test_world_and_edge_screen_profiles_change_only_their_group(self) -> None:
        base_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-asm-surface-alias.json").read_text(encoding="utf-8")
        )
        groups = {
            "i486-asm-world-group": {
                "BspWalkImplementation",
                "RenderWorldImplementation",
                "RenderFaceImplementation",
                "RenderBmodelFaceImplementation",
                "BmodelPolygonClipImplementation",
                "SolidClippedSubmodelPolygonsImplementation",
                "SubmodelPolygonsImplementation",
                "ZSubmodelPolygonsImplementation",
                "EfragStoreImplementation",
                "EmitCachedEdgeImplementation",
            },
            "i486-asm-edge-group": {
                "EdgeDrawingImplementation",
                "ScanEdgesImplementation",
                "EdgeListMaintenanceImplementation",
                "BackwardSpansImplementation",
            },
        }
        for profile_id, changed in groups.items():
            profile = json.loads(
                (ROOT / "tools/renderer-profiles" / f"{profile_id}.json").read_text(encoding="utf-8")
            )
            with self.subTest(profile=profile_id):
                self.assertEqual(profile["schemaVersion"], 1)
                self.assertEqual(profile["id"], profile_id)
                self.assertEqual(set(profile["selectors"]), set(base_profile["selectors"]))
                for name, value in profile["selectors"].items():
                    expected = "asm" if name in changed else base_profile["selectors"][name]
                    self.assertEqual(value, expected, name)

    def test_submodel_assembly_reads_cdecl_arguments_after_return_address(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_DrawSubmodelPolygons_asm486\):(?P<body>.*?"
            r"\.Lsubmodel_polygons_finish:.*?\bret)",
            assembly,
            re.DOTALL,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertRegex(body, r"(?m)^\s*movl\s+8\(%ebp\),%ebx\s+// pmodel")
        self.assertRegex(body, r"(?m)^\s*movl\s+12\(%ebp\),%edi\s+// clipflags")
        self.assertNotRegex(body, r"(?m)^\s*movl\s+4\(%ebp\),%ebx")

    def test_z_submodel_polygon_assembly_has_an_isolated_i486_profile_and_oracle(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = json.loads((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = json.loads((profiles / "i486-asm-zsubmodel.json").read_text(encoding="utf-8"))
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["id"], "i486-asm-zsubmodel")
        self.assertEqual(set(reference["selectors"]), set(candidate["selectors"]))
        self.assertEqual(candidate["selectors"]["ZSubmodelPolygonsImplementation"], "asm")
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(changed, {"ZSubmodelPolygonsImplementation"})

        assembly = (ROOT / "src/r_zsubmodelasm.s").read_text(encoding="utf-8")
        self.assertIn("C(R_ZDrawSubmodelPolys_asm486):", assembly)
        self.assertIn("fcompl\t.Lzsubmodel_negative_epsilon", assembly)
        self.assertIn("fcompl\t.Lzsubmodel_positive_epsilon", assembly)
        self.assertIn("testb\t$1,%ah", assembly)
        self.assertIn("testb\t$69,%ah", assembly)
        self.assertIn("call\tC(R_RenderPoly)", assembly)

        layout = (ROOT / "src/asm_zsubmodel.h").read_text(encoding="utf-8")
        for contract in (
            "offsetof(model_t, firstmodelsurface)",
            "offsetof(model_t, nummodelsurfaces)",
            "offsetof(model_t, surfaces)",
            "offsetof(msurface_t, plane)",
            "offsetof(msurface_t, flags)",
            "sizeof(msurface_t)",
            "offsetof(mplane_t, dist)",
        ):
            with self.subTest(contract=contract):
                self.assertIn(contract, layout)

        oracle = (ROOT / "src/r_draw.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_zsubmodel.h").read_text(encoding="utf-8")
        bench = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("R_ZDrawSubmodelPolys_C", oracle)
        self.assertIn("4096 continuous calls", fixture)
        self.assertIn("-benchzsubmodelpolys", bench)

    def test_frustum_transform_assembly_has_an_isolated_profile_and_guarded_oracle(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = json.loads((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = json.loads((profiles / "i486-asm-frustum-transform.json").read_text(encoding="utf-8"))
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["id"], "i486-asm-frustum-transform")
        self.assertEqual(set(reference["selectors"]), set(candidate["selectors"]))
        self.assertEqual(candidate["selectors"]["TransformFrustumImplementation"], "asm")
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(changed, {"TransformFrustumImplementation"})

        assembly = (ROOT / "src/r_frustumasm.s").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("C(R_TransformFrustum):", assembly)
        self.assertIn("call\tC(R_TransformFrustumCore_asm486)", assembly)
        self.assertIn("C(R_TransformFrustumCore_asm486):", assembly)
        self.assertIn("fchs", assembly)
        self.assertIn("faddp", assembly)
        self.assertIn("fxch", assembly)
        for screen_offset in (0, 20, 40, 60):
            self.assertIn(f"flds\t{screen_offset + 8}(%edi)", assembly)
        for clip_offset in (0, 24, 48, 72):
            for normal_offset in (0, 4, 8):
                offset = clip_offset + normal_offset
                operand = "(%eax)" if offset == 0 else f"{offset}(%eax)"
                self.assertIn(f"fsts\t{operand}", assembly)
            self.assertIn(f"fstps\t{clip_offset + 12}(%eax)", assembly)
        self.assertIn("pushl\t%edi", assembly)
        self.assertIn("popl\t%edi", assembly)
        self.assertNotRegex(assembly, r"(?i)\b(?:cmov\w*|mm\w*|[sv]se\w*)\b")

        layout = (ROOT / "src/asm_frustum.h").read_text(encoding="utf-8")
        for contract in (
            "sizeof(mplane_t) == FR_SCREEN_STRIDE",
            "offsetof(mplane_t, normal) == FR_SCREEN_NORMAL_X",
            "sizeof(clipplane_t) == FR_CLIP_STRIDE",
            "offsetof(clipplane_t, dist) == FR_CLIP_DIST",
        ):
            with self.subTest(contract=contract):
                self.assertIn(contract, layout)

        oracle = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_frustum.h").read_text(encoding="utf-8")
        bench = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("R_TransformFrustumCore_C", oracle)
        self.assertIn("4096 continuous calls", fixture)
        self.assertIn("frustum sequence progress", fixture)
        self.assertIn("-benchfrustumtransform", bench)

    def test_alias_light_conversion_truncates_like_the_c_cast(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_AliasTransformFinalVert_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertRegex(body, r"(?m)^\s*fnstcw\s+0\(%esp\)")
        self.assertRegex(body, r"(?m)^\s*orw\s+\$0x0c00,%dx")
        self.assertRegex(body, r"(?m)^\s*fldcw\s+2\(%esp\)\s*$")
        self.assertRegex(body, r"(?m)^\s*fistpl\s+Lalias_transform_temp\s*$")
        self.assertRegex(body, r"(?m)^\s*fldcw\s+0\(%esp\)\s*$")

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn('Bench486AliasTransformFinalCase ("fractional-cast", 3);', benchmark)

    def test_alias_transform_preserves_reference_x87_row_order(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_AliasTransformFinalVert_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        first_product = "\tfildl\tLalias_transform_coords\n"
        row_starts = []
        offset = 0
        while True:
            offset = body.find(first_product, offset)
            if offset < 0:
                break
            row_starts.append(offset)
            offset += len(first_product)
        self.assertEqual(len(row_starts), 3)

        expected_translation_offsets = (12, 28, 44)
        for index, translation_offset in enumerate(expected_translation_offsets):
            end = row_starts[index + 1] if index < 2 else len(body)
            row = body[row_starts[index]:end]
            translation = f"fadds\tC(aliastransform)+{translation_offset}"
            third_vertex = "\tfildl\tLalias_transform_coords+8\n"
            self.assertLess(row.index(translation), row.index(third_vertex))

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn('Bench486AliasTransformFinalCase ("x87-row-order", 4);', benchmark)

    def test_alias_bbox_vector_transform_preserves_reference_x87_row_order(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_AliasTransformVector_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        row_start = "\tflds\t0(%esi)\n"
        row_starts = []
        offset = 0
        while True:
            offset = body.find(row_start, offset)
            if offset < 0:
                break
            row_starts.append(offset)
            offset += len(row_start)
        self.assertEqual(len(row_starts), 3)

        for index, translation_offset in enumerate((12, 28, 44)):
            end = row_starts[index + 1] if index < 2 else len(body)
            row = body[row_starts[index]:end]
            translation = f"fadds\tC(aliastransform)+{translation_offset}"
            third_coordinate = "\tflds\t8(%esi)\n"
            self.assertLess(row.index(translation), row.index(third_coordinate))

        self.assertRegex(body, r"(?m)^\s*movl\s+12\(%esp\),%esi\s+// input vector$")
        self.assertRegex(body, r"(?m)^\s*movl\s+16\(%esp\),%edi\s+// output vector$")
        c_source = (ROOT / "src/r_alias.c").read_text(encoding="utf-8")
        self.assertIn("R_AliasTransformVector_asm486 (in, out);", c_source)

    def test_alias_transform_matrix_assembly_preserves_reference_order(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        macro = re.search(
            r"(?m)^\s*\.macro\s+CONCAT_TRANSFORM.*?^\s*\.endm\s*$",
            assembly,
            re.DOTALL,
        )
        self.assertIsNotNone(macro)
        body = macro.group(0)
        self.assertLess(body.index("faddp"), body.index(".if"))
        self.assertLess(body.index(".if"), body.index("fadds"))
        self.assertLess(body.index("fadds"), body.rindex("fmuls"))
        self.assertLess(body.rindex("fmuls"), body.rindex("faddp"))
        self.assertIn("CONCAT_TRANSFORM 12, 0, 12, 4, 28, 8, 44, 12", assembly)
        self.assertIn("R_ConcatTransforms_asm486 (t2matrix, tmatrix, rotationmatrix);", (ROOT / "src/r_alias.c").read_text(encoding="utf-8"))
        self.assertIn('Bench486AliasMatrixComposeCase ("translation-order", 1);', (ROOT / "src/host_cmd.c").read_text(encoding="utf-8"))
        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn('Bench486AliasTransformVectorCase ("x87-row-order", 1);', benchmark)

        view = re.search(
            r"C\(R_AliasSetViewMatrix_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(view)
        view_body = view.group("body")
        self.assertIn("pushl\t%ebx", view_body)
        self.assertIn("pushl\t%edi", view_body)
        self.assertEqual(view_body.count("xorl\t$0x80000000,%ebx"), 3)
        self.assertIn("popl\t%edi", view_body)
        self.assertIn("popl\t%ebx", view_body)
        self.assertNotRegex(view_body, r"(?i)\b(cmov[a-z]*|movnti|emms)\b")
        self.assertIn("R_AliasSetViewMatrix_asm486 (vright, vup, vpn", (ROOT / "src/r_alias.c").read_text(encoding="utf-8"))
        self.assertIn('Bench486AliasViewMatrixCase (names[i], vectors[i][0]', benchmark)

    def test_alias_setup_lighting_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_AliasSetupLighting_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("movl\t8(%ebp),%esi\t\t// alight_t *lighting", body)
        self.assertIn("cmpl\t$5,%eax", body)
        self.assertIn("shll\t$6,%edx", body)
        self.assertIn("fildl\t4(%esi)", body)
        self.assertIn("fmuls\t.Lalias_setup_lighting_grades", body)
        self.assertEqual(body.count("faddp\t%st(0),%st(1)"), 6)
        self.assertIn("fchs", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms)\b")

        c_source = (ROOT / "src/r_alias.c").read_text(encoding="utf-8")
        self.assertIn("void R_AliasSetupLighting_C (alight_t *plighting", c_source)
        self.assertIn("R_AliasSetupLighting_asm486 (plighting, alias_forward", c_source)
        self.assertIn("R_AliasSetupLighting_C (plighting, alias_forward", c_source)
        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("ambient-clamps", "negative-shade", "fractional-axes", "large-light-vector"):
            self.assertIn(f'{{"{case}",', benchmark)
        self.assertIn("Bench486AliasSetupLightingCase (&tests[step], mode, test_cw);", benchmark)

    def test_alias_setup_frame_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_AliasSetupFrame_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("shll\t$5,%eax", body)
        self.assertIn("leal\t16(%esi,%eax),%edi", body)
        self.assertIn("cmpl\t$0,0(%edi)", body)
        self.assertIn("faddl\t12(%ebp)", body)
        self.assertIn("fdiv\t%st(2),%st(0)", body)
        self.assertIn("fistpl\t-20(%ebp)", body)
        self.assertIn("movl\t-24(%ebp),%eax", body)
        self.assertIn("flds\t-4(%edi,%eax,4)", body)
        self.assertIn("movl\t16(%eax,%ecx,4),%eax", body)
        self.assertIn("fcoms\t(%edi,%edx,4)", body)
        self.assertIn("leal\t(%edx,%edx,2),%ecx", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms)\b")

        c_source = (ROOT / "src/r_alias.c").read_text(encoding="utf-8")
        self.assertIn("void R_AliasSetupFrame_C (int frame, double cltime, float syncbase)", c_source)
        self.assertIn("R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase);", c_source)
        self.assertIn("R_AliasSetupFrame_C (frame, cl.time, currententity->syncbase);", c_source)
        self.assertIn("offsetof(maliasframedesc_t, frame) == 12", c_source)
        self.assertIn("offsetof(maliasgroup_t, frames) == 8", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("single-frame", "boundary-first", "wrap-period", "negative-truncate-zero", "one-frame-group"):
            self.assertIn(f'{{"{case}",', benchmark)
        self.assertIn("4 * (int)(sizeof(tests)/sizeof(tests[0]))", benchmark)
        self.assertIn('COM_CheckParm ("-benchaliassetupframe")', benchmark)
        self.assertIn("Bench486AliasSetupFrameCases ();", benchmark)
        self.assertIn('group->intervals = 600;', benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$AliasSetupFrameImplementation = 'c'", bench_runner)
        self.assertIn("AliasSetupFrameImplementation = $AliasSetupFrameImplementation", bench_runner)
        self.assertIn("aliasSetupFrameImplementation = $AliasSetupFrameImplementation", bench_runner)
        self.assertIn("$AliasSetupFrameOnly -and $AliasSetupFrameImplementation -ne 'asm'", bench_runner)
        self.assertIn("-benchaliassetupframe -benchexit", bench_runner)

    def test_alias_setup_skin_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_AliasSetupSkinSelect_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("movl\t8(%esi),%edi", body)
        self.assertIn("leal\t(%edi,%eax,4),%edi", body)
        self.assertIn("cmpl\t$0,0(%edi)", body)
        self.assertIn("movl\t8(%edi),%ebx", body)
        self.assertIn("faddl\t12(%ebp)", body)
        self.assertIn("fdiv\t%st(2),%st(0)", body)
        self.assertIn("fistpl\t-20(%ebp)", body)
        self.assertIn("flds\t-4(%edi,%eax,4)", body)
        self.assertIn("fcoms\t(%edi,%edx,4)", body)
        self.assertIn("leal\t8(%eax,%ecx,4),%eax", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms)\b")

        c_source = (ROOT / "src/r_alias.c").read_text(encoding="utf-8")
        self.assertIn("maliasskindesc_t *R_AliasSetupSkinSelect_C", c_source)
        self.assertIn("R_AliasSetupSkinSelect_asm486 (skinnum, cl.time", c_source)
        self.assertIn("R_AliasSetupSkinSelect_C (skinnum, cl.time", c_source)
        self.assertIn("offsetof(maliasskindesc_t, skin) == 8", c_source)
        self.assertIn("offsetof(maliasskingroup_t, skindescs) == 8", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("single-skin", "boundary-first", "wrap-period", "negative-truncate-zero", "one-skin-group"):
            self.assertIn(f'{{"{case}",', benchmark)
        self.assertIn("4 * (int)(sizeof(tests)/sizeof(tests[0]))", benchmark)
        self.assertIn('COM_CheckParm ("-benchaliassetupskin")', benchmark)
        self.assertIn("Bench486AliasSetupSkinCases ();", benchmark)
        self.assertIn("group->intervals = 600;", benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$AliasSetupSkinImplementation = 'c'", bench_runner)
        self.assertIn("AliasSetupSkinImplementation = $AliasSetupSkinImplementation", bench_runner)
        self.assertIn("aliasSetupSkinImplementation = $AliasSetupSkinImplementation", bench_runner)
        self.assertIn("$AliasSetupSkinOnly -and $AliasSetupSkinImplementation -ne 'asm'", bench_runner)
        self.assertIn("-benchaliassetupskin -benchexit", bench_runner)

    def test_alias_triangle_gradients_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/d_polysa.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_PolysetCalcGradients_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("fildl\tC(r_p0)+0", body)
        self.assertIn("flds\tC(d_xdenom)", body)
        self.assertIn("fldcw\tceil_cw", body)
        self.assertIn("fldcw\tsingle_cw", body)
        self.assertIn("fistpl\tC(r_sstepx)", body)
        self.assertIn("imull\tskinwidth(%esp)", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms)\b")

        c_source = (ROOT / "src/d_polyse.c").read_text(encoding="utf-8")
        self.assertIn("void D_PolysetCalcGradients_C (int skinwidth)", c_source)
        self.assertIn("D_PolysetCalcGradients_asm486 (skinwidth);", c_source)
        self.assertIn("d_xdenom = d_xdenom_int;", c_source)
        self.assertIn("D_PolysetCalcGradients_C (skinwidth);", c_source)
        self.assertIn("int\t\t\td_xdenom_int;", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("standard-positive", "reverse-denominator", "negative-texture-slopes", "fractional-light-ceil", "large-fixed-coordinates"):
            self.assertIn(f'{{"{case}",', benchmark)
        self.assertIn("D_PolysetCalcGradients_C (test->skinwidth);", benchmark)
        self.assertIn("D_PolysetCalcGradients_asm486 (test->skinwidth);", benchmark)
        self.assertIn('COM_CheckParm ("-benchaliasgradients")', benchmark)
        self.assertIn("Bench486AliasGradientCases ();", benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$AliasGradientImplementation = 'asm'", bench_runner)
        self.assertIn("AliasGradientImplementation = $AliasGradientImplementation", bench_runner)
        self.assertIn("aliasGradientImplementation = $AliasGradientImplementation", bench_runner)
        self.assertIn("$AliasGradientsOnly -and $AliasGradientImplementation -ne 'asm'", bench_runner)
        self.assertIn("-benchaliasgradients -benchexit", bench_runner)

    def test_alias_line_scan_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/d_polysa.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_PolysetSetUpForLineScan_asm486\):(?P<body>.*?)(?=//-+\n// recursive subdivision)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("C(adivtab)(,%edx,8)", body)
        self.assertIn("idivl\t%ecx", body)
        self.assertIn("C(erroradjustup)", body)
        self.assertIn("C(erroradjustdown)", body)
        self.assertIn("C(D_PolysetSetUpForLineScan_C)", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms|fisttp)\b")

        c_source = (ROOT / "src/d_polyse.c").read_text(encoding="utf-8")
        self.assertIn("adivtab_t\tadivtab[64*64]", c_source)
        self.assertIn("void D_PolysetSetUpForLineScan_C", c_source)
        self.assertIn("D_PolysetSetUpForLineScan_asm486 (startvertu", c_source)
        self.assertIn("bench486_line_setup_calls++", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn("for (tm=-31 ; tm<=32 ; tm++)", benchmark)
        self.assertIn("D_PolysetSetUpForLineScan_C (0, 0, tm, tn);", benchmark)
        self.assertIn("D_PolysetSetUpForLineScan_asm486 (0, 0, tm, tn);", benchmark)
        self.assertIn('COM_CheckParm ("-benchaliaslinescan")', benchmark)
        self.assertIn("Bench486AliasLineScanCases ();", benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$AliasLineScanImplementation = 'asm'", bench_runner)
        self.assertIn("AliasLineScanImplementation = $AliasLineScanImplementation", bench_runner)
        self.assertIn("aliasLineScanImplementation = $AliasLineScanImplementation", bench_runner)
        self.assertIn("$AliasLineScanOnly -and $AliasLineScanImplementation -ne 'asm'", bench_runner)
        self.assertIn("-benchaliaslinescan -benchexit", bench_runner)

    def test_alias_edge_table_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/d_polysa.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_PolysetSetEdgeTable_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        for value in ("C(r_p0)+4", "C(r_p1)+4", "C(r_p2)+4", "C(edgetables)", "C(pedgetable)"):
            self.assertIn(value, body)
        self.assertIn("leal\t(%edx,%edx,8),%eax", body)
        self.assertIn("leal\tC(edgetables)(,%eax,4),%eax", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms|fisttp)\b")

        c_source = (ROOT / "src/d_polyse.c").read_text(encoding="utf-8")
        self.assertIn("typedef char edgetable_i486_size[(sizeof(edgetable) == 36) ? 1 : -1];", c_source)
        self.assertIn("void D_PolysetSetEdgeTable_C (void)", c_source)
        self.assertIn("D_PolysetSetEdgeTable_asm486 ();", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn("static void Bench486AliasEdgeTableCases (void)", benchmark)
        self.assertIn("D_PolysetSetEdgeTable_C ();", benchmark)
        self.assertIn("D_PolysetSetEdgeTable_asm486 ();", benchmark)
        self.assertIn('COM_CheckParm ("-benchaliasedgetable")', benchmark)
        self.assertIn("Bench486AliasEdgeTableCases ();", benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$AliasEdgeTableImplementation = 'asm'", bench_runner)
        self.assertIn("AliasEdgeTableImplementation = $AliasEdgeTableImplementation", bench_runner)
        self.assertIn("aliasEdgeTableImplementation = $AliasEdgeTableImplementation", bench_runner)
        self.assertIn("$AliasEdgeTableOnly -and $AliasEdgeTableImplementation -ne 'asm'", bench_runner)
        self.assertIn("-benchaliasedgetable -benchexit", bench_runner)

    def test_alias_skin_table_assembly_matches_reference_cache(self) -> None:
        assembly = (ROOT / "src/d_polysa.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_PolysetUpdateTables_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        for value in (
            "C(r_affinetridesc)+atd_skinwidth",
            "C(r_affinetridesc)+atd_pskin",
            "C(skinwidth)",
            "C(skinstart)",
            "C(skintable)",
        ):
            self.assertIn(value, body)
        self.assertIn("movl\t$480,%edi", body)
        self.assertIn("addl\t%ecx,%ebx", body)
        self.assertIn("addl\t$4,%esi", body)
        self.assertNotRegex(body, r"(?i)\b(cmov[a-z]*|movnti|emms|fisttp)\b")

        c_source = (ROOT / "src/d_polyse.c").read_text(encoding="utf-8")
        self.assertIn("void D_PolysetUpdateTables_C (void)", c_source)
        self.assertIn("D_PolysetUpdateTables_asm486 ();", c_source)
        self.assertIn("typedef char skintable_i486_rows", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        self.assertIn("static void Bench486AliasSkinTableCases (void)", benchmark)
        self.assertIn("D_PolysetUpdateTables_C ();", benchmark)
        self.assertIn("D_PolysetUpdateTables_asm486 ();", benchmark)
        self.assertIn('COM_CheckParm ("-benchaliasskintable")', benchmark)
        self.assertIn("Bench486AliasSkinTableCases ();", benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$AliasSkinTableImplementation = 'asm'", bench_runner)
        self.assertIn("AliasSkinTableImplementation = $AliasSkinTableImplementation", bench_runner)
        self.assertIn("aliasSkinTableImplementation = $AliasSkinTableImplementation", bench_runner)
        self.assertIn("$AliasSkinTableOnly -and $AliasSkinTableImplementation -ne 'asm'", bench_runner)
        self.assertIn("-benchaliasskintable -benchexit", bench_runner)

    def test_sprite_beam_translation_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_RotateSprite_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("C(r_spritedesc)+36", body)
        self.assertIn("C(r_entorigin)", body)
        self.assertIn("C(modelorg)", body)
        self.assertRegex(body, r"(?m)^\s*ftst\s*$")
        self.assertRegex(body, r"(?m)^\s*andb\s+\$0x45,%ah$")
        self.assertEqual(body.count("flds\t16(%esp)"), 3)
        self.assertRegex(body, r"(?m)^\s*fadds\s+0\(%esp\)")
        self.assertRegex(body, r"(?m)^\s*fsubs\s+0\(%esp\)")

        c_source = (ROOT / "src/r_sprite.c").read_text(encoding="utf-8")
        self.assertIn("void R_RotateSprite_C (float beamlength)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_BEAM", c_source)
        self.assertIn("R_RotateSprite_asm486 (beamlength);", c_source)
        self.assertIn("R_RotateSprite_C (beamlength);", c_source)
        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("zero", "negative-zero", "positive", "negative", "fractional", "small"):
            self.assertIn(f'Bench486SpriteBeamCase ("{case}",', benchmark)

    def test_sprite_face_clipping_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_ClipSpriteFace_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("C(clip_current)", body)
        self.assertIn("C(clip_verts)+400", body)
        self.assertIn("-116(%ebp)", body)
        self.assertRegex(body, r"(?m)^\s*testb\s+\$0x01,%ah$")
        self.assertGreaterEqual(body.count("andb\t$0x45,%ah"), 4)
        self.assertRegex(body, r"(?m)^\s*fsubr\s+%st\(1\),%st\(0\)$")
        self.assertRegex(body, r"(?m)^\s*fdivrp\s+%st\(0\),%st\(1\)$")
        self.assertEqual(body.count("fmul\t%st(1),%st(0)"), 5)
        self.assertRegex(body, r"(?m)^\s*fstp\s+%st\(0\)$")
        self.assertEqual(body.count("fstps\t"), 6)

        c_source = (ROOT / "src/r_sprite.c").read_text(encoding="utf-8")
        self.assertIn("int R_ClipSpriteFace_C (int nump, clipplane_t *pclipplane)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_CLIP", c_source)
        self.assertIn("return R_ClipSpriteFace_asm486 (nump, pclipplane);", c_source)
        self.assertIn("return R_ClipSpriteFace_C (nump, pclipplane);", c_source)
        self.assertIn("sizeof(clip_verts[0]) == 400", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in (
            "all-front-alt-buffer",
            "all-back",
            "fractional-crossings",
            "exact-plane-touch",
            "oblique-five-vertex",
            "near-plane-crossings",
        ):
            self.assertIn(f'Bench486SpriteClipCase ("{case}",', benchmark)

    def test_sprite_frame_selection_assembly_matches_reference_boundary(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_GetSpriteframe_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("24(%ebx,%esi,8)", body)
        self.assertIn("-4(%edi,%eax,4)", body)
        self.assertIn("faddl\t16(%ebp)", body)
        self.assertIn("fistpl\t-20(%ebp)", body)
        self.assertIn("orb\t$0x0c,%dh", body)
        self.assertIn("fcoms\t(%edi,%edx,4)", body)
        self.assertIn("fsubrp\t%st,%st(1)", body)
        self.assertRegex(body, r"(?m)^\s*fldcw\s+-16\(%ebp\)$")
        self.assertRegex(body, r"(?m)^\s*fstp\s+%st\(0\)$")

        c_source = (ROOT / "src/r_sprite.c").read_text(encoding="utf-8")
        self.assertIn("R_GetSpriteframe_C (msprite_t *psprite)", c_source)
        self.assertIn("#ifndef ASM486_SPRITE_FRAME", c_source)
        public_assembly = (ROOT / "src/r_spriteasm.s").read_text(encoding="utf-8")
        self.assertIn(".globl C(R_GetSpriteframe)", public_assembly)
        self.assertIn("call    C(R_GetSpriteframe_asm486)", public_assembly)
        self.assertIn("sizeof(mspriteframedesc_t) == 8", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in (
            "single-frame",
            "group-start",
            "boundary-first",
            "boundary-middle",
            "last-interval",
            "wrap-exact-period",
            "positive-multiple",
            "negative-truncate-zero",
            "negative-truncate-period",
            "syncbase-boundary",
            "negative-frame-fallback",
            "high-frame-fallback",
        ):
            self.assertIn(f'Bench486SpriteFrameCase ("{case}",', benchmark)

    def test_sprite_gradient_assembly_matches_reference_contract(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_SpriteCalculateGradients_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertEqual(body.count("call\tC(TransformVector)"), 4)
        self.assertIn("fdivrs\t.Lsprgrad_one", body)
        self.assertIn("fsts\tC(d_zistepu)", body)
        self.assertIn("fsts\tC(d_zistepv)", body)
        self.assertIn("fmul\t%st(3),%st(0)", body)
        self.assertEqual(body.count("fistpl\t-60(%ebp)"), 2)
        self.assertEqual(body.count("fldcw\t-54(%ebp)"), 2)

        c_source = (ROOT / "src/d_sprite.c").read_text(encoding="utf-8")
        self.assertIn("D_SpriteCalculateGradients_C (void)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_GRADIENTS", c_source)
        self.assertIn("D_SpriteCalculateGradients_asm486 (sprite_height);", c_source)
        self.assertIn("offsetof(spritedesc_t, vpn) == 36", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("oblique-camera", "positive-plane-distance", "large-viewport"):
            self.assertIn(f'Bench486SpriteGradientCase ("{case}",', benchmark)

    def test_sprite_scan_left_assembly_matches_reference_contract(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_SpriteScanLeftEdge_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn(".Lsprscanleft_fixed16", body)
        self.assertIn("fistpl", body)
        self.assertIn("fstps", body)

        c_source = (ROOT / "src/d_sprite.c").read_text(encoding="utf-8")
        self.assertIn("D_SpriteScanLeftEdge_C (void)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_SCAN_LEFT", c_source)
        self.assertIn("D_SpriteScanLeftEdge_asm486 (sprite_spans, minindex, maxindex,", c_source)
        self.assertIn("offsetof(emitpoint_t, v) == 4", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("fractional-quad-wrap", "five-vertex-nonzero-start", "negative-u"):
            self.assertIn(f'Bench486SpriteScanLeftCase ("{case}",', benchmark)

    def test_sprite_scan_right_assembly_matches_reference_contract(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_SpriteScanRightEdge_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertEqual(body.count("fcoms"), 9)
        self.assertIn("$-128,8(%edi)", body)
        self.assertIn("fistpl", body)
        self.assertIn("fstps", body)

        c_source = (ROOT / "src/d_sprite.c").read_text(encoding="utf-8")
        self.assertIn("D_SpriteScanRightEdge_C (void)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_SCAN_RIGHT", c_source)
        self.assertIn("r_refdef.fvrectright_adj", c_source)
        self.assertIn("D_SpriteScanRightEdge_asm486 (sprite_spans, minindex, maxindex,", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("fractional-quad", "viewport-clamp-wrap", "negative-slope-narrow-view"):
            self.assertIn(f'Bench486SpriteScanRightCase ("{case}",', benchmark)

    def test_sprite_draw_assembly_matches_reference_contract(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(D_DrawSprite_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("subl\t$12352,%esp", body)
        self.assertIn("imull\t$20,%eax", body)
        self.assertEqual(body.count("frndint"), 2)
        self.assertIn("call\tC(D_SpriteCalculateGradients)", body)
        self.assertIn("call\tC(D_SpriteScanLeftEdge)", body)
        self.assertIn("call\tC(D_SpriteScanRightEdge)", body)
        self.assertIn("call\tC(D_SpriteDrawSpans)", body)
        self.assertIn("fldcw\t-46(%ebp)", body)

        c_source = (ROOT / "src/d_sprite.c").read_text(encoding="utf-8")
        self.assertIn("void D_DrawSprite_C (void)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_DRAW", c_source)
        self.assertIn("D_DrawSprite_asm486 (r_spritedesc.nump, r_spritedesc.pverts,", c_source)
        self.assertIn("sizeof(sspan_t) == 12", c_source)
        self.assertIn("sizeof(emitpoint_t) == 20", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("fractional-rectangle", "viewport-clamp", "zero-scan"):
            self.assertIn(f'Bench486SpriteDrawCase ("{case}",', benchmark)
        self.assertIn('COM_CheckParm ("-benchspritedraw")', benchmark)
        self.assertIn("Bench486SpriteDrawCases ();", benchmark)

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$SpriteDrawImplementation = 'c'", bench_runner)
        self.assertIn("SpriteDrawImplementation = $SpriteDrawImplementation", bench_runner)
        self.assertIn("spriteDrawImplementation = $SpriteDrawImplementation", bench_runner)
        self.assertIn("$SpriteDrawOnly -and $SpriteDrawImplementation -ne 'asm'", bench_runner)

    def test_sprite_setup_assembly_matches_reference_contract(self) -> None:
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        routine = re.search(
            r"C\(R_SetupAndDrawSprite_asm486\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(routine)
        body = routine.group("body")
        self.assertIn("subl\t$640,%esp", body)
        self.assertIn("call\tC(R_ClipSpriteFace)", body)
        self.assertIn("call\tC(TransformVector)", body)
        self.assertIn("call\tC(D_DrawSprite)", body)
        self.assertIn("jp\t.Lsprite_setup_depth_ready", body)
        self.assertIn("imull\t$400,%eax", body)

        c_source = (ROOT / "src/r_sprite.c").read_text(encoding="utf-8")
        self.assertIn("void R_SetupAndDrawSprite_C (void)", c_source)
        self.assertIn("#ifdef ASM486_SPRITE_SETUP", c_source)
        self.assertIn("R_SetupAndDrawSprite_asm486 ();", c_source)
        self.assertIn("offsetof(clipplane_t, dist) == 12", c_source)
        self.assertIn("offsetof(mspriteframe_t, right) == 24", c_source)

        benchmark = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        for case in ("centered", "frustum-clipped", "near-plane", "outside-frustum", "backface"):
            self.assertIn(f'Bench486SpriteSetupCase ("{case}",', benchmark)
        self.assertIn('COM_CheckParm ("-benchspritesetup")', benchmark)
        self.assertIn("Bench486SpriteSetupCases ();", benchmark)
        self.assertIn("exact projected/framebuffer result", benchmark)

        profiles = ROOT / "tools/renderer-profiles"
        reference = json.loads((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = json.loads((profiles / "i486-asm-sprite-setup.json").read_text(encoding="utf-8"))
        self.assertEqual(set(reference["selectors"]), set(candidate["selectors"]))
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(changed, {"SpriteSetupImplementation"})
        self.assertEqual(candidate["selectors"]["SpriteSetupImplementation"], "asm")

        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$SpriteSetupImplementation = 'c'", bench_runner)
        self.assertIn("SpriteSetupImplementation = $SpriteSetupImplementation", bench_runner)
        self.assertIn("spriteSetupImplementation = $SpriteSetupImplementation", bench_runner)
        self.assertIn("$SpriteSetupOnly -and $SpriteSetupImplementation -ne 'asm'", bench_runner)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RenderingComparisonTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
