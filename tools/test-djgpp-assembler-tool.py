#!/usr/bin/env python3
"""Check the pinned, offline DJASM host-helper fallback and its tamper gate."""
from pathlib import Path
import hashlib
import importlib.util
import os
import struct
import tempfile
from types import SimpleNamespace


TOOLS = Path(__file__).resolve().parent
BUNDLE = TOOLS / "isa-runtime-reference"
spec = importlib.util.spec_from_file_location("djgpp_assembler_tool", TOOLS / "djgpp-assembler-tool.py")
assembler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assembler)


def main():
    with tempfile.TemporaryDirectory(prefix="djasm-host-tool-test-") as temporary:
        temporary = Path(temporary)
        output = temporary / "verified-output"
        original_compiler = assembler.host_compiler

        def no_host_compiler(explicit=None):
            raise ValueError("test compiler unavailable")

        assembler.host_compiler = no_host_compiler
        try:
            report = assembler.build(BUNDLE, None, output)
        finally:
            assembler.host_compiler = original_compiler

        executable = output / "djasm-host.exe"
        if report.get("method") != "hash-bound-prebuilt-host-helper":
            raise AssertionError("the missing-compiler path did not use the pinned helper")
        if not report.get("hostToolOnly") or not executable.is_file():
            raise AssertionError("the pinned helper did not produce a host-only executable")
        if hashlib.sha256(executable.read_bytes()).hexdigest().upper() != report["executableSha256"]:
            raise AssertionError("the copied helper differs from its reported executable hash")

        original_executable = executable.read_bytes()
        header = struct.unpack_from("<I", original_executable, 60)[0]
        invalid_images = {}
        for name, offset, value in (
            ("bad_mz", 0, 0),
            ("dos_only_header", header, 0),
            ("wrong_machine", header + 4, 0xAA),
        ):
            image = bytearray(original_executable)
            image[offset] = value
            invalid_images[name] = image
        invalid_images["truncated"] = original_executable[:63]
        for name, image in invalid_images.items():
            path = temporary / f"{name}.exe"
            path.write_bytes(image)
            try:
                assembler.require_host_executable(path)
            except ValueError:
                pass
            else:
                raise AssertionError(f"the Windows helper validator accepted {name}")

        compiler_dir = temporary / "host-bin"
        compiler_dir.mkdir()
        compiler = compiler_dir / "gcc.exe"
        compiler.write_bytes(b"probe")
        cross_names = (
            "DJDIR",
            "DJGPP",
            "GCC_EXEC_PREFIX",
            "COMPILER_PATH",
            "LIBRARY_PATH",
            "CPATH",
            "C_INCLUDE_PATH",
            "CPLUS_INCLUDE_PATH",
        )
        saved_environment = {name: os.environ.get(name) for name in cross_names}
        for name in cross_names:
            os.environ[name] = "poisoned-target-value"
        try:
            clean_environment = assembler.host_environment(compiler)
        finally:
            for name, value in saved_environment.items():
                if value is None:
                    os.environ.pop(name, None)
                else:
                    os.environ[name] = value
        if any(name in clean_environment for name in cross_names):
            raise AssertionError("target compiler environment leaked into the host helper")
        if clean_environment["PATH"].split(os.pathsep)[0] != str(compiler_dir):
            raise AssertionError("the requested host compiler directory is not first on PATH")

        original_run = assembler.subprocess.run
        assembler.subprocess.run = lambda *args, **kwargs: SimpleNamespace(
            returncode=0, stdout="i586-pc-msdosdjgpp\n"
        )
        try:
            try:
                assembler.host_compiler(compiler)
            except ValueError:
                pass
            else:
                raise AssertionError("a DOS-target compiler was accepted as a Windows host compiler")
        finally:
            assembler.subprocess.run = original_run

        broken = temporary / "tampered-bundle"
        for relative in ("manifest.json", "prebuilt/djasm-host.exe", "prebuilt/djasm-host-provenance.json"):
            source = BUNDLE / relative
            target = broken / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes())
        bad_executable = broken / "prebuilt/djasm-host.exe"
        bad_executable.write_bytes(bad_executable.read_bytes() + b"\0")
        try:
            assembler.build_prebuilt_host(broken, temporary / "rejected-output", "test")
        except ValueError as error:
            if "Changed pinned host-helper input: prebuilt/djasm-host.exe" not in str(error):
                raise AssertionError("the fallback failed for a reason other than its tampered helper") from error
        else:
            raise AssertionError("the host-helper gate accepted a changed prebuilt executable")

    print("test-djgpp-assembler-tool: PASS (fallback source/archive/executable binding and tamper rejection)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
