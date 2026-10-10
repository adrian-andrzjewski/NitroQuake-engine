#!/usr/bin/env python3
"""Source contracts for the strict-i486 R_RunParticleEffect leaf.

The DOS BENCH486 fixture is authoritative for C/ASM state, ABI, and RNG
parity. These host checks keep the source ISA, fixture matrix, and selector
plumbing visible without creating build output.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class RunParticleEffectSourceContractTests(unittest.TestCase):
    def test_i486_assembly_uses_only_reviewed_integer_and_x87_mnemonics(self) -> None:
        source = read("src/r_runparticleeffectasm.s")
        self.assertTrue(".arch i486" in source, "assembly must declare i486")
        self.assertTrue(".arch .387" in source, "assembly must declare x87")

        allowed = {
            "addl", "andl", "call", "cmpl", "cltd", "faddl", "faddp",
            "fildl", "fldl", "flds", "fmull", "fmuls", "fstps", "idivl",
            "incl", "je", "jge", "jl", "jmp", "jnz", "jz", "movb",
            "movl", "popl", "pushl", "ret", "subl", "testl",
        }
        found = []
        source_without_comments = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
        for original in source_without_comments.splitlines():
            line = original.strip()
            if not line or line.startswith(("#", ".")) or line.endswith(":"):
                continue
            found.append(line.split(None, 1)[0].lower())
        self.assertTrue(found, "assembly source has no machine instructions")
        self.assertEqual(sorted(set(found) - allowed), [],
                         "unreviewed assembly mnemonics found")
        self.assertEqual(source.count("call\tRUN_PARTICLE_EFFECT_RAND"), 6,
                         "both branches must retain the original RNG call sites")
        self.assertIsNone(re.search(
            r"(?im)^\s*(?:cmov\w*|emms|movq|padd\w*|psub\w*|\w*s[sd]\w*)\b",
            source,
        ), "post-486 or SIMD mnemonic found")

    def test_c_oracle_and_direct_fixture_pin_both_particle_modes(self) -> None:
        c_source = read("src/r_part.c")
        fixture = read("src/bench486_runparticleeffect.h")
        host = read("src/host_cmd.c")
        for contract in (
            "#define R_RunParticleEffect R_RunParticleEffect_C",
            "#if !defined(ASM486_RUN_PARTICLE_EFFECT) || defined(BENCH486)",
            "count == 1024",
            "RUN_PARTICLE_EFFECT_RAND()",
            "Bench486RunParticleEffectRand",
        ):
            self.assertTrue(contract in c_source, "missing C contract: " + contract)
        for contract in (
            "RPE_EMIT_LIMIT 1024",
            '"negative-count"',
            '"empty-pool"',
            '"one-impact"',
            '"partial-impact"',
            '"rocket-almost-full"',
            '"rocket-full"',
            '"rocket-extra-free-node"',
            '"libc-impact-continuation"',
            '"libc-rocket-continuation"',
            "expected_calls = emitted * (cases[i].count == 1024 ? 7 : 5)",
            "bench486_runparticleeffect_reference,\n\t\t\t\t\t&bench486_runparticleeffect_fixture",
            "Bench486RunParticleEffectCases ();",
            '"-benchrunparticleeffect"',
        ):
            self.assertTrue(contract in fixture + host,
                            "missing direct-fixture contract: " + contract)
        for contract in (
            "bench486_runparticleeffect_layout",
            "RPE_GUARD_WORDS",
            "Bench486Call_asm486 (function, 4, arguments, NULL)",
        ):
            self.assertTrue(contract in fixture,
                            "missing ABI/layout contract: " + contract)

    def test_selector_and_benchmark_runner_keep_c_as_default(self) -> None:
        selectors = read("tools/selectors.ps1")
        build = read("tools/build-dos.ps1")
        runner = read("tools/bench-dos.ps1")
        build_test = read("tools/test-build-dos.py")
        run_tests = read("tools/run-tests.ps1")
        for contract in (
            "'RunParticleEffectImplementation'",
            "ASM486_RUN_PARTICLE_EFFECT",
            "runparticleeffectasm",
            "runParticleEffectImplementation",
        ):
            self.assertTrue(contract in selectors,
                            "missing selector contract: " + contract)
        self.assertRegex(
            build,
            r"\[string\]\$RunParticleEffectImplementation\s*=\s*'c'",
        )
        for contract, source in (
            ("[switch]$RunParticleEffectOnly", runner),
            ("-RunParticleEffectOnly requires -RunParticleEffectImplementation asm", runner),
            ("-benchrunparticleeffect -benchexit", runner),
            ('dump_flags("-RunParticleEffectImplementation", "asm")', build_test),
            ("test-runparticleeffect.py", run_tests),
        ):
            self.assertTrue(contract in source,
                            "missing runner/build contract: " + contract)

        for target in ("i386", "i486"):
            golden = json.loads(read("tools/golden/build-flags-%s.json" % target))
            self.assertTrue(
                "r_runparticleeffectasm.s" in golden["assemblySources"],
                "the %s inventory must include the assembly module" % target,
            )


if __name__ == "__main__":
    unittest.main()
