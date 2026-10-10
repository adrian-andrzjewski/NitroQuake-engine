#!/usr/bin/env python3
"""Source contracts for the strict-i486 R_EntityParticles leaf.

The DOS BENCH486 fixture is authoritative for C/ASM state, ABI, and RNG
parity. These host checks keep its audited source, matrix, and selector
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


class EntityParticlesSourceContractTests(unittest.TestCase):
    def test_assembly_declares_i486_and_uses_reviewed_integer_x87_instructions(self) -> None:
        source = read("src/r_entityparticlesasm.s")
        self.assertIn(".arch i486", source)
        self.assertIn(".arch .387", source)

        allowed = {
            "addl", "andl", "call", "cmpl", "faddp", "fadds", "fcos",
            "fimull", "fld", "fldl", "flds", "fmul", "fmulp", "fmuls",
            "fsts", "fstp", "fstps", "fsin", "fsubp", "fxch", "incl", "je", "jmp",
            "jne", "movl", "movw", "popl", "pushl", "ret", "subl", "testl",
            "xorl",
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
        self.assertIsNone(re.search(
            r"(?im)^\s*(?:cmov\w*|emms|movq|padd\w*|psub\w*|\w*s[sd]\w*)\b",
            source,
        ), "post-486 or SIMD mnemonic found")

    def test_c_oracle_layout_and_direct_fixture_cover_state_and_rng(self) -> None:
        c_source = read("src/r_part.c")
        fixture = read("src/bench486_entityparticles.h")
        host = read("src/host_cmd.c")
        for contract in (
            "#define R_EntityParticles R_EntityParticles_C",
            "#if !defined(ASM486_ENTITY_PARTICLES) || defined(BENCH486)",
            "Bench486EntityParticlesRand",
            "Bench486EntityParticlesResetState",
            "offsetof(entity_t, origin) == 84",
            "offsetof(client_state_t, time) == 572",
        ):
            self.assertIn(contract, c_source)
        for contract in (
            '"cold-empty-warm-empty-single"',
            '"cold-single-warm-partial-full"',
            '"negative-time-wide-beam"',
            '"large-time-and-coordinate"',
            '"libc-rng-full-and-repeat"',
            "EP_NORMAL_COUNT * 3",
            "Bench486Call_asm486 (function, 1, arguments, NULL)",
            "R_EntityParticles_C",
            "R_EntityParticles_asm486",
            "Bench486EntityParticlesCases ();",
            '"-benchentityparticles"',
        ):
            self.assertIn(contract, fixture + host)

    def test_selector_and_direct_benchmark_keep_c_as_default(self) -> None:
        selectors = read("tools/selectors.ps1")
        build = read("tools/build-dos.ps1")
        runner = read("tools/bench-dos.ps1")
        build_test = read("tools/test-build-dos.py")
        run_tests = read("tools/run-tests.ps1")
        for contract in (
            "'EntityParticlesImplementation'",
            "ASM486_ENTITY_PARTICLES",
            "entityparticlesasm",
            "entityParticlesImplementation",
        ):
            self.assertIn(contract, selectors)
        self.assertRegex(
            build,
            r"\[string\]\$EntityParticlesImplementation\s*=\s*'c'",
        )
        for contract in (
            "[switch]$EntityParticlesOnly",
            "-EntityParticlesOnly requires -EntityParticlesImplementation asm",
            "-benchentityparticles -benchexit",
            'dump_flags("-EntityParticlesImplementation", "asm")',
            "test-entityparticles.py",
        ):
            self.assertIn(contract, runner + build_test + run_tests)

        for target in ("i386", "i486"):
            golden = json.loads(read("tools/golden/build-flags-%s.json" % target))
            self.assertEqual(golden["allAssemblySourceCount"], 53)
            self.assertIn("r_entityparticlesasm.s", golden["assemblySources"])


if __name__ == "__main__":
    unittest.main()
