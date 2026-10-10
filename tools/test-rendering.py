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

OWNERSHIP_TOOL = Path(__file__).with_name("renderer-ownership.py")
OWNERSHIP_SPEC = importlib.util.spec_from_file_location("renderer_ownership", OWNERSHIP_TOOL)
assert OWNERSHIP_SPEC and OWNERSHIP_SPEC.loader
renderer_ownership = importlib.util.module_from_spec(OWNERSHIP_SPEC)
sys.modules[OWNERSHIP_SPEC.name] = renderer_ownership
OWNERSHIP_SPEC.loader.exec_module(renderer_ownership)

REPORT_COMPARATOR_TOOL = Path(__file__).with_name("compare-rendering-reports.py")
REPORT_COMPARATOR_SPEC = importlib.util.spec_from_file_location(
    "compare_rendering_reports", REPORT_COMPARATOR_TOOL
)
assert REPORT_COMPARATOR_SPEC and REPORT_COMPARATOR_SPEC.loader
report_comparator = importlib.util.module_from_spec(REPORT_COMPARATOR_SPEC)
sys.modules[REPORT_COMPARATOR_SPEC.name] = report_comparator
REPORT_COMPARATOR_SPEC.loader.exec_module(report_comparator)


def load_json(text: str) -> dict:
    """Load JSON and treat newer renderer selectors as C in older profiles."""
    document = json.loads(text)
    if (
        isinstance(document, dict)
        and document.get("schemaVersion") == 1
        and str(document.get("id", "")).startswith("i486-")
        and not str(document.get("id", "")).startswith("i486-viewcontrol-")
        and isinstance(document.get("selectors"), dict)
    ):
        document["selectors"].setdefault("LineGraphImplementation", "c")
        document["selectors"].setdefault("AliasStatsImplementation", "c")
        document["selectors"].setdefault("PrintTimesImplementation", "c")
        document["selectors"].setdefault("ParticleExplosionImplementation", "c")
        document["selectors"].setdefault("ParticleExplosion2Implementation", "c")
        document["selectors"].setdefault("BlobExplosionImplementation", "c")
        document["selectors"].setdefault("LavaSplashImplementation", "c")
        document["selectors"].setdefault("RocketTrailImplementation", "c")
        document["selectors"].setdefault("TransformPlaneImplementation", "c")
        document["selectors"].setdefault("ParticleDrawImplementation", "c")
    return document


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

    def test_required_blob_explosion_events_gate_paired_report_parity(self) -> None:
        def write_report(
            name: str,
            event: dict | None,
            *,
            required: list[str] | None = None,
        ) -> Path:
            checksum_path = self.root / f"{name}-checksums.txt"
            checksum_rows = "".join(f"{frame} {123 + frame}\n" for frame in range(16))
            checksum_path.write_text(f"{checksum_rows}frames 16 overflow 0\n", encoding="ascii")
            image_path = self.capture(f"{name}.pcx")
            diagnostic = {"run": 1, "frameChecksumPath": str(checksum_path)}
            if event is not None:
                diagnostic.update(event)
            scenario = {
                "scenario": "blob-explosion-fixture",
                "result": "PASS",
                "ignoredWarmupChecksumFrames": 2,
                "frameDiagnostics": [diagnostic],
                "imageComparisons": [{"actual": {"path": str(image_path)}}],
            }
            if required is not None:
                scenario["requiredBenchEvents"] = required
            report_path = self.root / f"{name}-report.json"
            report_path.write_text(
                json.dumps({
                    "schemaVersion": 1,
                    "result": "PASS",
                    "cpuTarget": "i486",
                    "sourceTreeFingerprint": "fixture-tree",
                    "scenarios": [scenario],
                }),
                encoding="utf-8",
            )
            return report_path

        required_event = {
            # Frame 15 is valid in the 16-record stream even though two leading
            # checksum frames are excluded from post-warmup stability metrics.
            "blobExplosionEventFrames": [7, 15],
            "blobExplosionEventOverflow": 0,
        }
        reference = write_report("event-reference", required_event, required=["blobExplosion"])
        matching = write_report("event-matching", required_event, required=["blobExplosion"])
        passed = report_comparator.compare_reports(reference, matching)
        self.assertTrue(passed["pass"])
        self.assertEqual(
            passed["scenarios"][0]["requiredBenchEvents"],
            {
                "reference": ["blobExplosion"],
                "candidate": ["blobExplosion"],
                "match": True,
                "events": ["blobExplosion"],
            },
        )
        event_result = passed["scenarios"][0]["runs"][0]["benchEvents"]["blobExplosion"]
        self.assertTrue(event_result["pass"])
        self.assertTrue(event_result["framesMatch"])

        failing_cases = (
            ("different-frames", {"blobExplosionEventFrames": [7, 12], "blobExplosionEventOverflow": 0}, "framesMatch"),
            ("missing-metadata", None, "dataPresent"),
            ("zero-events", {"blobExplosionEventFrames": [], "blobExplosionEventOverflow": 0}, "hasEvents"),
            ("overflow", {"blobExplosionEventFrames": [7], "blobExplosionEventOverflow": 1}, "noOverflow"),
            ("frame-index-past-stream", {"blobExplosionEventFrames": [7, 16], "blobExplosionEventOverflow": 0}, "frameIndicesInRange"),
            ("negative-frame-index", {"blobExplosionEventFrames": [-1, 7], "blobExplosionEventOverflow": 0}, "frameIndicesInRange"),
        )
        for name, event_data, failed_state in failing_cases:
            with self.subTest(case=name):
                candidate = write_report(name, event_data, required=["blobExplosion"])
                compared = report_comparator.compare_reports(reference, candidate)
                self.assertFalse(compared["pass"])
                event_report = compared["scenarios"][0]["runs"][0]["benchEvents"]["blobExplosion"]
                self.assertFalse(event_report["pass"])
                if failed_state == "framesMatch":
                    self.assertFalse(event_report[failed_state])
                else:
                    self.assertFalse(event_report["candidate"][failed_state])

        undeclared_candidate = write_report("requirement-drift", required_event, required=[])
        requirement_drift = report_comparator.compare_reports(reference, undeclared_candidate)
        self.assertFalse(requirement_drift["pass"])
        self.assertFalse(requirement_drift["scenarios"][0]["requiredBenchEvents"]["match"])

        out_of_range_reference = write_report(
            "reference-frame-index-past-stream",
            {"blobExplosionEventFrames": [7, 16], "blobExplosionEventOverflow": 0},
            required=["blobExplosion"],
        )
        reference_range = report_comparator.compare_reports(out_of_range_reference, matching)
        self.assertFalse(reference_range["pass"])
        self.assertFalse(
            reference_range["scenarios"][0]["runs"][0]["benchEvents"]["blobExplosion"]
            ["reference"]["frameIndicesInRange"]
        )

        no_requirement_reference = write_report("optional-reference", None)
        no_requirement_candidate = write_report("optional-candidate", None)
        optional = report_comparator.compare_reports(no_requirement_reference, no_requirement_candidate)
        self.assertTrue(optional["pass"])

    def test_required_lavasplash_event_requires_exact_frame_and_pair_parity(self) -> None:
        expected = {"lavaSplash": [10]}

        def write_report(name: str, event: dict | None, *, expected_frames: dict = expected) -> Path:
            checksum_path = self.root / f"{name}-checksums.txt"
            checksum_rows = "".join(f"{frame} {123 + frame}\n" for frame in range(16))
            checksum_path.write_text(f"{checksum_rows}frames 16 overflow 0\n", encoding="ascii")
            image_path = self.capture(f"{name}.pcx")
            diagnostic = {"run": 1, "frameChecksumPath": str(checksum_path)}
            if event is not None:
                diagnostic.update(event)
            scenario = {
                "scenario": "demo2-lavasplash-event",
                "result": "PASS",
                "reference": None,
                "captureFrame": 10,
                "ignoredWarmupChecksumFrames": 2,
                "requiredBenchEvents": ["lavaSplash"],
                "expectedBenchEventFrames": expected_frames,
                "frameDiagnostics": [diagnostic],
                "imageComparisons": [{"actual": {"path": str(image_path)}}],
            }
            report_path = self.root / f"{name}-report.json"
            report_path.write_text(json.dumps({
                "schemaVersion": 1,
                "result": "PASS",
                "cpuTarget": "i486",
                "sourceTreeFingerprint": "fixture-tree",
                "scenarios": [scenario],
            }), encoding="utf-8")
            return report_path

        valid_event = {
            "lavaSplashEventCount": 1,
            "lavaSplashEventFrames": [10],
            "lavaSplashEventOverflow": 0,
        }
        reference = write_report("lava-reference", valid_event)
        candidate = write_report("lava-candidate", valid_event)
        compared = report_comparator.compare_reports(reference, candidate)
        self.assertTrue(compared["pass"])
        run = compared["scenarios"][0]["runs"][0]
        self.assertTrue(run["frameChecksums"]["exactMatch"])
        self.assertTrue(run["framebuffer"]["exactMatch"])
        self.assertTrue(run["benchEvents"]["lavaSplash"]["pass"])
        self.assertEqual(run["benchEvents"]["lavaSplash"]["expectedFrames"]["reference"], [10])

        invalid_cases = (
            ("wrong-frame", {"lavaSplashEventCount": 1, "lavaSplashEventFrames": [9], "lavaSplashEventOverflow": 0}),
            ("wrong-count", {"lavaSplashEventCount": 2, "lavaSplashEventFrames": [10], "lavaSplashEventOverflow": 0}),
            ("overflow", {"lavaSplashEventCount": 2, "lavaSplashEventFrames": [10], "lavaSplashEventOverflow": 1}),
            ("missing-count", {"lavaSplashEventFrames": [10], "lavaSplashEventOverflow": 0}),
            ("missing-event", None),
        )
        for name, event_data in invalid_cases:
            with self.subTest(case=name):
                invalid = write_report(name, event_data)
                result = report_comparator.compare_reports(reference, invalid)
                self.assertFalse(result["pass"])
                self.assertFalse(result["scenarios"][0]["runs"][0]["benchEvents"]["lavaSplash"]["pass"])

        wrong_expected = write_report("wrong-expected", valid_event, expected_frames={"lavaSplash": [9]})
        expected_result = report_comparator.compare_reports(reference, wrong_expected)
        self.assertFalse(expected_result["pass"])
        self.assertFalse(
            expected_result["scenarios"][0]["runs"][0]["benchEvents"]["lavaSplash"]["expectedFramesMatch"]
        )

    def test_required_teleportsplash_event_requires_exact_frame_and_pair_parity(self) -> None:
        expected = {"teleportSplash": [10]}

        def write_report(name: str, event: dict | None, *, expected_frames: dict = expected) -> Path:
            checksum_path = self.root / f"{name}-checksums.txt"
            checksum_rows = "".join(f"{frame} {123 + frame}\n" for frame in range(16))
            checksum_path.write_text(f"{checksum_rows}frames 16 overflow 0\n", encoding="ascii")
            image_path = self.capture(f"{name}.pcx")
            diagnostic = {"run": 1, "frameChecksumPath": str(checksum_path)}
            if event is not None:
                diagnostic.update(event)
            scenario = {
                "scenario": "demo2-teleportsplash-event",
                "result": "PASS",
                "reference": None,
                "captureFrame": 10,
                "ignoredWarmupChecksumFrames": 2,
                "requiredBenchEvents": ["teleportSplash"],
                "expectedBenchEventFrames": expected_frames,
                "frameDiagnostics": [diagnostic],
                "imageComparisons": [{"actual": {"path": str(image_path)}}],
            }
            report_path = self.root / f"{name}-report.json"
            report_path.write_text(json.dumps({
                "schemaVersion": 1,
                "result": "PASS",
                "cpuTarget": "i486",
                "sourceTreeFingerprint": "fixture-tree",
                "scenarios": [scenario],
            }), encoding="utf-8")
            return report_path

        valid_event = {
            "teleportSplashEventCount": 1,
            "teleportSplashEventFrames": [10],
            "teleportSplashEventOverflow": 0,
        }
        reference = write_report("teleport-reference", valid_event)
        candidate = write_report("teleport-candidate", valid_event)
        compared = report_comparator.compare_reports(reference, candidate)
        self.assertTrue(compared["pass"])
        run = compared["scenarios"][0]["runs"][0]
        self.assertTrue(run["frameChecksums"]["exactMatch"])
        self.assertTrue(run["framebuffer"]["exactMatch"])
        self.assertTrue(run["benchEvents"]["teleportSplash"]["pass"])
        self.assertEqual(run["benchEvents"]["teleportSplash"]["expectedFrames"]["reference"], [10])

        invalid_cases = (
            ("wrong-frame", {"teleportSplashEventCount": 1, "teleportSplashEventFrames": [9], "teleportSplashEventOverflow": 0}),
            ("wrong-count", {"teleportSplashEventCount": 2, "teleportSplashEventFrames": [10], "teleportSplashEventOverflow": 0}),
            ("overflow", {"teleportSplashEventCount": 2, "teleportSplashEventFrames": [10], "teleportSplashEventOverflow": 1}),
            ("missing-count", {"teleportSplashEventFrames": [10], "teleportSplashEventOverflow": 0}),
            ("missing-event", None),
        )
        for name, event_data in invalid_cases:
            with self.subTest(case=name):
                invalid = write_report(name, event_data)
                result = report_comparator.compare_reports(reference, invalid)
                self.assertFalse(result["pass"])
                self.assertFalse(result["scenarios"][0]["runs"][0]["benchEvents"]["teleportSplash"]["pass"])

        wrong_expected = write_report("wrong-expected", valid_event, expected_frames={"teleportSplash": [9]})
        expected_result = report_comparator.compare_reports(reference, wrong_expected)
        self.assertFalse(expected_result["pass"])
        self.assertFalse(
            expected_result["scenarios"][0]["runs"][0]["benchEvents"]["teleportSplash"]["expectedFramesMatch"]
        )

    def test_required_run_particle_effect_event_requires_exact_frame_and_pair_parity(self) -> None:
        expected = {"runParticleEffect": [10]}

        def write_report(name: str, event: dict | None, *, expected_frames: dict = expected) -> Path:
            checksum_path = self.root / f"{name}-checksums.txt"
            checksum_rows = "".join(f"{frame} {123 + frame}\n" for frame in range(16))
            checksum_path.write_text(f"{checksum_rows}frames 16 overflow 0\n", encoding="ascii")
            image_path = self.capture(f"{name}.pcx")
            diagnostic = {"run": 1, "frameChecksumPath": str(checksum_path)}
            if event is not None:
                diagnostic.update(event)
            scenario = {
                "scenario": "demo2-wizspike-event",
                "result": "PASS",
                "reference": None,
                "captureFrame": 10,
                "ignoredWarmupChecksumFrames": 2,
                "requiredBenchEvents": ["runParticleEffect"],
                "expectedBenchEventFrames": expected_frames,
                "frameDiagnostics": [diagnostic],
                "imageComparisons": [{"actual": {"path": str(image_path)}}],
            }
            report_path = self.root / f"{name}-report.json"
            report_path.write_text(json.dumps({
                "schemaVersion": 1,
                "result": "PASS",
                "cpuTarget": "i486",
                "sourceTreeFingerprint": "fixture-tree",
                "scenarios": [scenario],
            }), encoding="utf-8")
            return report_path

        valid_event = {
            "runParticleEffectEventCount": 1,
            "runParticleEffectEventFrames": [10],
            "runParticleEffectEventOverflow": 0,
        }
        reference = write_report("run-particle-effect-reference", valid_event)
        candidate = write_report("run-particle-effect-candidate", valid_event)
        compared = report_comparator.compare_reports(reference, candidate)
        self.assertTrue(compared["pass"])
        run = compared["scenarios"][0]["runs"][0]
        self.assertTrue(run["frameChecksums"]["exactMatch"])
        self.assertTrue(run["framebuffer"]["exactMatch"])
        self.assertTrue(run["benchEvents"]["runParticleEffect"]["pass"])
        self.assertEqual(run["benchEvents"]["runParticleEffect"]["expectedFrames"]["reference"], [10])

        invalid_cases = (
            ("wrong-frame", {"runParticleEffectEventCount": 1, "runParticleEffectEventFrames": [9], "runParticleEffectEventOverflow": 0}),
            ("wrong-count", {"runParticleEffectEventCount": 2, "runParticleEffectEventFrames": [10], "runParticleEffectEventOverflow": 0}),
            ("overflow", {"runParticleEffectEventCount": 2, "runParticleEffectEventFrames": [10], "runParticleEffectEventOverflow": 1}),
            ("missing-count", {"runParticleEffectEventFrames": [10], "runParticleEffectEventOverflow": 0}),
            ("missing-event", None),
        )
        for name, event_data in invalid_cases:
            with self.subTest(case=name):
                invalid = write_report(name, event_data)
                result = report_comparator.compare_reports(reference, invalid)
                self.assertFalse(result["pass"])
                self.assertFalse(result["scenarios"][0]["runs"][0]["benchEvents"]["runParticleEffect"]["pass"])

        wrong_expected = write_report("wrong-expected", valid_event, expected_frames={"runParticleEffect": [9]})
        expected_result = report_comparator.compare_reports(reference, wrong_expected)
        self.assertFalse(expected_result["pass"])
        self.assertFalse(
            expected_result["scenarios"][0]["runs"][0]["benchEvents"]["runParticleEffect"]["expectedFramesMatch"]
        )

    def test_render_validation_enforces_and_exports_required_event_data(self) -> None:
        source = (ROOT / "tools/render-validation-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("$requiredBenchEvents -contains 'blobExplosion'", source)
        self.assertIn("test = 'required-bench-event'", source)
        self.assertIn("blobExplosionEventFrames = $blobExplosionEventFrames", source)
        self.assertIn("blobExplosionEventOverflow = $blobExplosionEventOverflow", source)
        self.assertIn("$checksumStreamFrameCount = $frameData.Checksums.Count", source)
        self.assertIn("$_ -lt 0 -or $_ -ge $checksumStreamFrameCount", source)
        self.assertIn("checksumFramesAfterWarmup = $checksumPostWarmupFrameCount", source)
        self.assertIn("outside the total $checksumStreamFrameCount-frame checksum stream", source)
        self.assertIn("$rendererSelectorProfileData.selectors.PSObject.Properties['ParticleDrawImplementation']", source)
        self.assertIn("NotePropertyValue 'c'", source)
        self.assertIn("Compare-Bench486EventRepeat", source)
        self.assertIn("repeat-blob-explosion-event-stability", source)
        self.assertIn("blobExplosionEventRepeatParity = $blobExplosionEventRepeatParity", source)
        self.assertIn("$requiredBenchEvents -contains 'lavaSplash'", source)
        self.assertIn("lavaSplashEventCount = $lavaSplashEventCount", source)
        self.assertIn("expectedBenchEventFrames = $expectedBenchEventFrames", source)
        self.assertIn("expectedLavaSplashEventFrames", source)
        self.assertIn("repeat-lava-splash-event-stability", source)
        self.assertLess(
            source.index("required lavaSplash event count/frame/overflow metadata is missing"),
            source.index("if ($SkipGoldenImageComparison)"),
            "pair-only scenarios must enforce LavaSplash telemetry before deferring golden-image comparison",
        )
        self.assertIn("$lavaSplashEventFrames", source[source.index("foreach ($captureBenchEvent") :])
        self.assertIn("$requiredBenchEvents -contains 'teleportSplash'", source)
        self.assertIn("teleportSplashEventCount = $teleportSplashEventCount", source)
        self.assertIn("teleportSplashEventFrames = $teleportSplashEventFrames", source)
        self.assertIn("teleportSplashEventOverflow = $teleportSplashEventOverflow", source)
        self.assertIn("repeat-teleport-splash-event-stability", source)
        self.assertIn("$teleportSplashEventFrames", source[source.index("foreach ($captureBenchEvent") :])
        self.assertLess(
            source.index("required teleportSplash event count/frame/overflow metadata is missing"),
            source.index("if ($SkipGoldenImageComparison)"),
            "pair-only scenarios must enforce TeleportSplash telemetry before deferring golden-image comparison",
        )
        self.assertIn("$requiredBenchEvents -contains 'runParticleEffect'", source)
        self.assertIn("runParticleEffectEventCount = $runParticleEffectEventCount", source)
        self.assertIn("runParticleEffectEventFrames = $runParticleEffectEventFrames", source)
        self.assertIn("runParticleEffectEventOverflow = $runParticleEffectEventOverflow", source)
        self.assertIn("repeat-run-particle-effect-event-stability", source)
        self.assertIn("$runParticleEffectEventFrames", source[source.index("foreach ($captureBenchEvent") :])
        self.assertLess(
            source.index("required runParticleEffect event count/frame/overflow metadata is missing"),
            source.index("if ($SkipGoldenImageComparison)"),
            "pair-only scenarios must enforce R_RunParticleEffect telemetry before deferring golden-image comparison",
        )

    def test_repeat_event_parity_helper_is_wired_and_covers_frames_and_overflow(self) -> None:
        source = (ROOT / "tools/bench-event-repeat.ps1").read_text(encoding="utf-8")
        runner = (ROOT / "tools/render-validation-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("framesMatch = $framesMatch", source)
        self.assertIn("overflowMatch = $overflowMatch", source)
        self.assertIn("exactMatch = $framesMatch -and $overflowMatch", source)
        self.assertIn("bench-event-repeat.ps1", runner)

    def test_timedemo_event_parser_accepts_overflow_accounting_contract(self) -> None:
        source = (ROOT / "tools/timedemo-event-record.ps1").read_text(encoding="utf-8")
        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        workflow_source = (ROOT / "tools/run-tests.ps1").read_text(encoding="utf-8")
        self.assertIn("$count -ne ($frames.Count + $overflow)", source)
        self.assertIn("if ($eventLines.Count -eq 0)", source)
        self.assertIn("Frames = $null", source)
        self.assertIn("Read-Bench486BlobExplosionEvents -Report $report", timedemo_source)
        self.assertIn("Read-Bench486LavaSplashEvents -Report $report", timedemo_source)
        self.assertIn("Read-Bench486TeleportSplashEvents -Report $report", timedemo_source)
        self.assertIn("Read-Bench486RunParticleEffectEvents -Report $report", timedemo_source)
        self.assertIn("test-timedemo-event-record.ps1", workflow_source)

    def test_scenario_manifest_has_pinned_references(self) -> None:
        manifest = load_json((ROOT / "tools/render-scenarios.json").read_text(encoding="utf-8"))
        scenarios = manifest["scenarios"]
        self.assertTrue(scenarios)
        self.assertIn("host_framerate 0.0783", manifest["validationAutoexecCommands"])
        self.assertGreaterEqual(manifest["warmupChecksumFrames"], 0)
        self.assertEqual(len({scene["id"] for scene in scenarios}), len(scenarios))
        scenario_by_id = {scene["id"]: scene for scene in scenarios}
        self.assertEqual(scenario_by_id["demo1-vesa-full"]["autoexecCommands"], ["d_subdiv16 1"])
        self.assertEqual(scenario_by_id["demo1-drawspans8"]["autoexecCommands"], ["d_subdiv16 0"])
        drawspans8 = scenario_by_id["demo1-drawspans8"]
        self.assertEqual(drawspans8["reference"], "tools/golden/render/demo1-drawspans8.pcx")
        self.assertNotEqual(drawspans8["reference"], scenario_by_id["demo1-vesa-full"]["reference"])
        self.assertEqual(drawspans8["expectedChecksum"], 3987640479)
        self.assertEqual(
            drawspans8["tolerance"],
            {"channel": 0, "maxChangedPixelFraction": 0, "maxMeanAbsoluteError": 0},
        )
        for scene in scenarios:
            with self.subTest(scene=scene["id"]):
                self.assertGreater(scene["expectedFrames"], 0)
                self.assertGreater(scene["expectedChecksum"], 0)
                self.assertGreaterEqual(scene["repeatRuns"], 2)
                reference = ROOT / scene["reference"]
                image = rendering.load_pcx(reference)
                self.assertEqual((image.width, image.height), (320, 200))

    def test_blob_explosion_scenario_manifest_is_pinned_and_requires_event(self) -> None:
        base_manifest = load_json((ROOT / "tools/render-scenarios.json").read_text(encoding="utf-8"))
        focused_manifest = load_json(
            (ROOT / "tools/render-scenarios-blob-explosion.json").read_text(encoding="utf-8")
        )
        self.assertEqual(focused_manifest["warmupChecksumFrames"], 4)
        base_scenario = next(
            scene for scene in base_manifest["scenarios"]
            if scene["id"] == "demo2-entity-workload"
        )
        self.assertEqual(len(focused_manifest["scenarios"]), 1)
        focused_scenario = focused_manifest["scenarios"][0]
        self.assertEqual(focused_scenario["id"], "demo2-blob-explosion-event")
        self.assertEqual(focused_scenario["demo"], base_scenario["demo"])
        self.assertEqual(focused_scenario["quakeExtraArgs"], base_scenario["quakeExtraArgs"])
        self.assertEqual(focused_scenario["expectedFrames"], 10)
        self.assertEqual(focused_scenario["expectedChecksum"], 2074560903)
        self.assertEqual(focused_scenario["captureFrame"], 10)
        self.assertGreaterEqual(focused_scenario["repeatRuns"], 2)
        self.assertEqual(
            focused_scenario["reference"],
            "tools/golden/render/blob-explosion-event.pcx",
        )
        self.assertEqual(
            focused_scenario["tolerance"],
            {"channel": 0, "maxChangedPixelFraction": 0, "maxMeanAbsoluteError": 0},
        )
        self.assertEqual(
            focused_scenario["demoFixture"],
            {
                "sourceMember": "demo2.dem",
                "firstPostSignonRecord": 4,
                "keepPostSignonRecords": 11,
                "eventRecord": 14,
                "eventType": 4,
                "coordShorts": [-2136, 17413, 9968],
                "pakEntry": "demo2.dem",
            },
        )
        self.assertEqual(focused_scenario["requiredBenchEvents"], ["blobExplosion"])
        self.assertEqual(focused_scenario["captureBenchEvents"], ["blobExplosion"])
        self.assertIn("TE_TAREXPLOSION", focused_scenario["description"])

    def test_lavasplash_scenario_is_pair_only_exact_and_uses_isolated_profiles(self) -> None:
        manifest = load_json(
            (ROOT / "tools/render-scenarios-lavasplash.json").read_text(encoding="utf-8")
        )
        self.assertEqual(manifest["warmupChecksumFrames"], 4)
        self.assertEqual(len(manifest["scenarios"]), 1)
        scene = manifest["scenarios"][0]
        self.assertEqual(scene["id"], "demo2-lavasplash-event")
        self.assertIn("TE_LAVASPLASH", scene["description"])
        self.assertEqual(scene["expectedFrames"], 10)
        self.assertEqual(scene["expectedChecksum"], 0)
        self.assertEqual(scene["captureFrame"], 10)
        self.assertEqual(scene["requiredBenchEvents"], ["lavaSplash"])
        self.assertEqual(scene["expectedBenchEventFrames"], {"lavaSplash": [10]})
        self.assertEqual(scene["captureBenchEvents"], ["lavaSplash"])
        self.assertIsNone(scene["reference"])
        self.assertEqual(
            scene["tolerance"],
            {"channel": 0, "maxChangedPixelFraction": 0, "maxMeanAbsoluteError": 0},
        )
        self.assertEqual(
            scene["demoFixture"],
            {
                "sourceMember": "demo2.dem",
                "firstPostSignonRecord": 4,
                "keepPostSignonRecords": 11,
                "eventRecord": 14,
                "eventType": 10,
                "coordShorts": [-2136, 17413, 9968],
                "pakEntry": "demo2.dem",
            },
        )

        c_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-lavasplash-c.json").read_text(encoding="utf-8")
        )
        asm_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-lavasplash-asm.json").read_text(encoding="utf-8")
        )
        self.assertEqual(c_profile["selectors"], {"LavaSplashImplementation": "c"})
        self.assertEqual(asm_profile["selectors"], {"LavaSplashImplementation": "asm"})
        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        self.assertRegex(
            timedemo_source,
            r"(?m)^\s*\[string\]\$LavaSplashImplementation\s*=\s*'c'",
        )
        for profile in (c_profile, asm_profile):
            for selector in profile["selectors"]:
                self.assertIn(selector, timedemo_source)
        validation_source = (ROOT / "tools/render-validation-dos.ps1").read_text(encoding="utf-8")
        parity_source = (ROOT / "tools/render-parity-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("must define a reference image unless golden comparison is deferred", validation_source)
        self.assertIn(
            '"reference": null',
            (ROOT / "tools/render-scenarios-lavasplash.json").read_text(encoding="utf-8"),
        )
        self.assertIn("$validationArgs += '-SkipGoldenImageComparison'", parity_source)

    def test_teleportsplash_scenario_is_pair_only_exact_and_uses_isolated_profiles(self) -> None:
        manifest_text = (ROOT / "tools/render-scenarios-teleportsplash.json").read_text(encoding="utf-8")
        manifest = json.loads(manifest_text)
        self.assertEqual(manifest["warmupChecksumFrames"], 4)
        self.assertEqual(len(manifest["scenarios"]), 1)
        scene = manifest["scenarios"][0]
        self.assertEqual(scene["id"], "demo2-teleportsplash-event")
        self.assertIn("TE_TELEPORT", scene["description"])
        self.assertEqual(scene["expectedFrames"], 10)
        self.assertEqual(scene["expectedChecksum"], 0)
        self.assertEqual(scene["captureFrame"], 10)
        self.assertEqual(scene["requiredBenchEvents"], ["teleportSplash"])
        self.assertEqual(scene["expectedBenchEventFrames"], {"teleportSplash": [10]})
        self.assertEqual(scene["captureBenchEvents"], ["teleportSplash"])
        self.assertIsNone(scene["reference"])
        self.assertEqual(scene["tolerance"], {"channel": 0, "maxChangedPixelFraction": 0, "maxMeanAbsoluteError": 0})
        self.assertEqual(
            scene["demoFixture"],
            {
                "sourceMember": "demo2.dem",
                "firstPostSignonRecord": 4,
                "keepPostSignonRecords": 11,
                "eventRecord": 14,
                "eventType": 11,
                "coordShorts": [-2136, 17413, 9968],
                "pakEntry": "demo2.dem",
            },
        )

        c_profile = json.loads((ROOT / "tools/renderer-profiles/i486-teleportsplash-c.json").read_text(encoding="utf-8"))
        asm_profile = json.loads((ROOT / "tools/renderer-profiles/i486-teleportsplash-asm.json").read_text(encoding="utf-8"))
        self.assertEqual(c_profile["selectors"], {"TeleportSplashImplementation": "c"})
        self.assertEqual(asm_profile["selectors"], {"TeleportSplashImplementation": "asm"})
        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        self.assertRegex(timedemo_source, r"(?m)^\s*\[string\]\$TeleportSplashImplementation\s*=\s*'c'")
        self.assertIn("Read-Bench486TeleportSplashEvents -Report $report", timedemo_source)
        self.assertIn("if ($eventType -notin @(4, 7, 10, 11, 19))", timedemo_source)
        self.assertIn("TE_TELEPORT (11)", timedemo_source)
        self.assertIn("TE_WIZSPIKE (7)", timedemo_source)
        self.assertIn("TeleportSplashImplementation", timedemo_source)
        validation_source = (ROOT / "tools/render-validation-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("$referencePath = $null", validation_source)
        parity_source = (ROOT / "tools/render-parity-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("must define a reference image unless golden comparison is deferred", validation_source)
        self.assertIn('"reference": null', manifest_text)
        self.assertIn("$validationArgs += '-SkipGoldenImageComparison'", parity_source)

    def test_run_particle_effect_scenario_is_pair_only_exact_and_uses_isolated_profiles(self) -> None:
        manifest_text = (ROOT / "tools/render-scenarios-runparticleeffect.json").read_text(encoding="utf-8")
        manifest = json.loads(manifest_text)
        self.assertEqual(manifest["warmupChecksumFrames"], 4)
        self.assertEqual(len(manifest["scenarios"]), 1)
        scene = manifest["scenarios"][0]
        self.assertEqual(scene["id"], "demo2-wizspike-event")
        self.assertIn("TE_WIZSPIKE", scene["description"])
        self.assertIn("R_RunParticleEffect", scene["description"])
        self.assertEqual(scene["expectedFrames"], 10)
        self.assertEqual(scene["expectedChecksum"], 0)
        self.assertEqual(scene["captureFrame"], 10)
        self.assertGreaterEqual(scene["repeatRuns"], 2)
        self.assertEqual(scene["requiredBenchEvents"], ["runParticleEffect"])
        self.assertEqual(scene["expectedBenchEventFrames"], {"runParticleEffect": [10]})
        self.assertEqual(scene["captureBenchEvents"], ["runParticleEffect"])
        self.assertIsNone(scene["reference"])
        self.assertEqual(scene["tolerance"], {"channel": 0, "maxChangedPixelFraction": 0, "maxMeanAbsoluteError": 0})
        self.assertEqual(
            scene["demoFixture"],
            {
                "sourceMember": "demo2.dem",
                "firstPostSignonRecord": 4,
                "keepPostSignonRecords": 11,
                "eventRecord": 14,
                "eventType": 7,
                "coordShorts": [-2136, 17413, 9968],
                "pakEntry": "demo2.dem",
            },
        )

        c_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-runparticleeffect-c.json").read_text(encoding="utf-8")
        )
        asm_profile = json.loads(
            (ROOT / "tools/renderer-profiles/i486-runparticleeffect-asm.json").read_text(encoding="utf-8")
        )
        self.assertEqual(c_profile["selectors"], {"RunParticleEffectImplementation": "c"})
        self.assertEqual(asm_profile["selectors"], {"RunParticleEffectImplementation": "asm"})
        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        self.assertRegex(timedemo_source, r"(?m)^\s*\[string\]\$RunParticleEffectImplementation\s*=\s*'c'")
        self.assertIn("Read-Bench486RunParticleEffectEvents -Report $report", timedemo_source)
        self.assertIn("if ($eventType -notin @(4, 7, 10, 11, 19))", timedemo_source)
        self.assertIn("TE_WIZSPIKE (7)", timedemo_source)
        for profile in (c_profile, asm_profile):
            for selector in profile["selectors"]:
                self.assertIn(selector, timedemo_source)
        validation_source = (ROOT / "tools/render-validation-dos.ps1").read_text(encoding="utf-8")
        parity_source = (ROOT / "tools/render-parity-dos.ps1").read_text(encoding="utf-8")
        self.assertLess(
            validation_source.index("required runParticleEffect event count/frame/overflow metadata is missing"),
            validation_source.index("if ($SkipGoldenImageComparison)"),
            "pair-only scenarios must enforce R_RunParticleEffect telemetry before deferring golden-image comparison",
        )
        self.assertIn('"reference": null', manifest_text)
        self.assertIn("$validationArgs += '-SkipGoldenImageComparison'", parity_source)

    def test_entity_particles_event_command_fits_the_dos_psp_tail(self) -> None:
        manifest = json.loads(
            (ROOT / "tools/render-scenarios-entityparticles.json").read_text(encoding="utf-8")
        )
        scene = manifest["scenarios"][0]
        self.assertEqual(scene["quakeExtraArgs"], "-benchentityparticlesframe 10")
        command_tail = (
            "-timedemoexit -framechecksums -framecapture 10 -nosound "
            f"-nocdaudio {scene['quakeExtraArgs']} +timedemo {scene['demo']}"
        )
        psp_tail = " " + command_tail
        self.assertEqual(len(psp_tail.encode("ascii")), 113, psp_tail)
        self.assertLessEqual(len(psp_tail.encode("ascii")), 126, psp_tail)

        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        common_source = (ROOT / "tools/common.ps1").read_text(encoding="utf-8")
        self.assertIn("Assert-DosPspCommandTail -CommandTail (' ' + $quakeCommandTail)", timedemo_source)
        self.assertIn("$dosPspCommandTailMaxBytes = 126", common_source)
        self.assertIn("cd \\quake", timedemo_source)

    def test_damage_parse_benchmark_is_explicit_and_assembly_only(self) -> None:
        source = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertRegex(source, r"(?m)^\s*\[string\]\$DamageParseImplementation\s*=\s*'c'")
        self.assertIn("[switch]$DamageParseOnly", source)
        self.assertIn("if ($DamageParseOnly -and $DamageParseImplementation -ne 'asm')", source)
        self.assertIn("-benchvparsedamage -benchexit", source)
        self.assertIn("damageParseOnly = [bool]$DamageParseOnly", source)

    def test_bonus_flash_is_covered_by_palette_assembly_and_exact_fixture(self) -> None:
        source = (ROOT / "src/view.c").read_text(encoding="utf-8")
        assembly = (ROOT / "src/v_paletteasm.s").read_text(encoding="utf-8")
        layout = (ROOT / "src/asm_palette.h").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_palette.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")

        self.assertIn("CSHIFT_BONUS==p_shift_bonus", source)
        self.assertIn("void V_BonusFlash_C (void)", source)
        self.assertIn("void V_BonusFlash_f (void)", source)
        self.assertIn("#define p_shift_bonus 2", layout)
        self.assertIn("#define p_shift_destcolor 0", layout)
        self.assertIn("C(V_BonusFlash_asm486):", assembly)
        for store in (
            "$215,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_destcolor",
            "$186,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_destcolor+4",
            "$69,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_destcolor+8",
            "$50,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_percent",
        ):
            with self.subTest(store=store):
                self.assertIn(store, assembly)
        self.assertIn("Bench486BonusFlashCases", fixture)
        self.assertIn("V_BonusFlash_C", fixture)
        self.assertIn("V_BonusFlash_asm486", fixture)
        self.assertIn("V_BonusFlash_f", fixture)
        self.assertIn("Bench486PaletteRead(state,i)", fixture)
        self.assertIn("Bench486PaletteWrite(state,i)", fixture)
        self.assertIn('COM_CheckParm ("-benchpalette")', host_commands)
        self.assertIn("[switch]$PaletteOnly", runner)
        self.assertIn("if ($PaletteOnly -and $PaletteImplementation -ne 'asm')", runner)
        self.assertIn("-benchpalette -benchexit", runner)
        self.assertIn("paletteOnly = [bool]$PaletteOnly", runner)

    def test_cshift_command_preserves_atoi_and_contents_shift_behavior(self) -> None:
        source = (ROOT / "src/view.c").read_text(encoding="utf-8")
        assembly = (ROOT / "src/v_paletteasm.s").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_palette.h").read_text(encoding="utf-8")

        self.assertIn("void V_cshift_f_C (void)", source)
        self.assertIn("void V_cshift_f_asm486 (void);", source)
        self.assertIn("void V_cshift_f (void);", source)
        self.assertIn("sizeof(int)==4", source)
        self.assertIn("C(V_cshift_f_asm486):", assembly)
        self.assertIn("C(V_cshift_f):", assembly)
        self.assertEqual(assembly.count("call    C(Cmd_Argv)"), 4)
        self.assertEqual(assembly.count("call    C(atoi)"), 4)
        for offset in ("p_shift_destcolor", "p_shift_destcolor+4",
                "p_shift_destcolor+8", "p_shift_percent"):
            with self.subTest(offset=offset):
                self.assertIn("C(cshift_empty)+" + offset, assembly)
        self.assertIn("Cmd_TokenizeString(command)", fixture)
        self.assertIn("Bench486CshiftCases", fixture)
        self.assertIn("V_SetContentsColor_C", fixture)
        self.assertIn("V_SetContentsColor_asm486", fixture)
        for case in (
            '"v_cshift 12 -3 255 96"',
            '"v_cshift +17junk -08 0x10 +40tail"',
            '"v_cshift 21"',
            '"v_cshift -2147483648 2147483647 -2147483647 2147483646"',
            '"v_cshift"',
        ):
            with self.subTest(case=case):
                self.assertIn(case, fixture)

    def test_v_init_assembly_preserves_registration_order_and_gamma_setup(self) -> None:
        source = (ROOT / "src/view.c").read_text(encoding="utf-8")
        assembly = (ROOT / "src/v_viewcontrolasm.s").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_vinit.h").read_text(encoding="utf-8")
        host = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")

        self.assertIn("void V_Init_View_C (void)", source)
        self.assertIn("V_INIT_BUILD_GAMMA BuildGammaTable_C", source)
        self.assertIn("V_Init_SetBenchHooks", source)
        self.assertIn("V_Init_ClearBenchHooks", source)
        self.assertRegex(assembly, r"(?m)^_V_Init_asm486:")
        body = re.search(
            r"(?m)^_V_Init_asm486:(?P<body>.*?^\s*ret\s*$)", assembly, re.DOTALL
        )
        self.assertIsNotNone(body)
        self.assertEqual(body.group("body").count("call V_INIT_ADD_COMMAND"), 3)
        self.assertEqual(body.group("body").count("call V_INIT_REGISTER_VARIABLE"), 26)
        self.assertRegex(
            body.group("body"),
            r"pushl \$0x3f800000\s+call _BuildGammaTable\s+addl \$4,%esp",
        )
        self.assertNotRegex(body.group("body"), r"(?i)\b(?:cmov\w*|mm\w*|[sv]se\w*|fisttp|fcomi\w*)\b")
        self.assertIn("BVINIT_PRE_GAMMA_CVAR_COUNT 25", fixture)
        self.assertIn("BVINIT_CVAR_COUNT 26", fixture)
        self.assertIn("Bench486VInitCases (void)", fixture)
        self.assertIn('#include "bench486_vinit.h"', host)
        self.assertGreaterEqual(host.count("Bench486VInitCases ();"), 2)

    def test_damage_parse_profiles_isolate_the_new_assembly_candidate(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = json.loads((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        c_profile = json.loads((profiles / "i486-vparsedamage-c.json").read_text(encoding="utf-8"))
        asm_profile = json.loads((profiles / "i486-vparsedamage-asm.json").read_text(encoding="utf-8"))
        self.assertEqual(c_profile["id"], "i486-vparsedamage-c")
        self.assertEqual(asm_profile["id"], "i486-vparsedamage-asm")
        self.assertEqual(c_profile["selectors"], {"DamageParseImplementation": "c"})
        self.assertEqual(asm_profile["selectors"], {"DamageParseImplementation": "asm"})
        self.assertEqual(reference["selectors"].get("DamageParseImplementation", "c"), "c")

        timedemo_source = (ROOT / "tools/timedemo-dos.ps1").read_text(encoding="utf-8")
        self.assertRegex(timedemo_source, r"(?m)^\s*\[string\]\$DamageParseImplementation\s*=\s*'c'")
        self.assertRegex(timedemo_source, r"(?m)^\s*DamageParseImplementation\s*=\s*\$DamageParseImplementation\s*$")
        self.assertIn("damageParseImplementation = $DamageParseImplementation", timedemo_source)

        scenario = json.loads((ROOT / "tools/render-scenarios-svcdamage.json").read_text(encoding="utf-8"))
        damage_scenario = scenario["scenarios"][0]
        self.assertEqual(damage_scenario["requiredBenchEvents"], ["svcDamage"])
        self.assertEqual(damage_scenario["expectedBenchEventFrames"], {"svcDamage": [10]})
        self.assertEqual(damage_scenario["captureBenchEvents"], ["svcDamage"])
        self.assertEqual(damage_scenario["reference"], None)
        self.assertEqual(scenario["defaultTolerance"], {
            "channel": 0,
            "maxChangedPixelFraction": 0,
            "maxMeanAbsoluteError": 0,
        })

    def test_assembly_selector_profile_uses_supported_i486_paths(self) -> None:
        profile_path = ROOT / "tools/renderer-profiles/i486-asm-selectable.json"
        profile = load_json(profile_path.read_text(encoding="utf-8"))
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
        reference_selectors = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )["selectors"]
        self.assertEqual(reference_selectors["MarkLightsImplementation"], "c")
        mark_lights_profile = load_json(
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
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = load_json(
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
        reference = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = load_json(
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
        reference = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = load_json(
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
        reference = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = load_json(
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
        reference = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        assembly_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-asm-selectable.json").read_text(encoding="utf-8")
        )
        reference_profile = load_json(
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

    def test_linegraph_profile_fixture_and_historical_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-line-graph.json").read_text(encoding="utf-8"))
        historical = json.loads(
            (profiles / "i486-asm-selectable-84.json").read_text(encoding="utf-8")
        )
        selectable85 = json.loads(
            (profiles / "i486-asm-selectable-85.json").read_text(encoding="utf-8")
        )

        self.assertEqual(len(reference["selectors"]), 87)
        self.assertEqual(focused["id"], "i486-asm-line-graph")
        self.assertEqual(focused["selectors"]["LineGraphImplementation"], "asm")
        expected_focused = dict(reference["selectors"])
        expected_focused["LineGraphImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertEqual(len(historical["selectors"]), 84)
        self.assertNotIn("LineGraphImplementation", historical["selectors"])
        expected85 = dict(historical["selectors"])
        expected85["LineGraphImplementation"] = "asm"
        self.assertEqual(len(selectable85["selectors"]), 85)
        self.assertEqual(selectable85["selectors"], expected85)

        fixture = (ROOT / "src/bench486_linegraph.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("#define LG_FIXTURE_VISIBLE_WIDTH 64", fixture)
        self.assertIn("#define LG_FIXTURE_ROWBYTES      72", fixture)
        self.assertIn("Bench486LineGraphBuildExpected", fixture)
        self.assertIn("Bench486LineGraphPaddingCanaries", fixture)
        self.assertIn("R_LineGraph_C (cases[i].x, cases[i].y, cases[i].height)", fixture)
        self.assertIn("R_LineGraph_asm486 (cases[i].x, cases[i].y, cases[i].height)", fixture)
        self.assertGreaterEqual(
            fixture.count("Q_memcpy (&bench486_linegraph_work, &bench486_linegraph_initial"), 2
        )
        for case in (
            "fractional-height-and-offsets",
            "height-clamped-to-fractional-limit",
            "zero-height-fills-background",
            "negative-fractional-graphheight",
            "last-visible-column-with-padding",
        ):
            self.assertIn(case, fixture)
        self.assertIn('Bench486Printf ("linegraph fixture begin', fixture)
        self.assertIn('#include "bench486_linegraph.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchlinegraph")', host_commands)
        self.assertIn("Bench486LineGraphCases ();", host_commands)
        self.assertIn("[switch]$LineGraphOnly", bench_runner)
        self.assertIn("$LineGraphOnly -and $LineGraphImplementation -ne 'asm'", bench_runner)
        self.assertIn("+bench486 -benchlinegraph -benchexit", bench_runner)
        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$LineGraphImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported LineGraph selectors",
            )
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$PaletteImplementation\s*=\s*'c'",
                f"{runner_name} must retain PaletteImplementation validation",
            )

    def test_alias_stats_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-alias-stats.json").read_text(encoding="utf-8"))
        historical84 = json.loads((profiles / "i486-asm-selectable-84.json").read_text(encoding="utf-8"))
        historical85 = json.loads((profiles / "i486-asm-selectable-85.json").read_text(encoding="utf-8"))
        selectable86 = json.loads((profiles / "i486-asm-selectable-86.json").read_text(encoding="utf-8"))

        self.assertEqual(len(reference["selectors"]), 87)
        self.assertEqual(focused["id"], "i486-asm-alias-stats")
        self.assertEqual(focused["selectors"]["AliasStatsImplementation"], "asm")
        expected_focused = dict(reference["selectors"])
        expected_focused["AliasStatsImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertNotIn("AliasStatsImplementation", historical84["selectors"])
        self.assertNotIn("AliasStatsImplementation", historical85["selectors"])
        self.assertEqual(len(historical84["selectors"]), 84)
        self.assertEqual(len(historical85["selectors"]), 85)
        self.assertEqual(historical85["selectors"]["LineGraphImplementation"], "asm")
        expected86 = dict(historical85)
        expected86["id"] = "i486-asm-selectable-86"
        expected86["description"] = selectable86["description"]
        expected86["selectors"] = dict(historical85["selectors"])
        expected86["selectors"]["AliasStatsImplementation"] = "asm"
        self.assertEqual(len(selectable86["selectors"]), 86)
        self.assertEqual(selectable86, expected86)

        assembly = (ROOT / "src/r_aliasstatsasm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_aliasstats.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("C(R_PrintAliasStats_asm486):", assembly)
        self.assertIn('asciz "%3i polygon model drawn\\n"', assembly)
        self.assertIn("pushl\tC(r_amodels_drawn)", assembly)
        self.assertIn("call\tC(Con_Printf)", assembly)
        self.assertIn("void R_PrintAliasStats_C (void)", oracle)
        self.assertIn("ASM486_ALIAS_STATS", selectors)
        self.assertIn("AS_FIXTURE_GUARD_BYTES", fixture)
        self.assertIn("Con_Printf (\"\\n\")", fixture)
        self.assertIn("Bench486AliasStatsBuildExpected", fixture)
        self.assertIn("R_PrintAliasStats_C", fixture)
        self.assertIn("R_PrintAliasStats_asm486", fixture)
        self.assertIn("result->buffer_pointer = con_text", fixture)
        self.assertIn("result_c.buffer_pointer ==", fixture)
        self.assertIn("aliasstats %s FAIL baseline/C/ASM/pair", fixture)
        self.assertIn('Bench486Printf ("aliasstats fixture begin', fixture)
        for case in (
            "negative-width-three",
            "negative-width-four",
            "signed-minimum",
            "signed-maximum",
        ):
            self.assertIn(case, fixture)
        self.assertIn("Bench486AliasStatsRestore (&saved);", fixture)
        self.assertIn("Bench486AliasStatsSave (&saved);", fixture)
        self.assertIn('#include "bench486_aliasstats.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchaliasstats")', host_commands)
        self.assertIn("Bench486AliasStatsCases ();", host_commands)
        self.assertIn("[switch]$AliasStatsOnly", bench_runner)
        self.assertIn("$AliasStatsOnly -and $AliasStatsImplementation -ne 'asm'", bench_runner)
        self.assertIn("+bench486 -benchaliasstats -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$AliasStatsImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported AliasStats selectors",
            )

    def test_print_times_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-print-times.json").read_text(encoding="utf-8"))
        selectable = json.loads((profiles / "i486-asm-selectable.json").read_text(encoding="utf-8"))
        selectable86 = json.loads((profiles / "i486-asm-selectable-86.json").read_text(encoding="utf-8"))
        selectable87 = json.loads((profiles / "i486-asm-selectable-87.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["selectors"]["PrintTimesImplementation"], "c")
        self.assertEqual(focused["id"], "i486-asm-print-times")
        expected_focused = dict(reference["selectors"])
        expected_focused["PrintTimesImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertNotIn("PrintTimesImplementation", selectable86["selectors"])
        self.assertEqual(len(selectable["selectors"]), 84)
        self.assertEqual(selectable["selectors"]["PrintTimesImplementation"], "asm")
        self.assertEqual(len(selectable87["selectors"]), 87)
        self.assertEqual(selectable87["id"], "i486-asm-selectable-87")
        expected87 = dict(selectable86)
        expected87["id"] = selectable87["id"]
        expected87["description"] = selectable87["description"]
        expected87["selectors"] = dict(selectable86["selectors"])
        expected87["selectors"]["PrintTimesImplementation"] = "asm"
        self.assertEqual(selectable87, expected87)

        assembly = (ROOT / "src/r_printtimesasm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_printtimes.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("C(R_PrintTimes_asm486):", assembly)
        self.assertIn("C(Bench486PrintTimesTime)", assembly)
        self.assertIn("C(Sys_FloatTime)", assembly)
        self.assertIn('asciz "%5.1f ms %3i/%3i/%3i poly %3i surf\\n"', assembly)
        self.assertIn("fstps\t-4(%ebp)", assembly)
        self.assertIn("fsubs\tC(r_time1)", assembly)
        self.assertIn("fmuls\t.Lprint_times_1000", assembly)
        self.assertIn("fstps\t-8(%ebp)", assembly)
        self.assertIn("fstpl\t(%esp)", assembly)
        self.assertIn("addl\t$28,%esp", assembly)
        self.assertIn("movl\t$0,C(c_surf)", assembly)
        arg_order = [
            assembly.index("pushl\tC(c_surf)"),
            assembly.index("pushl\tC(r_drawnpolycount)"),
            assembly.index("pushl\tC(r_polycount)"),
            assembly.index("pushl\tC(c_faceclip)"),
            assembly.index("fstpl\t(%esp)"),
            assembly.index("pushl\t$.Lprint_times_format"),
            assembly.index("call\tC(Con_Printf)"),
            assembly.index("movl\t$0,C(c_surf)"),
        ]
        self.assertEqual(arg_order, sorted(arg_order))
        self.assertIn("void R_PrintTimes_C (void)", oracle)
        self.assertIn("Bench486PrintTimesTime (void)", oracle)
        self.assertIn("ASM486_PRINT_TIMES", selectors)
        self.assertIn("PT_FIXTURE_CW      0x0c7f", fixture)
        self.assertIn("double-to-float-chop", fixture)
        self.assertIn("negative-zero-display", fixture)
        self.assertIn("repeat-ring-wrap", fixture)
        self.assertIn("Bench486PrintTimesFixedTimer", fixture)
        self.assertIn("timer_calls != cases[i].repeats", fixture)
        self.assertIn("fnstcw", fixture)
        self.assertIn("fnstsw", fixture)
        self.assertIn("abi_flags & 16", fixture)
        self.assertNotIn("movl %%esp,%0", fixture)
        self.assertIn("Con_Printf (\"\\n\")", fixture)
        self.assertIn('#include "bench486_printtimes.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchprinttimes")', host_commands)
        self.assertIn("Bench486PrintTimesCases ();", host_commands)
        self.assertIn("[switch]$PrintTimesOnly", bench_runner)
        self.assertIn("$PrintTimesOnly -and $PrintTimesImplementation -ne 'asm'", bench_runner)
        self.assertIn("+bench486 -benchprinttimes -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$PrintTimesImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported PrintTimes selectors",
            )

    def test_forward_span_fixture_has_c_oracle_guards_and_isolated_runner(self) -> None:
        assembly = (ROOT / "src/r_edgea.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_edge.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_forwardspans.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        ownership = (ROOT / "tools/renderer-ownership.py").read_text(encoding="utf-8")

        self.assertIn(".globl C(R_GenerateSpans_asm486)", assembly)
        self.assertIn("C(R_GenerateSpans_asm486):", assembly)
        self.assertIn("void R_LeadingEdge_C (edge_t *edge)", oracle)
        self.assertIn("void R_GenerateSpans_C (void)", oracle)
        self.assertIn("bmodel-legacy-constant-boundary", fixture)
        self.assertIn("bmodel-bottom-double-boundary", fixture)
        self.assertIn("bmodel-top-double-boundary", fixture)
        self.assertIn("bmodel-fu-fixed-point-boundary", fixture)
        self.assertIn("bmodel-slope-tiebreak-wins", fixture)
        self.assertIn("fractional-u-pixel-boundary", fixture)
        self.assertIn(".double\t0.99", assembly)
        self.assertIn(".double\t1.01", assembly)
        self.assertIn("fmull\tdouble_point_99", assembly)
        self.assertIn("fmull\tdouble_1_point_01", assembly)
        self.assertIn("the compiled C oracle keeps fu in extended x87 precision", assembly)
        self.assertNotIn("fstps\tLtemp", assembly)
        self.assertIn("BFS_GUARD_WORDS", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn('#include "bench486_forwardspans.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchforwardspans")', host_commands)
        self.assertIn("Bench486ForwardSpansCases ();", host_commands)
        self.assertIn("[switch]$ForwardSpansOnly", bench_runner)
        self.assertIn("+bench486 -benchforwardspans -benchexit", bench_runner)
        self.assertIn('"_R_GenerateSpans_asm486": "r_edgea.s"', ownership)

    def test_zspan_fixture_compares_assembly_to_retained_c_oracle(self) -> None:
        assembly = (ROOT / "src/d_draw.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/d_scan.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_zspans.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")

        self.assertIn("C(D_DrawZSpans):", assembly)
        self.assertIn("#if\t!id386 || defined(BENCH486)", oracle)
        self.assertIn("void D_DrawZSpans_C (espan_t *pspan)", oracle)
        self.assertIn("truncate-boundary", fixture)
        self.assertIn("vertical-gradient", fixture)
        self.assertIn("background-depth", fixture)
        self.assertIn("BZS_GUARD_WORDS", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn("Q_memcmp (&bench486_zspans_c_buffer", fixture)
        self.assertIn("orw\t$0x0c00,%ax", assembly)
        self.assertIn("LFPairDone:", assembly)
        self.assertIn("LFNegPairDone:", assembly)
        self.assertIn("LFNegativeDepthPair:", assembly)
        self.assertIn("LZeroStepNegativeStore:", assembly)
        self.assertIn('#include "bench486_zspans.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchzspans")', host_commands)
        self.assertIn("Bench486ZSpansCases ();", host_commands)
        self.assertIn("[switch]$ZSpansOnly", bench_runner)
        self.assertIn("+bench486 -benchzspans -benchexit", bench_runner)
        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1",
                "timedemo-dos.ps1", "selectors.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertNotIn("ZSpanNegativeUnroll", runner)

    def test_screen_update_and_assembly_are_in_renderer_ownership_closure(self) -> None:
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")

        self.assertTrue(renderer_ownership.renderer_source("screen.c", "_SCR_UpdateScreen"))
        self.assertTrue(renderer_ownership.renderer_source("screen_fovasm.s", "_CalcFov_asm486"))
        self.assertTrue(renderer_ownership.renderer_source("screen_notifyasm.s", "_SCR_DrawNotifyString"))
        self.assertTrue(renderer_ownership.is_c_function_clone(
            "_SCR_UpdateScreen.part.0", "screen.c", {"SCR_UpdateScreen"}))
        self.assertFalse(renderer_ownership.is_c_function_clone(
            "_SCR_UpdateScreen", "screen.c", {"SCR_UpdateScreen"}))
        self.assertFalse(renderer_ownership.is_c_function_clone(
            ".Lscreen_update_done", "screen.c", {"SCR_UpdateScreen"}))
        for root in renderer_ownership.DEFAULT_ROOTS:
            self.assertIn(f"'--root', '{root}'", bench_runner)

    def test_particle_explosion2_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-particle-explosion2.json").read_text(encoding="utf-8"))
        selectable = json.loads((profiles / "i486-asm-selectable.json").read_text(encoding="utf-8"))
        selectable87 = json.loads((profiles / "i486-asm-selectable-87.json").read_text(encoding="utf-8"))
        selectable88 = json.loads((profiles / "i486-asm-selectable-88.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["selectors"]["ParticleExplosion2Implementation"], "c")
        self.assertEqual(focused["id"], "i486-asm-particle-explosion2")
        expected_focused = dict(reference["selectors"])
        expected_focused["ParticleExplosion2Implementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertEqual(len(selectable["selectors"]), 84)
        self.assertEqual(selectable["selectors"]["ParticleExplosion2Implementation"], "asm")
        self.assertEqual(len(selectable87["selectors"]), 87)
        self.assertNotIn("ParticleExplosion2Implementation", selectable87["selectors"])
        self.assertEqual(selectable88["id"], "i486-asm-selectable-88")
        self.assertEqual(len(selectable88["selectors"]), 88)
        expected88 = dict(selectable87)
        expected88["id"] = selectable88["id"]
        expected88["description"] = selectable88["description"]
        expected88["selectors"] = dict(selectable87["selectors"])
        expected88["selectors"]["ParticleExplosion2Implementation"] = "asm"
        self.assertEqual(selectable88, expected88)

        assembly = (ROOT / "src/r_particleexplosion2asm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_part.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_particleexplosion2.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("idivl\t%ecx", assembly)
        self.assertIn("andl\t$31,%eax", assembly)
        self.assertIn("andl\t$511,%eax", assembly)
        self.assertIn("call\tC(rand)", assembly)
        self.assertIn("R_ParticleExplosion2_C", oracle)
        self.assertIn("ASM486_PARTICLE_EXPLOSION2", selectors)
        self.assertIn("one-extra", fixture)
        self.assertIn("almost-full", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn("particle-explosion2 %d/%d %s", fixture)
        self.assertIn('#include "bench486_particleexplosion2.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchparticleexplosion2")', host_commands)
        self.assertIn("Bench486ParticleExplosion2Cases ();", host_commands)
        self.assertIn("[switch]$ParticleExplosion2Only", bench_runner)
        self.assertIn("-ParticleExplosion2Only requires -ParticleExplosion2Implementation asm", bench_runner)
        self.assertIn("+bench486 -benchparticleexplosion2 -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$ParticleExplosion2Implementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported ParticleExplosion2 selectors",
            )

    def test_particle_explosion_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-particle-explosion.json").read_text(encoding="utf-8"))
        selectable = json.loads((profiles / "i486-asm-selectable.json").read_text(encoding="utf-8"))
        selectable88 = json.loads((profiles / "i486-asm-selectable-88.json").read_text(encoding="utf-8"))
        selectable89 = json.loads((profiles / "i486-asm-selectable-89.json").read_text(encoding="utf-8"))
        selectable90 = json.loads((profiles / "i486-asm-selectable-90.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["selectors"]["ParticleExplosionImplementation"], "c")
        expected_focused = dict(reference["selectors"])
        expected_focused["ParticleExplosionImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertEqual(len(selectable["selectors"]), 84)
        self.assertEqual(selectable["selectors"]["ParticleExplosionImplementation"], "asm")
        self.assertEqual(len(selectable88["selectors"]), 88)
        self.assertNotIn("ParticleExplosionImplementation", selectable88["selectors"])
        self.assertEqual(len(selectable89["selectors"]), 89)
        self.assertEqual(selectable89["selectors"]["ParticleExplosionImplementation"], "asm")
        self.assertNotIn("TransformPlaneImplementation", selectable89["selectors"])
        expected90 = dict(selectable89)
        expected90["id"] = selectable90["id"]
        expected90["description"] = selectable90["description"]
        expected90["selectors"] = dict(selectable89["selectors"])
        expected90["selectors"]["TransformPlaneImplementation"] = "asm"
        self.assertEqual(selectable90, expected90)
        self.assertEqual(len(selectable90["selectors"]), 90)

        assembly = (ROOT / "src/r_particleexplosionasm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_part.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_particleexplosion.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("idivl\t%ecx", assembly)
        self.assertIn("C(R_ParticleExplosion_asm486):", assembly)
        self.assertIn("C(rand)", assembly)
        self.assertIn("R_ParticleExplosion_C", oracle)
        self.assertIn("ASM486_PARTICLE_EXPLOSION", selectors)
        self.assertIn("INT_MIN", fixture)
        self.assertIn("one-extra-libc-rand", fixture)
        self.assertIn("seven rand calls per particle", assembly)
        self.assertIn('#include "bench486_particleexplosion.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchparticleexplosion")', host_commands)
        self.assertIn("Bench486ParticleExplosionCases ();", host_commands)
        self.assertIn("[switch]$ParticleExplosionOnly", bench_runner)
        self.assertIn("-ParticleExplosionOnly requires -ParticleExplosionImplementation asm", bench_runner)
        self.assertIn("+bench486 -benchparticleexplosion -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$ParticleExplosionImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported ParticleExplosion selectors",
            )

    def test_blob_explosion_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-blob-explosion.json").read_text(encoding="utf-8"))
        selectable91 = json.loads((profiles / "i486-asm-selectable-91.json").read_text(encoding="utf-8"))
        selectable92 = json.loads((profiles / "i486-asm-selectable-92.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["selectors"]["BlobExplosionImplementation"], "c")
        self.assertEqual(focused["id"], "i486-asm-blob-explosion")
        expected_focused = dict(reference["selectors"])
        expected_focused["BlobExplosionImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertEqual(focused["selectors"]["ParticleExplosionImplementation"], "c")

        self.assertEqual(len(selectable91["selectors"]), 91)
        self.assertNotIn("BlobExplosionImplementation", selectable91["selectors"])
        self.assertEqual(selectable92["id"], "i486-asm-selectable-92")
        self.assertEqual(len(selectable92["selectors"]), 92)
        expected92 = dict(selectable91)
        expected92["id"] = selectable92["id"]
        expected92["description"] = selectable92["description"]
        expected92["selectors"] = dict(selectable91["selectors"])
        expected92["selectors"]["BlobExplosionImplementation"] = "asm"
        self.assertEqual(selectable92, expected92)

        assembly = (ROOT / "src/r_blobexplosionasm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_part.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_blobexplosion.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("idivl\t%ecx", assembly)
        self.assertIn("R_BlobExplosion_asm486", assembly)
        self.assertIn("Bench486BlobExplosionRand", assembly)
        self.assertIn("R_BlobExplosion_C", oracle)
        self.assertIn("ASM486_BLOB_EXPLOSION", selectors)
        self.assertIn("emitted * 8", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn('#include "bench486_blobexplosion.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchblobexplosion")', host_commands)
        self.assertIn("Bench486BlobExplosionCases ();", host_commands)
        self.assertIn("[switch]$BlobExplosionOnly", bench_runner)
        self.assertIn("-BlobExplosionOnly requires -BlobExplosionImplementation asm", bench_runner)
        self.assertIn("+bench486 -benchblobexplosion -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$BlobExplosionImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported BlobExplosion selectors",
            )

    def test_transform_plane_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-transform-plane.json").read_text(encoding="utf-8"))
        selectable = json.loads((profiles / "i486-asm-selectable.json").read_text(encoding="utf-8"))
        selectable89 = json.loads((profiles / "i486-asm-selectable-89.json").read_text(encoding="utf-8"))
        selectable90 = json.loads((profiles / "i486-asm-selectable-90.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["selectors"]["TransformPlaneImplementation"], "c")
        expected_focused = dict(reference["selectors"])
        expected_focused["TransformPlaneImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertEqual(len(selectable["selectors"]), 84)
        self.assertEqual(selectable["selectors"]["TransformPlaneImplementation"], "asm")
        self.assertEqual(len(selectable89["selectors"]), 89)
        self.assertNotIn("TransformPlaneImplementation", selectable89["selectors"])
        self.assertEqual(len(selectable90["selectors"]), 90)
        self.assertEqual(selectable90["selectors"]["TransformPlaneImplementation"], "asm")

        assembly = (ROOT / "src/r_transformplaneasm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_transformplane.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("fstps\t-4(%ebp)", assembly)
        self.assertIn("fsubs\t-4(%ebp)", assembly)
        self.assertIn("call\tC(TransformVector)", assembly)
        self.assertIn("R_TransformPlane_C", oracle)
        self.assertIn("ASM486_TRANSFORM_PLANE", selectors)
        self.assertIn("precision-sensitive-cancel", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn('#include "bench486_transformplane.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchtransformplane")', host_commands)
        self.assertIn("Bench486TransformPlaneCases ();", host_commands)
        self.assertIn("[switch]$TransformPlaneOnly", bench_runner)
        self.assertIn("-TransformPlaneOnly requires -TransformPlaneImplementation asm", bench_runner)
        self.assertIn("+bench486 -benchtransformplane -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$TransformPlaneImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported TransformPlane selectors",
            )

    def test_rocket_trail_profile_fixture_and_selectable_count(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        focused = load_json((profiles / "i486-asm-rocket-trail.json").read_text(encoding="utf-8"))
        selectable90 = json.loads((profiles / "i486-asm-selectable-90.json").read_text(encoding="utf-8"))
        selectable91 = json.loads((profiles / "i486-asm-selectable-91.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["selectors"]["RocketTrailImplementation"], "c")
        self.assertEqual(focused["id"], "i486-asm-rocket-trail")
        expected_focused = dict(reference["selectors"])
        expected_focused["RocketTrailImplementation"] = "asm"
        self.assertEqual(focused["selectors"], expected_focused)
        self.assertEqual(len(selectable90["selectors"]), 90)
        self.assertNotIn("RocketTrailImplementation", selectable90["selectors"])
        self.assertEqual(selectable91["id"], "i486-asm-selectable-91")
        self.assertEqual(len(selectable91["selectors"]), 91)
        expected91 = dict(selectable90)
        expected91["id"] = selectable91["id"]
        expected91["description"] = selectable91["description"]
        expected91["selectors"] = dict(selectable90["selectors"])
        expected91["selectors"]["RocketTrailImplementation"] = "asm"
        self.assertEqual(selectable91, expected91)

        assembly = (ROOT / "src/r_rockettrailasm.s").read_text(encoding="utf-8")
        oracle = (ROOT / "src/r_part.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_rockettrail.h").read_text(encoding="utf-8")
        host_commands = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        bench_runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("idivl\t%ecx", assembly)
        self.assertIn("C(R_RocketTrail_asm486):", assembly)
        self.assertIn("Bench486RocketTrailRand", assembly)
        self.assertIn("R_RocketTrail_C", oracle)
        self.assertIn("ASM486_ROCKET_TRAIL", selectors)
        self.assertIn("RocketTrailImplementation", selectors)
        self.assertIn("libc-rand-continuation", fixture)
        self.assertIn("tracer-exhaustion", fixture)
        self.assertIn("bench486_rockettrail_c_tracercount", fixture)
        self.assertIn("bench486_rockettrail_asm_tracercount", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn('#include "bench486_rockettrail.h"', host_commands)
        self.assertIn('COM_CheckParm ("-benchrockettrail")', host_commands)
        self.assertIn("Bench486RocketTrailCases ();", host_commands)
        self.assertIn("requires -benchexit to isolate libc RNG state", host_commands)
        self.assertIn("[switch]$RocketTrailOnly", bench_runner)
        self.assertIn("-RocketTrailOnly requires -RocketTrailImplementation asm", bench_runner)
        self.assertIn("+bench486 -benchrockettrail -benchexit", bench_runner)

        for runner_name in ("build-dos.ps1", "bench-dos.ps1", "smoke-dos.ps1", "timedemo-dos.ps1"):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$RocketTrailImplementation\s*=\s*'c'",
                f"{runner_name} must reject unsupported RocketTrail selectors",
            )

    def test_sprite_scan_left_focused_profile_changes_only_that_selector(self) -> None:
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        reference_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-c-reference.json").read_text(encoding="utf-8")
        )
        candidate_profile = load_json(
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
        assembly_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-asm-selectable.json").read_text(encoding="utf-8")
        )
        screened_profile = load_json(
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
                "ParticleDrawImplementation",
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
                "PrintTimesImplementation",
            } else assembly_profile["selectors"][name]
            self.assertEqual(value, expected, name)

    def test_surface_alias_profile_keeps_world_edge_paths_on_reference(self) -> None:
        assembly_profile = load_json(
            (ROOT / "tools/renderer-profiles/i486-asm-selectable.json").read_text(encoding="utf-8")
        )
        screened_profile = load_json(
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
            "ParticleDrawImplementation",
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
            "PrintTimesImplementation",
        }
        for name, value in screened_profile["selectors"].items():
            expected = "c" if name in reference_paths else assembly_profile["selectors"][name]
            self.assertEqual(value, expected, name)

    def test_world_and_edge_screen_profiles_change_only_their_group(self) -> None:
        base_profile = load_json(
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
            profile = load_json(
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
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = load_json((profiles / "i486-asm-zsubmodel.json").read_text(encoding="utf-8"))
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

        combined = load_json((profiles / "i486-asm-selectable-84.json").read_text(encoding="utf-8"))
        self.assertEqual(combined["selectors"]["PublicBindingsImplementation"], "asm")
        self.assertEqual(combined["selectors"]["ZSubmodelPolygonsImplementation"], "asm")
        binding = (ROOT / "src/r_publicbindingsasm.s").read_text(encoding="utf-8")
        public_fixture = (ROOT / "src/bench486_publicbindings.h").read_text(encoding="utf-8")
        self.assertRegex(
            binding,
            r"(?s)#ifdef ASM486_DRAW_Z_SUBMODEL_POLYS\s+\.p2align 2\s+\.globl _R_ZDrawSubmodelPolys\s+"
            r"_R_ZDrawSubmodelPolys:\s+jmp _R_ZDrawSubmodelPolys_asm486\s+#endif",
        )
        self.assertIn("{ (void (*)(void))R_ZDrawSubmodelPolys, (void (*)(void))R_ZDrawSubmodelPolys_asm486 }", public_fixture)
        self.assertIn("#if !defined(ASM486_PUBLIC_BINDINGS)", oracle)

    def test_render_poly_has_direct_raw_bit_c_assembly_oracle(self) -> None:
        fixture = (ROOT / "src/bench486_renderpoly.h").read_text(encoding="utf-8")
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        reference = (ROOT / "src/r_draw.c").read_text(encoding="utf-8")
        draw_driver = (ROOT / "src/d_edge.c").read_text(encoding="utf-8")
        public_fixture = (ROOT / "src/bench486_publicbindings.h").read_text(encoding="utf-8")

        self.assertIn("#define RPP_EXPECTED_PAIRS 168", fixture)
        self.assertIn("static const unsigned short control_words[12]", fixture)
        self.assertIn("Bench486RenderPolyFloatBits", fixture)
        self.assertIn("RPP_DIFFER (\"C/ASM.x87_status_except_C1\"", fixture)
        self.assertIn("c->x87_status & ~0x0200U", fixture)
        self.assertIn("a->x87_status & ~0x0200U", fixture)
        self.assertIn("c1_differences++", fixture)
        self.assertIn("0x0041U", fixture)
        self.assertIn('RPP_DIFFER ("C.x87_invalid_or_stack_fault_expected_clear"', fixture)
        self.assertIn('RPP_DIFFER ("ASM.x87_invalid_or_stack_fault_expected_clear"', fixture)
        self.assertNotIn("x87_status_with_exception_flags", fixture)
        self.assertIn("render-poly x87 C1 differences=%u first geometry=%u axis=%u plane=%u CW=%04x C-FSW=%04x ASM-FSW=%04x", fixture)
        diagnostic_formats = re.findall(r'Bench486Printf \("([^"\n]*render-poly[^"\n]*)"', fixture)
        self.assertTrue(diagnostic_formats)
        for format_string in diagnostic_formats:
            expanded = re.sub(r"%08x", "ffffffff", format_string)
            expanded = re.sub(r"%04x", "ffff", expanded)
            expanded = expanded.replace("%x", "ffffffff")
            # The fixture's counters are bounded by 168 pairs, signed values
            # are indices/axis values, and field labels are under 64 bytes.
            expanded = expanded.replace("%u", "168")
            expanded = expanded.replace("%d", "-32768")
            expanded = expanded.replace("%s", "x" * 64 if "first=%s[" in format_string else "FAIL")
            self.assertLess(len(expanded), 192, format_string)
        self.assertIn("extern medge_t *r_pedge", fixture)
        self.assertIn("saved->current_edge = r_pedge", fixture)
        self.assertIn("r_pedge = saved->current_edge", fixture)
        self.assertIn('RPP_DIFFER ("C/ASM.global.r_pedge"', fixture)
        self.assertIn("R_RenderPoly_C", reference)
        self.assertIn("lzi = 1.0 / transformed[2];", reference)
        self.assertIn("fdivrs\t.Lrpx_reciprocal_numerator", assembly)
        self.assertIn(".Lrpx_near_clip_reciprocal:", assembly)
        self.assertIn(".long 0x42c80000", assembly)
        self.assertIn("defined(BENCH486) && defined(ASM486_PUBLIC_BINDINGS)", draw_driver)
        self.assertIn("bench486_renderpoly_draw_hook ();", draw_driver)
        self.assertIn('#include "bench486_renderpoly.h"', public_fixture)
        self.assertIn("Bench486RenderPolyCases();", public_fixture)

    def test_frustum_transform_assembly_has_an_isolated_profile_and_guarded_oracle(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = load_json((profiles / "i486-asm-frustum-transform.json").read_text(encoding="utf-8"))
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
        index_routine = re.search(
            r"C\(R_SetUpFrustumIndexes\):(?P<body>.*?^\s*ret\s*$)",
            assembly,
            re.DOTALL | re.MULTILINE,
        )
        self.assertIsNotNone(index_routine)
        index_body = index_routine.group("body")
        self.assertIn("fldz", index_body)
        self.assertIn("fcomps\tFR_CLIP_NORMAL_X(%esi,%ebx,4)", index_body)
        self.assertIn("jp\t.Lfr_index_nonnegative", index_body)
        self.assertIn("ja\t.Lfr_index_negative", index_body)
        self.assertNotIn("ftst", index_body)
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
            "sizeof(r_frustum_indexes) / sizeof(r_frustum_indexes[0]) == FR_INDEX_PLANES * FR_INDEX_AXES * 2",
        ):
            with self.subTest(contract=contract):
                self.assertIn(contract, layout)

        oracle = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_frustum.h").read_text(encoding="utf-8")
        bench = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("R_TransformFrustumCore_C", oracle)
        self.assertIn("R_SetUpFrustumIndexes_C", oracle)
        self.assertIn("R_SetUpFrustumIndexes_C", fixture)
        self.assertIn("frustum index sequence progress", fixture)
        self.assertIn("4096 continuous calls", fixture)
        self.assertIn("frustum sequence progress", fixture)
        self.assertIn("-benchfrustumtransform", bench)

    def test_viewcontrol_setupframe_assembly_has_a_focused_profile_and_c_oracle(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-viewcontrol-c.json").read_text(encoding="utf-8"))
        candidate = load_json((profiles / "i486-viewcontrol-asm.json").read_text(encoding="utf-8"))
        self.assertEqual(candidate["schemaVersion"], 1)
        self.assertEqual(candidate["selectors"], {"ViewControlImplementation": "asm"})
        self.assertEqual(reference["selectors"], {"ViewControlImplementation": "c"})

        dispatch = (ROOT / "src/v_viewcontrolasm.s").read_text(encoding="utf-8")
        assembly = (ROOT / "src/r_setupframe_asm.inc").read_text(encoding="utf-8")
        c_source = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        layout = (ROOT / "src/asm_viewcontrol.h").read_text(encoding="utf-8")
        self.assertIn('#include "r_setupframe_asm.inc"', dispatch)
        self.assertIn(".globl _R_SetupFrame", assembly)
        self.assertIn("_R_SetupFrame:", assembly)
        for call in (
            "call _R_CheckVariables",
            "call _R_AnimateLight",
            "call _AngleVectors",
            "call _Mod_PointInLeaf",
            "call _R_ViewChanged",
            "call _R_TransformFrustum",
            "call _R_SetSkyFrame",
            "call _R_SetUpFrustumIndexes",
            "call _D_SetupFrame",
        ):
            with self.subTest(call=call):
                self.assertIn(call, assembly)
        self.assertIn("void R_SetupFrame_View_C (void)", c_source)
        self.assertIn("VC_REFDEF_AMBIENTLIGHT 144", layout)
        self.assertIn("offsetof(viddef_t,maxwarpwidth)==VC_VID_MAXWARPWIDTH", layout)
        self.assertIn("sizeof(edge_t)==VC_EDGE_SIZE", layout)
        self.assertNotRegex(assembly, r"(?i)\b(?:cmov\w*|mm\w*|[sv]se\w*|fisttp|fcomi\w*)\b")

    def test_calc_fov_assembly_matches_the_c_oracle_under_x87_modes(self) -> None:
        assembly = (ROOT / "src/screen_fovasm.s").read_text(encoding="utf-8")
        source = (ROOT / "src/screen.c").read_text(encoding="utf-8")
        layout = (ROOT / "src/asm_screenfov.h").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_viewcontrol.h").read_text(encoding="utf-8")

        self.assertIn(".arch i486", assembly)
        self.assertIn(".arch .387", assembly)
        self.assertIn("C(CalcFov_asm486):", assembly)
        for instruction in ("fcoms", "fnstsw", "fptan", "fpatan", "fdivrs"):
            with self.subTest(instruction=instruction):
                self.assertIn(instruction, assembly)
        self.assertNotRegex(assembly, r"(?i)\b(?:cmov\w*|mm\w*|[sv]se\w*|fisttp|fcomi\w*)\b")
        self.assertIn("#define SCREEN_CALC_FOV_C CalcFov_C", source)
        self.assertIn("CalcFov_asm486 (r_refdef.fov_x", source)
        self.assertIn("Bench486CalcFovSysError", layout)
        self.assertIn("CalcFov C/ASM exact result, error, x87-mode and ABI", fixture)
        self.assertIn("12 x87 control words", fixture)
        self.assertIn("Bench486CalcFovCases();", fixture)

    def test_console_input_selector_has_a_focused_reference_and_assembly_profile(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-consoleinput-c.json").read_text(encoding="utf-8"))
        candidate = load_json((profiles / "i486-consoleinput-asm.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["id"], "i486-consoleinput-c")
        self.assertEqual(candidate["id"], "i486-consoleinput-asm")
        self.assertEqual(set(candidate["selectors"]), set(reference["selectors"]))
        self.assertEqual(reference["selectors"]["ConsoleImplementation"], "c")
        self.assertEqual(candidate["selectors"]["ConsoleImplementation"], "asm")
        changed = {
            name for name, value in candidate["selectors"].items()
            if reference["selectors"][name] != value
        }
        self.assertEqual(changed, {"ConsoleImplementation"})

        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        self.assertIn("ASM486_CONSOLE_INPUT", selectors)
        for runner_name in (
            "build-dos.ps1",
            "bench-dos.ps1",
            "timedemo-dos.ps1",
            "smoke-dos.ps1",
            "coverage-dos.ps1",
        ):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$ConsoleImplementation\s*=\s*'c'",
                f"{runner_name} must expose ConsoleImplementation with a C default",
            )

    def test_screen_notify_selector_has_a_focused_reference_and_assembly_profile(self) -> None:
        profiles = ROOT / "tools/renderer-profiles"
        reference = load_json((profiles / "i486-screennotify-c.json").read_text(encoding="utf-8"))
        candidate = load_json((profiles / "i486-screennotify-asm.json").read_text(encoding="utf-8"))

        self.assertEqual(reference["id"], "i486-screennotify-c")
        self.assertEqual(candidate["id"], "i486-screennotify-asm")
        self.assertEqual(set(candidate["selectors"]), set(reference["selectors"]))
        self.assertEqual(reference["selectors"]["ScreenNotifyImplementation"], "c")
        self.assertEqual(candidate["selectors"]["ScreenNotifyImplementation"], "asm")
        self.assertEqual(
            {name for name, value in candidate["selectors"].items()
             if reference["selectors"][name] != value},
            {"ScreenNotifyImplementation"},
        )

        selectors = (ROOT / "tools/selectors.ps1").read_text(encoding="utf-8")
        assembly = (ROOT / "src/screen_notifyasm.s").read_text(encoding="utf-8")
        self.assertIn("ASM486_SCREEN_NOTIFY", selectors)
        self.assertIn(".arch i486", assembly)
        self.assertNotRegex(assembly, r"(?i)\b(?:cmov\w*|mm\w*|[sv]se\w*|fisttp|fcomi\w*)\b")
        for runner_name in (
            "build-dos.ps1",
            "bench-dos.ps1",
            "timedemo-dos.ps1",
            "smoke-dos.ps1",
            "coverage-dos.ps1",
        ):
            runner = (ROOT / "tools" / runner_name).read_text(encoding="utf-8")
            self.assertRegex(
                runner,
                r"(?s)\[ValidateSet\('c', 'asm'\)\]\s*"
                r"\[string\]\$ScreenNotifyImplementation\s*=\s*'c'",
                f"{runner_name} must expose ScreenNotifyImplementation with a C default",
            )

    def test_screen_notify_fixture_pins_x87_layout_and_line_consumption(self) -> None:
        assembly = (ROOT / "src/screen_notifyasm.s").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_screennotify.h").read_text(encoding="utf-8")
        source = (ROOT / "src/screen.c").read_text(encoding="utf-8")
        runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")

        for instruction in (
            "fildl   C(vid)+sn_vid_height_offset",
            "orw     $0x0300,%ax",
            "fmull   .Lscreen_notify_point_35",
            "faddl   .Lscreen_notify_two_32",
            "fistpl  -20(%ebp)",
            "fldcw   -14(%ebp)",
            "movsbl  (%ebx,%esi),%eax",
            "cmpl    $40,%esi",
            "subl    %eax,%edi",
            "shrl    $1,%edi",
        ):
            with self.subTest(instruction=instruction):
                self.assertIn(instruction, assembly)
        self.assertIn("SCR_DrawNotifyString_Screen_C", source)
        self.assertIn("while (*start && *start != '\\n')", source)
        self.assertIn("SCR_DrawNotifyString_Screen_C", fixture)
        self.assertIn("SCR_DrawNotifyString_asm486", fixture)
        self.assertIn("SCR_DrawNotifyString,", fixture)
        self.assertIn("(unsigned)x > BSN_ROW_BYTES - 8U", fixture)
        self.assertIn("(unsigned)y > BSN_FRAME_ROWS - 8U", fixture)
        self.assertIn("precision_bits[3]", fixture)
        self.assertIn("precision_count = ((test_case->width | test_case->height) & 0x80000000U) ? 3 : 1", fixture)
        self.assertIn("control_word_before", fixture)
        self.assertIn("control_word_after", fixture)
        self.assertIn("control_word_probe_changed", fixture)
        self.assertIn("abi & 0x20U", fixture)
        for case in (
            '"line-39"', '"line-40"', '"line-41"',
            '"narrow-even-40"', '"narrow-odd-40"',
            '"high-bit-width-40"', '"large-width-40"',
            '"high-bit-height"', '"max-height"',
            '"overlong-suffix"', '"leading-newline"',
            '"consecutive-newlines"', '"trailing-newline"',
            '"signed-high-bytes"',
        ):
            with self.subTest(case=case):
                self.assertIn(case, fixture)
        self.assertIn("rounding_names[4]", fixture)
        self.assertIn("-ScreenNotifyOnly requires -ScreenNotifyImplementation asm.", runner)
        self.assertIn("-benchscreenotify", runner)

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
        reference = load_json((profiles / "i486-c-reference.json").read_text(encoding="utf-8"))
        candidate = load_json((profiles / "i486-asm-sprite-setup.json").read_text(encoding="utf-8"))
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

    def test_r_check_variables_assembly_preserves_the_compiled_reference_behavior(self) -> None:
        assembly = (ROOT / "src/r_checkvariables_asm.inc").read_text(encoding="utf-8")
        module = (ROOT / "src/v_viewcontrolasm.s").read_text(encoding="utf-8")
        reference = (ROOT / "src/r_misc.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_viewcontrol.h").read_text(encoding="utf-8")

        self.assertIn('#include "r_checkvariables_asm.inc"', module)
        self.assertRegex(assembly, r"(?m)^_R_CheckVariables:")
        self.assertIn("fcoms\tRCHECK_OLDBRIGHT", assembly)
        self.assertIn("fnstsw\t%ax", assembly)
        self.assertIn("testb\t$0x40,%ah", assembly)
        self.assertIn("fstps\tRCHECK_OLDBRIGHT", assembly)
        self.assertIn("jmp\t_D_FlushCaches", assembly)
        self.assertIn("void R_CheckVariables_View_C (void)", reference)
        self.assertIn("void R_CheckVariables (void)", reference)
        self.assertIn("Bench486RCheckVariablesCases();", fixture)
        self.assertIn("R_CheckVariables C/ASM compare", fixture)
        self.assertIn("R_CheckVariables_View_C,0,NULL,NULL", fixture)
        self.assertIn("R_CheckVariables,0,NULL,NULL", fixture)

    def test_efrag_store_has_exact_c_asm_state_fixture_and_isolated_runner(self) -> None:
        source = (ROOT / "src/r_efrag.c").read_text(encoding="utf-8")
        fixture = (ROOT / "src/bench486_efragstore.h").read_text(encoding="utf-8")
        host = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        traceability = (ROOT / "docs/ledger/2026-10-10-efrag-store-parity-fixture.md").read_text(
            encoding="utf-8"
        )

        self.assertIn("R_STORE_EFRAGS_C_ENTRY R_StoreEfrags_C", source)
        self.assertIn("void R_StoreEfrags_asm486 (efrag_t **ppefrag);", source)
        self.assertIn("void R_StoreEfrags_C (efrag_t **ppefrag)", fixture)
        self.assertIn("R_StoreEfrags_asm486", fixture)
        self.assertIn("Bench486Call_asm486", fixture)
        self.assertIn("Q_memcpy (result->visible, cl_visedicts", fixture)
        self.assertIn("MAX_VISEDICTS - 1", fixture)
        self.assertIn('"mixed-types-duplicates-visible"', fixture)
        self.assertIn('"one-slot-left"', fixture)
        self.assertIn('"full-capacity"', fixture)
        self.assertIn("bench486_efragstore_c_result", fixture)
        self.assertIn("bench486_efragstore_asm_result", fixture)
        self.assertIn('#include "bench486_efragstore.h"', host)
        self.assertIn('COM_CheckParm ("-benchefragstore")', host)
        self.assertGreaterEqual(host.count("Bench486EfragStoreCases ();"), 2)
        self.assertIn("[switch]$EfragStoreOnly", runner)
        self.assertIn("$EfragStoreOnly -and $EfragStoreImplementation -ne 'asm'", runner)
        self.assertIn("+bench486 -benchefragstore -benchexit", runner)
        self.assertIn("efragStoreOnly = [bool]$EfragStoreOnly", runner)
        self.assertIn("R_StoreEfrags_C", traceability)
        self.assertIn(
            "-EfragStoreOnly -EfragStoreImplementation asm -MathClosureImplementation asm",
            traceability,
        )

    def test_particle_update_has_multiframe_exact_c_asm_fixture_and_runner(self) -> None:
        fixture = (ROOT / "src/bench486_particleupdate.h").read_text(encoding="utf-8")
        host = (ROOT / "src/host_cmd.c").read_text(encoding="utf-8")
        runner = (ROOT / "tools/bench-dos.ps1").read_text(encoding="utf-8")
        assembly = (ROOT / "src/asm486_experiments.s").read_text(encoding="utf-8")
        traceability = (ROOT / "docs/ledger/2026-10-10-particle-update-parity-fixture.md").read_text(
            encoding="utf-8"
        )

        self.assertIn("R_DrawParticles_C", fixture)
        self.assertIn("R_DrawParticles_asm486", fixture)
        self.assertIn("BPU_FRAME_COUNT 10", fixture)
        self.assertIn("BPU_MODE_COUNT 4", fixture)
        self.assertIn("pt_slowgrav", fixture)
        self.assertIn("Bench486ParticleDrawPrepareBuffers", fixture)
        self.assertIn("Bench486ParticleUpdateCompareAssembly", fixture)
        self.assertIn("particle-update depthbuffer mismatch", fixture)
        self.assertIn("particle-update list/projection/CW mismatch", fixture)
        for start, end in (
            (".Lparticle_explode_velocity:", ".Lparticle_explode2:"),
            (".Lparticle_explode2_velocity:", ".Lparticle_blob:"),
            (".Lparticle_blob:", ".Lparticle_blob2:"),
        ):
            with self.subTest(block=start):
                block = assembly[assembly.index(start):assembly.index(end, assembly.index(start))]
                self.assertLess(block.index("fmuls\tpt_vel+8(%ebx)"),
                                block.index("fsubs\t-36(%ebp)"))
                self.assertLess(block.index("fsubs\t-36(%ebp)"),
                                block.index("fstps\tpt_vel+8(%ebx)"))
        self.assertIn('#include "bench486_particleupdate.h"', host)
        self.assertIn('COM_CheckParm ("-benchparticleupdate")', host)
        self.assertIn("[switch]$ParticleUpdateOnly", runner)
        self.assertIn("$ParticleUpdateOnly -and $ParticleUpdateImplementation -ne 'asm'", runner)
        self.assertIn("-benchparticleupdate -benchexit", runner)
        self.assertIn("particleUpdateOnly = [bool]$ParticleUpdateOnly", runner)
        self.assertIn("R_DrawParticles_C", traceability)
        self.assertIn("R_DrawParticles_asm486", traceability)
        self.assertIn("40 frames across four x87 rounding modes", traceability)
        self.assertIn("-ParticleUpdateImplementation asm -ParticleDrawImplementation asm -ParticleUpdateOnly", traceability)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RenderingComparisonTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
