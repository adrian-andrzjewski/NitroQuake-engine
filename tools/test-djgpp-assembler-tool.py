#!/usr/bin/env python3
"""Check the source-built Windows host helper and its pinned inputs."""
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
        report = assembler.build(BUNDLE, None, output)
        executable = output / "djasm-host.exe"
        if report.get("method") != "rebuilt-from-pinned-DJGPP-source":
            raise AssertionError("the helper was not built from the pinned source files")
        if not report.get("hostToolOnly") or not executable.is_file():
            raise AssertionError("the source-built helper is missing")
        if hashlib.sha256(executable.read_bytes()).hexdigest().upper() != report["executableSha256"]:
            raise AssertionError("the helper differs from its reported executable hash")

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

        compiler = Path(report["hostCompiler"])
        cross_names = (
            "DJDIR", "DJGPP", "GCC_EXEC_PREFIX", "COMPILER_PATH", "LIBRARY_PATH",
            "CPATH", "C_INCLUDE_PATH", "CPLUS_INCLUDE_PATH",
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
        if clean_environment["PATH"].split(os.pathsep)[0] != str(compiler.parent):
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
        for relative in (
            "manifest.json",
            "primary/djgpp-host/src/djasm.c",
            "primary/djgpp-host/include/coff.h",
        ):
            source = BUNDLE / relative
            target = broken / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes())
        bad_source = broken / "primary/djgpp-host/src/djasm.c"
        bad_source.write_bytes(bad_source.read_bytes() + b"\n")
        try:
            assembler.build(broken, compiler, temporary / "rejected-output")
        except ValueError as error:
            if "Changed pinned host-helper input: primary/djgpp-host/src/djasm.c" not in str(error):
                raise AssertionError("the source gate failed for an unexpected reason") from error
        else:
            raise AssertionError("the host-helper gate accepted changed pinned source")

    print("test-djgpp-assembler-tool: PASS (source build, host isolation, and pinned-input rejection)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
