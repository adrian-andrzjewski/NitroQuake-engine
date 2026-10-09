#!/usr/bin/env python3
"""Regression tests for the 32-bit x86 ISA classifiers."""

from __future__ import annotations

import os
import re
import sys
import importlib.util

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

SOURCE_AUDIT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "isa-audit-source.py")
SOURCE_AUDIT_SPEC = importlib.util.spec_from_file_location("isa_audit_source", SOURCE_AUDIT_PATH)
if SOURCE_AUDIT_SPEC is None or SOURCE_AUDIT_SPEC.loader is None:
    raise RuntimeError("could not load tools/isa-audit-source.py")
isa_audit_source = importlib.util.module_from_spec(SOURCE_AUDIT_SPEC)
SOURCE_AUDIT_SPEC.loader.exec_module(isa_audit_source)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> int:
    failures: list[str] = []

    # The one-, two-, and immediate three-operand IMUL forms are all documented
    # for the 386. Operand spelling must not change the reported minimum ISA.
    for mnemonic, operands in (
        ("imul", "%ebx"),
        ("imull", "%ebx,%eax"),
        ("imull", "$7,%eax"),
        ("imull", "$7,%ebx,%eax"),
        ("imulw", "$7,%bx,%ax"),
        ("imulb", "%bl"),
    ):
        actual = isa_audit_source.classify(mnemonic, operands)
        if actual != "i386":
            failures.append("%s %s classified %s, expected i386" % (mnemonic, operands, actual))

    if isa_audit_source.classify("imulq", "%rbx,%rax") != "unknown":
        failures.append("32-bit source audit must reject the long-mode imulq mnemonic")

    # Keep the independent source-level classifier aligned with the strict
    # byte-level policy for instructions whose mnemonic alone is misleading.
    cmov_names = (
        "o no b c nae ae nb nc e z ne nz be na a nbe s ns p pe np po "
        "l nge ge nl le ng g nle"
    ).split()
    for condition in cmov_names:
        name = "cmov" + condition
        if isa_audit_source.classify(name, "%ebx,%eax") != "p6":
            failures.append("%s must be rejected as post-486" % name)
    for name in ("cmovnel", "cmovzl", "cmovgew"):
        if isa_audit_source.classify(name, "%ebx,%eax") != "p6":
            failures.append("%s suffix spelling must be rejected as post-486" % name)
    for operands in ("%mm0,%mm1", "(%eax),%mm0", "%xmm3,%xmm2"):
        if isa_audit_source.classify("movq", operands) != "p6":
            failures.append("MOVQ with SIMD operands %s must be rejected" % operands)
    if isa_audit_source.classify("movq", "%eax,%ebx") != "unknown":
        failures.append("unrecognized 32-bit MOVQ operands must fail closed")
    if isa_audit_source.classify("pause", "") != "p6":
        failures.append("PAUSE must be rejected as post-486")
    if isa_audit_source.classify("sete", "%al") != "i386":
        failures.append("SETcc must match its 386 classification")

    object_audit = os.path.join(ROOT, "tools", "isa-audit.ps1")
    with open(object_audit, "r", encoding="utf-8") as handle:
        text = handle.read()
    if not re.search(r"'0faf'\s*=\s*'i386'\s+#.*80386", text):
        failures.append("object audit must classify opcode 0F AF as i386")
    if not re.search(r"'0fc3'\s*=\s*'p6'\s+#.*MOVNTI.*SSE2", text):
        failures.append("object audit must reject MOVNTI (0F C3) as post-486")
    if "[string]$SectionAllowListJson" not in text or "allowedSectionKeys.Contains" not in text:
        failures.append("object audit must support exact linked-section allow-lists")

    linked_audit = os.path.join(ROOT, "tools", "isa-audit-linked.ps1")
    with open(linked_audit, "r", encoding="utf-8") as handle:
        linked_text = handle.read()
    for contract in (
        "-FailOnViolation",
        "Linked inputs contain code sections outside the mapped .text family",
        "Expected all executable code in the GO32 .text section",
        "objdump -r",
        "Every linker *fill* span in output .text",
        "textFillSpans = @($textFillReport.ToArray())",
        "Unmapped executable .text bytes",
        "linkedOpcodeMismatches = $mismatches.Count",
        "linkedTextRelocationCount = $textRelocationCount",
        "fullExecutableDisassembly = $fullExecutableDisassembly",
    ):
        if contract not in linked_text:
            failures.append("linked ISA audit is missing contract %r" % contract)

    if failures:
        for failure in failures:
            print("FAIL: " + failure)
        return 1

    print("PASS: all tested IMUL forms are i386; imulq is rejected for this target")
    print("PASS: object audit classifies 0F AF as i386")
    print("PASS: linked audit rejects MOVNTI and includes mapped runtime/code sections")
    return 0


if __name__ == "__main__":
    sys.exit(main())
