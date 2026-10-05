"""Host tests for the PCX decoder, tolerant comparison, and frame-log parser."""

from __future__ import annotations

import importlib.util
import json
import struct
import sys
import tempfile
import unittest
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


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RenderingComparisonTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
