"""Build or verify the Windows host helper for DJGPP startup-source proofs.

The helper assembles original 16-bit startup sources on the Windows host. Its
output is compared byte-for-byte with startup code embedded in the DOS target;
the helper itself never runs on the 486 target.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import struct
import subprocess


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def pinned_file(bundle, files, name):
    record = files.get(name)
    path = bundle / name
    if record is None or not path.is_file():
        raise ValueError(f"Pinned host-helper input is missing from the bundle: {name}")
    if path.stat().st_size != record["bytes"] or sha(path) != record["sha256"]:
        raise ValueError(f"Changed pinned host-helper input: {name}")
    return path


def load_bundle(bundle):
    index = json.loads((bundle / "manifest.json").read_text(encoding="utf-8"))
    if index.get("schemaVersion") != 1:
        raise ValueError("Unsupported runtime source bundle manifest.")
    return index, {item["path"]: item for item in index["files"]}


def host_compiler(explicit=None):
    """Never confuse a DJGPP target compiler with the Windows verification host."""
    candidates = (
        [explicit]
        if explicit
        else [
            Path(item) / "gcc.exe"
            for item in os.environ.get("PATH", "").split(os.pathsep)
            if item
        ]
    )
    if not explicit and os.environ.get("LOCALAPPDATA"):
        packages = Path(os.environ["LOCALAPPDATA"]) / "Microsoft/WinGet/Packages"
        candidates += sorted(packages.glob("*/mingw64/bin/gcc.exe"))

    seen = set()
    for candidate in candidates:
        path = Path(candidate).resolve()
        if path in seen or not path.is_file():
            continue
        seen.add(path)
        probe = subprocess.run([str(path), "-dumpmachine"], capture_output=True, text=True)
        target = probe.stdout.strip().lower()
        if probe.returncode == 0 and ("mingw" in target or "windows" in target):
            return path
        if explicit:
            raise ValueError(
                f"The requested host compiler targets {target!r}, rather than Windows."
            )
    raise ValueError(
        "A Windows host GCC is required; use --host-compiler to identify a MinGW compiler."
    )


def require_host_executable(path):
    blob = path.read_bytes()
    if len(blob) < 64 or blob[:2] != b"MZ":
        raise ValueError("The DJASM verification helper is not a Windows executable.")
    header = struct.unpack_from("<I", blob, 60)[0]
    if header + 6 > len(blob) or blob[header : header + 4] != b"PE\0\0":
        raise ValueError("The DJASM verification helper is not PE; a DOS target was selected.")
    machine = struct.unpack_from("<H", blob, header + 4)[0]
    if machine not in (0x14C, 0x8664):
        raise ValueError(f"Unsupported Windows DJASM host machine: {machine:#x}")


def primary_sources(bundle, files):
    source = pinned_file(bundle, files, "primary/djgpp-host/src/djasm.c")
    header = pinned_file(bundle, files, "primary/djgpp-host/include/coff.h")
    return source, header


def host_environment(compiler):
    environment = dict(os.environ)
    for name in (
        "DJDIR",
        "DJGPP",
        "GCC_EXEC_PREFIX",
        "COMPILER_PATH",
        "LIBRARY_PATH",
        "CPATH",
        "C_INCLUDE_PATH",
        "CPLUS_INCLUDE_PATH",
    ):
        environment.pop(name, None)
    environment["PATH"] = str(compiler.parent) + os.pathsep + environment.get("PATH", "")
    return environment


def build(bundle, compiler, output):
    compiler = host_compiler(compiler)
    index, files = load_bundle(bundle)
    source, header = primary_sources(bundle, files)
    output.mkdir(parents=True, exist_ok=True)
    source_target = output / "src/djasm.c"
    header_target = output / "include/coff.h"
    source_target.parent.mkdir(parents=True, exist_ok=True)
    header_target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, source_target)
    shutil.copyfile(header, header_target)

    executable = output / "djasm-host.exe"
    process = subprocess.run(
        [str(compiler), "-O2", "-std=gnu89", "-I", str(header_target.parent), str(source_target), "-o", str(executable)],
        capture_output=True,
        text=True,
        env=host_environment(compiler),
    )
    (output / "compilation.txt").write_text(process.stdout + process.stderr, encoding="utf-8")
    if process.returncode:
        raise ValueError(f"Primary DJASM host build failed: {process.stderr}")
    require_host_executable(executable)
    report = {
        "passed": True,
        "hostToolOnly": True,
        "method": "rebuilt-from-pinned-DJGPP-source",
        "sourceSha256": sha(source_target),
        "headerSha256": sha(header_target),
        "hostCompiler": str(compiler.resolve()),
        "hostCompilerSha256": sha(compiler),
        "executable": str(executable.resolve()),
        "executableSha256": sha(executable),
        "runtimeBundleManifestSha256": sha(bundle / "manifest.json"),
    }
    (output / "provenance.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, default=Path(__file__).with_name("isa-runtime-reference"))
    parser.add_argument("--host-compiler", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = build(args.bundle, args.host_compiler, args.output)
    print(f"Primary DJASM host proof tool PASS ({report['method']}): {report['executable']}")


if __name__ == "__main__":
    main()
