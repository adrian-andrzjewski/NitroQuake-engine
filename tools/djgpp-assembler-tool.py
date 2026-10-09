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
import zipfile


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


def primary_archives(bundle, files):
    archives = {}
    for name in ("djlsr205.zip", "djdev205.zip"):
        archives[name] = pinned_file(bundle, files, f"primary/{name}")
    return archives


def verify_prebuilt_host(bundle, files):
    executable = pinned_file(bundle, files, "prebuilt/djasm-host.exe")
    provenance_path = pinned_file(bundle, files, "prebuilt/djasm-host-provenance.json")
    provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
    if provenance.get("schemaVersion") != 1:
        raise ValueError("Unsupported prebuilt DJASM provenance schema.")

    archives = primary_archives(bundle, files)
    for name, path in archives.items():
        if sha(path) != provenance["archiveSha256"].get(name):
            raise ValueError(f"Prebuilt DJASM provenance does not match {name}.")

    with zipfile.ZipFile(archives["djlsr205.zip"]) as package:
        source = package.read("src/djasm/djasm.c")
    with zipfile.ZipFile(archives["djdev205.zip"]) as package:
        header = package.read("include/coff.h")
    if hashlib.sha256(source).hexdigest().upper() != provenance["sourceSha256"]:
        raise ValueError("Prebuilt DJASM source identity differs from the primary archive.")
    if hashlib.sha256(header).hexdigest().upper() != provenance["coffHeaderSha256"]:
        raise ValueError("Prebuilt DJASM header identity differs from the primary archive.")
    if sha(executable) != provenance["executableSha256"]:
        raise ValueError("Prebuilt DJASM executable hash does not match its provenance.")
    require_host_executable(executable)
    return executable, provenance


def build_prebuilt_host(bundle, output, reason):
    index, files = load_bundle(bundle)
    executable, provenance = verify_prebuilt_host(bundle, files)
    output.mkdir(parents=True, exist_ok=True)
    target = output / "djasm-host.exe"
    shutil.copyfile(executable, target)
    report = {
        "passed": True,
        "hostToolOnly": True,
        "method": "hash-bound-prebuilt-host-helper",
        "compilerDiscoveryFallback": reason,
        "sourceSha256": provenance["sourceSha256"],
        "headerSha256": provenance["coffHeaderSha256"],
        "hostCompiler": provenance["hostCompiler"],
        "hostCompilerSha256": provenance["hostCompilerSha256"],
        "prebuiltExecutable": str(executable.resolve()),
        "prebuiltExecutableSha256": sha(executable),
        "executable": str(target.resolve()),
        "executableSha256": sha(target),
        "archiveSha256": provenance["archiveSha256"],
        "runtimeBundleManifestSha256": sha(bundle / "manifest.json"),
    }
    (output / "provenance.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


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
    try:
        compiler = host_compiler(compiler)
    except ValueError as error:
        if compiler is not None:
            raise
        return build_prebuilt_host(bundle, output, str(error))

    index, files = load_bundle(bundle)
    archives = primary_archives(bundle, files)
    output.mkdir(parents=True, exist_ok=True)
    members = (
        ("djlsr205.zip", "src/djasm/djasm.c", "src/djasm/djasm.c"),
        ("djdev205.zip", "include/coff.h", "include/coff.h"),
    )
    for archive, member, target in members:
        with zipfile.ZipFile(archives[archive]) as package:
            content = package.read(member)
        path = output / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)

    executable = output / "djasm-host.exe"
    process = subprocess.run(
        [str(compiler), "-O2", "-std=gnu89", str(output / "src/djasm/djasm.c"), "-o", str(executable)],
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
        "method": "rebuilt-from-primary-source",
        "sourceSha256": sha(output / "src/djasm/djasm.c"),
        "headerSha256": sha(output / "include/coff.h"),
        "hostCompiler": str(compiler.resolve()),
        "hostCompilerSha256": sha(compiler),
        "executable": str(executable.resolve()),
        "executableSha256": sha(executable),
        "archiveSha256": {name: sha(path) for name, path in archives.items()},
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
