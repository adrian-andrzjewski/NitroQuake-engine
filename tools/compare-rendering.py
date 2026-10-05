"""Compare Quake's indexed PCX captures with tolerant RGB image metrics.

The renderer writes raw 8-bit PCX frames. This tool uses only the Python standard
library so the validation path works on a clean Windows build host without PIL.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class PcxImage:
    width: int
    height: int
    pixels: bytes
    palette: bytes

    def rgb(self) -> bytes:
        lookup = bytes(self.palette)
        result = bytearray(self.width * self.height * 3)
        for offset, index in enumerate(self.pixels):
            palette_offset = index * 3
            target = offset * 3
            result[target : target + 3] = lookup[palette_offset : palette_offset + 3]
        return bytes(result)


def load_pcx(path: Path) -> PcxImage:
    data = path.read_bytes()
    if len(data) < 128 + 769:
        raise ValueError(f"{path}: PCX file is truncated")
    if data[0] != 0x0A or data[2] != 1 or data[3] != 8 or data[65] != 1:
        raise ValueError(f"{path}: expected 8-bit, single-plane PCX with RLE encoding")

    xmin, ymin, xmax, ymax = struct.unpack_from("<HHHH", data, 4)
    width = xmax - xmin + 1
    height = ymax - ymin + 1
    bytes_per_line = struct.unpack_from("<H", data, 66)[0]
    if width <= 0 or height <= 0 or bytes_per_line < width:
        raise ValueError(f"{path}: invalid PCX dimensions or scanline pitch")

    palette_start = len(data) - 769
    if data[palette_start] != 0x0C:
        raise ValueError(f"{path}: missing 256-color PCX palette marker")
    palette = data[palette_start + 1 :]
    if len(palette) != 768:
        raise ValueError(f"{path}: incomplete PCX palette")

    decoded_bytes = height * bytes_per_line
    decoded = bytearray()
    cursor = 128
    while len(decoded) < decoded_bytes:
        if cursor >= palette_start:
            raise ValueError(f"{path}: PCX image data ended before the final scanline")
        value = data[cursor]
        cursor += 1
        if value & 0xC0 == 0xC0:
            count = value & 0x3F
            if count == 0 or cursor >= palette_start:
                raise ValueError(f"{path}: invalid PCX RLE packet")
            value = data[cursor]
            cursor += 1
            decoded.extend(bytes((value,)) * count)
        else:
            decoded.append(value)
        if len(decoded) > decoded_bytes:
            raise ValueError(f"{path}: PCX RLE data overruns its declared image size")

    pixels = bytearray(width * height)
    for y in range(height):
        source = y * bytes_per_line
        target = y * width
        pixels[target : target + width] = decoded[source : source + width]
    return PcxImage(width, height, bytes(pixels), palette)


def _png_chunk(tag: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + tag
        + payload
        + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
    )


def write_diff_png(path: Path, expected: PcxImage, actual: PcxImage, channel_tolerance: int) -> None:
    if (expected.width, expected.height) != (actual.width, actual.height):
        return
    expected_rgb = expected.rgb()
    actual_rgb = actual.rgb()
    rows = bytearray()
    for y in range(expected.height):
        rows.append(0)  # PNG filter type 0
        for x in range(expected.width):
            pixel = y * expected.width + x
            offset = pixel * 3
            deltas = [abs(expected_rgb[offset + c] - actual_rgb[offset + c]) for c in range(3)]
            if max(deltas) <= channel_tolerance:
                gray = (expected_rgb[offset] * 30 + expected_rgb[offset + 1] * 59 + expected_rgb[offset + 2] * 11) // 100
                rows.extend((gray, gray, gray))
            else:
                strength = max(80, min(255, max(deltas) * 2))
                rows.extend((strength, 0, 255 - strength // 2))

    ihdr = struct.pack(">IIBBBBB", expected.width, expected.height, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + _png_chunk(b"IHDR", ihdr)
    png += _png_chunk(b"IDAT", zlib.compress(bytes(rows), 9))
    png += _png_chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def compare_images(
    expected_path: Path,
    actual_path: Path,
    *,
    channel_tolerance: int = 2,
    max_changed_pixel_fraction: float = 0.0005,
    max_mean_absolute_error: float = 0.5,
) -> dict[str, Any]:
    expected = load_pcx(expected_path)
    actual = load_pcx(actual_path)
    dimensions_match = (expected.width, expected.height) == (actual.width, actual.height)
    if not dimensions_match:
        return {
            "pass": False,
            "expected": {"path": str(expected_path), "width": expected.width, "height": expected.height},
            "actual": {"path": str(actual_path), "width": actual.width, "height": actual.height},
            "metrics": {"dimensionsMatch": False},
            "tolerance": {
                "channel": channel_tolerance,
                "maxChangedPixelFraction": max_changed_pixel_fraction,
                "maxMeanAbsoluteError": max_mean_absolute_error,
            },
        }

    expected_rgb = expected.rgb()
    actual_rgb = actual.rgb()
    channel_differences = [abs(a - b) for a, b in zip(expected_rgb, actual_rgb)]
    pixel_count = expected.width * expected.height
    changed_pixels = sum(
        1
        for pixel in range(pixel_count)
        if max(channel_differences[pixel * 3 : pixel * 3 + 3]) > channel_tolerance
    )
    mean_error = sum(channel_differences) / len(channel_differences) if channel_differences else 0.0
    changed_fraction = changed_pixels / pixel_count if pixel_count else 0.0
    max_error = max(channel_differences, default=0)
    passed = (
        changed_fraction <= max_changed_pixel_fraction
        and mean_error <= max_mean_absolute_error
    )
    return {
        "pass": passed,
        "expected": {"path": str(expected_path), "width": expected.width, "height": expected.height},
        "actual": {"path": str(actual_path), "width": actual.width, "height": actual.height},
        "metrics": {
            "dimensionsMatch": True,
            "pixels": pixel_count,
            "changedPixels": changed_pixels,
            "changedPixelFraction": changed_fraction,
            "meanAbsoluteChannelError": mean_error,
            "maxAbsoluteChannelError": max_error,
            "paletteMatches": expected.palette == actual.palette,
        },
        "tolerance": {
            "channel": channel_tolerance,
            "maxChangedPixelFraction": max_changed_pixel_fraction,
            "maxMeanAbsoluteError": max_mean_absolute_error,
        },
    }


def read_frame_checksums(path: Path) -> dict[str, Any]:
    checksums: list[int] = []
    overflow: int | None = None
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), start=1):
        summary = line.split()
        if len(summary) == 4 and summary[0] == "frames" and summary[2] == "overflow":
            try:
                declared_frames, overflow = int(summary[1]), int(summary[3])
            except ValueError as exc:
                raise ValueError(f"{path}:{line_number}: malformed frame summary") from exc
            continue
        if len(summary) != 2:
            raise ValueError(f"{path}:{line_number}: malformed checksum record")
        try:
            frame_index, checksum = int(summary[0]), int(summary[1])
        except ValueError as exc:
            raise ValueError(f"{path}:{line_number}: malformed checksum record") from exc
        if frame_index != len(checksums):
            raise ValueError(f"{path}:{line_number}: expected frame {len(checksums)}, got {frame_index}")
        checksums.append(checksum)

    if overflow is None:
        raise ValueError(f"{path}: missing frame count/overflow completion summary")
    if declared_frames != len(checksums):
        raise ValueError(f"{path}: summary says {declared_frames} frames, found {len(checksums)}")
    if overflow != 0:
        raise ValueError(f"{path}: checksum capture overflowed by {overflow} frames")
    return {"frames": checksums, "count": len(checksums), "overflow": overflow}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("expected", type=Path)
    parser.add_argument("actual", type=Path)
    parser.add_argument("--scenario", default="render")
    parser.add_argument("--channel-tolerance", type=int, default=2)
    parser.add_argument("--max-changed-pixel-fraction", type=float, default=0.0005)
    parser.add_argument("--max-mean-absolute-error", type=float, default=0.5)
    parser.add_argument("--report-json", type=Path)
    parser.add_argument("--diff-image", type=Path)
    args = parser.parse_args(argv)
    if args.channel_tolerance < 0 or not 0 <= args.max_changed_pixel_fraction <= 1:
        parser.error("tolerances must be nonnegative and the pixel fraction must be in [0, 1]")
    if args.max_mean_absolute_error < 0 or math.isnan(args.max_mean_absolute_error):
        parser.error("--max-mean-absolute-error must be nonnegative")

    try:
        report = compare_images(
            args.expected,
            args.actual,
            channel_tolerance=args.channel_tolerance,
            max_changed_pixel_fraction=args.max_changed_pixel_fraction,
            max_mean_absolute_error=args.max_mean_absolute_error,
        )
        report["scenario"] = args.scenario
        diff_path = args.diff_image or args.actual.with_name(args.actual.stem + "-diff.png")
        write_diff_png(diff_path, load_pcx(args.expected), load_pcx(args.actual), args.channel_tolerance)
        report["diffImage"] = str(diff_path)
    except (OSError, ValueError) as exc:
        report = {
            "scenario": args.scenario,
            "pass": False,
            "error": str(exc),
            "expected": {"path": str(args.expected)},
            "actual": {"path": str(args.actual)},
        }

    serialized = json.dumps(report, indent=2, sort_keys=True)
    if args.report_json:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        args.report_json.write_text(serialized + "\n", encoding="utf-8")
    print(serialized)
    return 0 if report.get("pass") else 1


if __name__ == "__main__":
    raise SystemExit(main())
