"""Host tests for exact C-reference versus assembly render report comparisons."""

from __future__ import annotations

import importlib.util
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def load_tool(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


comparison = load_tool("compare_rendering_reports", ROOT / "tools/compare-rendering-reports.py")


def write_pcx(path: Path, pixels: bytes, palette: bytes) -> None:
    width = len(pixels)
    height = 1
    header = bytearray(128)
    header[0:4] = bytes((0x0A, 5, 1, 8))
    struct.pack_into("<HHHH", header, 4, 0, 0, width - 1, 0)
    header[65] = 1
    header[66:68] = width.to_bytes(2, "little")
    encoded = bytearray()
    for value in pixels:
        if value >= 0xC0:
            encoded.extend((0xC1, value))
        else:
            encoded.append(value)
    path.write_bytes(bytes(header) + bytes(encoded) + b"\x0c" + palette)


class RenderReportComparisonTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="quake-render-reports-")
        self.root = Path(self.temp.name)
        self.palette = bytearray(768)
        self.palette[3:6] = bytes((70, 80, 90))
        # Duplicate colors prove the parity check compares framebuffer indices,
        # not only the RGB image they happen to produce.
        self.palette[6:9] = bytes((70, 80, 90))

    def tearDown(self) -> None:
        self.temp.cleanup()

    def make_report(self, profile: str, *, source_tree: str | None = "same-tree") -> Path:
        profile_dir = self.root / profile
        profile_dir.mkdir()
        checksum_path = profile_dir / "framechecksums.txt"
        checksum_path.write_text("0 100\n1 200\n2 300\nframes 3 overflow 0\n", encoding="ascii")
        capture_path = profile_dir / "frame.pcx"
        write_pcx(capture_path, bytes((1, 2, 3, 4)), bytes(self.palette))
        report = {
            "schemaVersion": 1,
            "result": "PASS",
            "cpuTarget": "i486",
            "rendererSelectorProfile": profile,
            "sourceTreeFingerprint": source_tree,
            "scenarios": [
                {
                    "scenario": "unit-scene",
                    "result": "PASS",
                    "captureFrame": 2,
                    "ignoredWarmupChecksumFrames": 1,
                    "sourceFingerprint": f"profile-specific-{profile}",
                    "frameDiagnostics": [
                        {"run": 1, "frameChecksumPath": str(checksum_path)}
                    ],
                    "imageComparisons": [
                        {"actual": {"path": str(capture_path)}}
                    ],
                }
            ],
        }
        report_path = profile_dir / "render-validation-result.json"
        report_path.write_text(json.dumps(report), encoding="utf-8")
        return report_path

    def test_compares_streams_and_raw_framebuffer_exactly_across_profiles(self) -> None:
        reference = self.make_report("c-reference")
        candidate = self.make_report("assembly")
        result = comparison.compare_reports(reference, candidate)
        self.assertTrue(result["pass"], json.dumps(result, indent=2))
        self.assertEqual(result["sourceTreeFingerprintStatus"], "match")
        self.assertFalse(
            result["reference"]["sourceFingerprint"] == result["candidate"]["sourceFingerprint"]
        )
        run = result["scenarios"][0]["runs"][0]
        self.assertTrue(run["frameChecksums"]["exactMatch"])
        self.assertEqual(run["frameChecksums"]["comparedFrames"], 2)
        self.assertTrue(run["framebuffer"]["exactMatch"])

    def test_detects_palette_index_difference_even_when_rgb_is_identical(self) -> None:
        reference = self.make_report("c-reference")
        candidate = self.make_report("assembly")
        candidate_report = json.loads(candidate.read_text(encoding="utf-8"))
        capture = Path(candidate_report["scenarios"][0]["imageComparisons"][0]["actual"]["path"])
        write_pcx(capture, bytes((1, 2, 2, 4)), bytes(self.palette))

        result = comparison.compare_reports(reference, candidate)
        self.assertFalse(result["pass"])
        framebuffer = result["scenarios"][0]["runs"][0]["framebuffer"]
        self.assertFalse(framebuffer["exactMatch"])
        self.assertEqual(framebuffer["metrics"]["pixelIndexMismatches"], 1)

    def test_compares_entity_particles_event_and_exact_checksum_stream_length(self) -> None:
        reference = self.make_report("c-reference")
        candidate = self.make_report("assembly")
        for report_path in (reference, candidate):
            report = json.loads(report_path.read_text(encoding="utf-8"))
            scenario = report["scenarios"][0]
            scenario["expectedChecksumStreamFrames"] = 3
            scenario["requiredBenchEvents"] = ["entityParticles"]
            scenario["expectedBenchEventFrames"] = {"entityParticles": [2]}
            scenario["frameDiagnostics"][0].update(
                {
                    "entityParticlesEventCount": 1,
                    "entityParticlesEventFrames": [2],
                    "entityParticlesEventOverflow": 0,
                }
            )
            report_path.write_text(json.dumps(report), encoding="utf-8")

        result = comparison.compare_reports(reference, candidate)
        self.assertTrue(result["pass"], json.dumps(result, indent=2))
        run = result["scenarios"][0]["runs"][0]
        self.assertTrue(run["benchEvents"]["entityParticles"]["pass"])
        self.assertTrue(run["expectedChecksumStreamFrames"]["pass"])

        candidate_report = json.loads(candidate.read_text(encoding="utf-8"))
        candidate_report["scenarios"][0]["frameDiagnostics"][0]["entityParticlesEventFrames"] = [1]
        candidate_report["scenarios"][0]["expectedChecksumStreamFrames"] = 4
        candidate.write_text(json.dumps(candidate_report), encoding="utf-8")
        result = comparison.compare_reports(reference, candidate)
        self.assertFalse(result["pass"])
        run = result["scenarios"][0]["runs"][0]
        self.assertFalse(run["benchEvents"]["entityParticles"]["pass"])
        self.assertFalse(run["expectedChecksumStreamFrames"]["pass"])

    def test_compares_svc_damage_dispatch_frame(self) -> None:
        reference = self.make_report("c-reference")
        candidate = self.make_report("assembly")
        for report_path in (reference, candidate):
            report = json.loads(report_path.read_text(encoding="utf-8"))
            scenario = report["scenarios"][0]
            scenario["expectedChecksumStreamFrames"] = 3
            scenario["requiredBenchEvents"] = ["svcDamage"]
            scenario["expectedBenchEventFrames"] = {"svcDamage": [2]}
            scenario["frameDiagnostics"][0].update(
                {
                    "svcDamageEventCount": 1,
                    "svcDamageEventFrames": [2],
                    "svcDamageEventOverflow": 0,
                }
            )
            report_path.write_text(json.dumps(report), encoding="utf-8")

        result = comparison.compare_reports(reference, candidate)
        self.assertTrue(result["pass"], json.dumps(result, indent=2))
        self.assertTrue(
            result["scenarios"][0]["runs"][0]["benchEvents"]["svcDamage"]["pass"]
        )

        candidate_report = json.loads(candidate.read_text(encoding="utf-8"))
        candidate_report["scenarios"][0]["frameDiagnostics"][0]["svcDamageEventFrames"] = [1]
        candidate.write_text(json.dumps(candidate_report), encoding="utf-8")
        result = comparison.compare_reports(reference, candidate)
        self.assertFalse(result["pass"])
        self.assertFalse(result["scenarios"][0]["runs"][0]["benchEvents"]["svcDamage"]["pass"])

    def test_unpinned_source_reports_require_explicit_diagnostic_override(self) -> None:
        reference = self.make_report("c-reference", source_tree=None)
        candidate = self.make_report("assembly", source_tree=None)
        strict = comparison.compare_reports(reference, candidate)
        diagnostic = comparison.compare_reports(reference, candidate, allow_unpinned_sources=True)
        self.assertFalse(strict["pass"])
        self.assertEqual(strict["sourceTreeFingerprintStatus"], "unrecorded")
        self.assertTrue(diagnostic["pass"], json.dumps(diagnostic, indent=2))

    def test_rejects_different_source_trees_and_cpu_targets(self) -> None:
        reference = self.make_report("c-reference", source_tree="source-A")
        candidate = self.make_report("assembly", source_tree="source-B")
        self.assertFalse(comparison.compare_reports(reference, candidate)["pass"])

        candidate_report = json.loads(candidate.read_text(encoding="utf-8"))
        candidate_report["sourceTreeFingerprint"] = "source-A"
        candidate_report["cpuTarget"] = "i386"
        candidate.write_text(json.dumps(candidate_report), encoding="utf-8")
        result = comparison.compare_reports(reference, candidate)
        self.assertFalse(result["pass"])
        self.assertFalse(result["cpuTargetMatches"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
