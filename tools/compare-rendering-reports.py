"""Compare deterministic render-validation reports from two selector profiles.

Per-run checksum streams are compared after the manifest's configured warmup
frames. Captured PCX framebuffers are compared at raw palette-index and palette
byte level, so this parity gate is exact even when two palette indices happen to
render to the same RGB color.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path
from typing import Any


RENDERING_TOOL = Path(__file__).with_name("compare-rendering.py")
SPEC = importlib.util.spec_from_file_location("compare_rendering", RENDERING_TOOL)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load renderer comparison helpers from {RENDERING_TOOL}")
rendering = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = rendering
SPEC.loader.exec_module(rendering)


def _load_report(path: Path) -> dict[str, Any]:
    try:
        report = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read render-validation report {path}: {exc}") from exc
    if not isinstance(report, dict) or report.get("schemaVersion") != 1:
        raise ValueError(f"{path}: expected render-validation report schemaVersion 1")
    scenarios = report.get("scenarios")
    if not isinstance(scenarios, list):
        raise ValueError(f"{path}: scenarios must be an array")
    return report


def _scenario_map(report: dict[str, Any], path: Path) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for entry in report["scenarios"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("scenario"), str):
            raise ValueError(f"{path}: each scenario needs a string scenario id")
        scenario_id = entry["scenario"]
        if scenario_id in result:
            raise ValueError(f"{path}: duplicate scenario id {scenario_id!r}")
        result[scenario_id] = entry
    return result


def _artifact_path(report_path: Path, value: Any, label: str) -> Path:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{report_path}: missing {label} path")
    path = Path(value)
    if not path.is_absolute():
        path = report_path.parent / path
    return path


def _compare_streams(reference_path: Path, candidate_path: Path, ignored_frames: int) -> dict[str, Any]:
    reference = rendering.read_frame_checksums(reference_path)
    candidate = rendering.read_frame_checksums(candidate_path)
    common_count = min(reference["count"], candidate["count"])
    start = min(ignored_frames, common_count)
    mismatches = [
        frame
        for frame in range(start, common_count)
        if reference["frames"][frame] != candidate["frames"][frame]
    ]
    exact = reference["count"] == candidate["count"] and not mismatches
    return {
        "exactMatch": exact,
        "reference": str(reference_path),
        "candidate": str(candidate_path),
        "referenceFrames": reference["count"],
        "candidateFrames": candidate["count"],
        "comparedFrames": common_count - start,
        "ignoredLeadingFrames": start,
        "mismatchedFrames": len(mismatches),
        "mismatchFrameIndices": mismatches,
        "firstMismatchFrame": mismatches[0] if mismatches else None,
        "lastMismatchFrame": mismatches[-1] if mismatches else None,
    }


def _compare_exact_framebuffers(
    reference_path: Path, candidate_path: Path, diff_path: Path | None
) -> dict[str, Any]:
    reference = rendering.load_pcx(reference_path)
    candidate = rendering.load_pcx(candidate_path)
    dimensions_match = (reference.width, reference.height) == (candidate.width, candidate.height)
    if not dimensions_match:
        return {
            "exactMatch": False,
            "reference": {"path": str(reference_path), "width": reference.width, "height": reference.height},
            "candidate": {"path": str(candidate_path), "width": candidate.width, "height": candidate.height},
            "metrics": {"dimensionsMatch": False},
        }

    changed_indices = [
        index for index, (left, right) in enumerate(zip(reference.pixels, candidate.pixels)) if left != right
    ]
    changed_palette_bytes = [
        index for index, (left, right) in enumerate(zip(reference.palette, candidate.palette)) if left != right
    ]
    if diff_path is not None:
        rendering.write_diff_png(diff_path, reference, candidate, channel_tolerance=0)
    indices_exact = not changed_indices
    palette_exact = not changed_palette_bytes
    return {
        "exactMatch": indices_exact and palette_exact,
        "reference": {"path": str(reference_path), "width": reference.width, "height": reference.height},
        "candidate": {"path": str(candidate_path), "width": candidate.width, "height": candidate.height},
        "metrics": {
            "dimensionsMatch": True,
            "pixelCount": len(reference.pixels),
            "pixelIndexMismatches": len(changed_indices),
            "firstPixelIndexMismatch": changed_indices[0] if changed_indices else None,
            "lastPixelIndexMismatch": changed_indices[-1] if changed_indices else None,
            "paletteMatches": palette_exact,
            "paletteByteMismatches": len(changed_palette_bytes),
            "firstPaletteByteMismatch": changed_palette_bytes[0] if changed_palette_bytes else None,
        },
        "diffImage": str(diff_path) if diff_path is not None else None,
    }


def _runs_by_id(entry: dict[str, Any], report_path: Path, scenario_id: str) -> dict[int, dict[str, Any]]:
    diagnostics = entry.get("frameDiagnostics")
    if not isinstance(diagnostics, list):
        raise ValueError(f"{report_path}: {scenario_id} frameDiagnostics must be an array")
    runs: dict[int, dict[str, Any]] = {}
    for item in diagnostics:
        if not isinstance(item, dict):
            raise ValueError(f"{report_path}: {scenario_id} has a malformed frame diagnostic")
        try:
            run_id = int(item["run"])
        except (KeyError, TypeError, ValueError) as exc:
            raise ValueError(f"{report_path}: {scenario_id} has a diagnostic without a run number") from exc
        if run_id in runs:
            raise ValueError(f"{report_path}: {scenario_id} repeats run {run_id}")
        runs[run_id] = item
    return runs


def _safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def compare_reports(
    reference_report_path: Path,
    candidate_report_path: Path,
    *,
    diff_dir: Path | None = None,
    allow_unpinned_sources: bool = False,
) -> dict[str, Any]:
    reference_report = _load_report(reference_report_path)
    candidate_report = _load_report(candidate_report_path)
    reference_scenarios = _scenario_map(reference_report, reference_report_path)
    candidate_scenarios = _scenario_map(candidate_report, candidate_report_path)

    reference_tree = reference_report.get("sourceTreeFingerprint")
    candidate_tree = candidate_report.get("sourceTreeFingerprint")
    if reference_tree and candidate_tree:
        source_status = "match" if reference_tree == candidate_tree else "mismatch"
    else:
        source_status = "unrecorded"

    scenario_ids = sorted(set(reference_scenarios) | set(candidate_scenarios))
    scenario_results: list[dict[str, Any]] = []
    for scenario_id in scenario_ids:
        reference_entry = reference_scenarios.get(scenario_id)
        candidate_entry = candidate_scenarios.get(scenario_id)
        if reference_entry is None or candidate_entry is None:
            scenario_results.append({
                "scenario": scenario_id,
                "pass": False,
                "error": "scenario is missing from one report",
                "missingFrom": "reference" if reference_entry is None else "candidate",
            })
            continue

        ignored_reference = int(reference_entry.get("ignoredWarmupChecksumFrames", -1))
        ignored_candidate = int(candidate_entry.get("ignoredWarmupChecksumFrames", -1))
        reference_runs = _runs_by_id(reference_entry, reference_report_path, scenario_id)
        candidate_runs = _runs_by_id(candidate_entry, candidate_report_path, scenario_id)
        reference_images = reference_entry.get("imageComparisons")
        candidate_images = candidate_entry.get("imageComparisons")
        if not isinstance(reference_images, list) or not isinstance(candidate_images, list):
            raise ValueError(f"{scenario_id}: imageComparisons must be arrays in both reports")

        run_ids = sorted(set(reference_runs) | set(candidate_runs))
        run_results: list[dict[str, Any]] = []
        reference_run_order = list(reference_runs)
        candidate_run_order = list(candidate_runs)
        for run_id in run_ids:
            left = reference_runs.get(run_id)
            right = candidate_runs.get(run_id)
            if left is None or right is None:
                run_results.append({"run": run_id, "pass": False, "error": "run is missing from one report"})
                continue

            run_result: dict[str, Any] = {"run": run_id}
            if ignored_reference != ignored_candidate or ignored_reference < 0:
                run_result["checksumError"] = "reports use different or invalid warmup frame counts"
            else:
                try:
                    left_checksum = _artifact_path(reference_report_path, left.get("frameChecksumPath"), "frame checksum")
                    right_checksum = _artifact_path(candidate_report_path, right.get("frameChecksumPath"), "frame checksum")
                    run_result["frameChecksums"] = _compare_streams(left_checksum, right_checksum, ignored_reference)
                except (OSError, ValueError) as exc:
                    run_result["checksumError"] = str(exc)

            reference_image_index = reference_run_order.index(run_id)
            candidate_image_index = candidate_run_order.index(run_id)
            if reference_image_index >= len(reference_images) or candidate_image_index >= len(candidate_images):
                run_result["imageError"] = "captured image is missing for this run"
            else:
                try:
                    left_image = _artifact_path(reference_report_path, reference_images[reference_image_index].get("actual", {}).get("path"), "captured image")
                    right_image = _artifact_path(candidate_report_path, candidate_images[candidate_image_index].get("actual", {}).get("path"), "captured image")
                    image_diff = None
                    if diff_dir is not None:
                        image_diff = diff_dir / f"{_safe_name(scenario_id)}-run-{run_id:02d}.png"
                    run_result["framebuffer"] = _compare_exact_framebuffers(left_image, right_image, image_diff)
                except (OSError, ValueError) as exc:
                    run_result["imageError"] = str(exc)

            run_result["pass"] = (
                run_result.get("frameChecksums", {}).get("exactMatch", False)
                and run_result.get("framebuffer", {}).get("exactMatch", False)
                and "checksumError" not in run_result
                and "imageError" not in run_result
            )
            run_results.append(run_result)

        if len(reference_images) != len(reference_runs) or len(candidate_images) != len(candidate_runs):
            image_shape_ok = False
        else:
            image_shape_ok = True
        scenario_results.append({
            "scenario": scenario_id,
            "pass": image_shape_ok and bool(run_results) and all(item.get("pass", False) for item in run_results),
            "referenceResult": reference_entry.get("result"),
            "candidateResult": candidate_entry.get("result"),
            "ignoredWarmupChecksumFrames": ignored_reference,
            "referenceCaptureFrame": reference_entry.get("captureFrame"),
            "candidateCaptureFrame": candidate_entry.get("captureFrame"),
            "imageRunCountsMatch": image_shape_ok,
            "runs": run_results,
        })

    source_compatible = source_status == "match" or (source_status == "unrecorded" and allow_unpinned_sources)
    same_target = reference_report.get("cpuTarget") == candidate_report.get("cpuTarget")
    suite_pass = reference_report.get("result") == "PASS" and candidate_report.get("result") == "PASS"
    passed = (
        source_compatible
        and source_status != "mismatch"
        and same_target
        and suite_pass
        and bool(scenario_results)
        and all(item.get("pass", False) for item in scenario_results)
    )
    return {
        "schemaVersion": 1,
        "comparison": "exact-render-profile-parity",
        "pass": passed,
        "sourceTreeFingerprintStatus": source_status,
        "reference": {
            "report": str(reference_report_path),
            "profile": reference_report.get("rendererSelectorProfile"),
            "sourceTreeFingerprint": reference_tree,
            "sourceFingerprint": reference_report["scenarios"][0].get("sourceFingerprint") if reference_report["scenarios"] else None,
            "result": reference_report.get("result"),
            "cpuTarget": reference_report.get("cpuTarget"),
        },
        "candidate": {
            "report": str(candidate_report_path),
            "profile": candidate_report.get("rendererSelectorProfile"),
            "sourceTreeFingerprint": candidate_tree,
            "sourceFingerprint": candidate_report["scenarios"][0].get("sourceFingerprint") if candidate_report["scenarios"] else None,
            "result": candidate_report.get("result"),
            "cpuTarget": candidate_report.get("cpuTarget"),
        },
        "sourceCompatible": source_compatible,
        "cpuTargetMatches": same_target,
        "bothInputSuitesPassed": suite_pass,
        "allowUnpinnedSources": allow_unpinned_sources,
        "scenarios": scenario_results,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path, help="C/reference render-validation-result.json")
    parser.add_argument("candidate", type=Path, help="assembly/candidate render-validation-result.json")
    parser.add_argument("--output-json", type=Path, help="write the machine-readable comparison report")
    parser.add_argument("--diff-dir", type=Path, help="write exact-comparison diagnostic PNGs here")
    parser.add_argument(
        "--allow-unpinned-sources",
        action="store_true",
        help="permit old reports that lack sourceTreeFingerprint; use for diagnostics only",
    )
    args = parser.parse_args(argv)

    try:
        report = compare_reports(
            args.reference,
            args.candidate,
            diff_dir=args.diff_dir,
            allow_unpinned_sources=args.allow_unpinned_sources,
        )
    except (OSError, ValueError) as exc:
        parser.error(str(exc))

    serialized = json.dumps(report, indent=2, sort_keys=True)
    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(serialized + "\n", encoding="utf-8")
    print(serialized)
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
