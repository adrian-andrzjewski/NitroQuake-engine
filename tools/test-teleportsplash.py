#!/usr/bin/env python3
"""Source-level contract checks for the i486 R_TeleportSplash slice.

The DOS BENCH486 fixture remains the authority for C/ASM state and RNG parity;
this host test guards the lattice/reference contract, selector wiring, and
source ISA mnemonics without compiling or generating build artifacts.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class TeleportSplashSourceContractTests(unittest.TestCase):
    def test_i486_source_uses_only_reviewed_integer_and_x87_mnemonics(self) -> None:
        source = read("src/r_teleportsplashasm.s")
        self.assertIn(".arch i486", source, "assembly must declare the target ISA")
        self.assertIn(".arch .387", source, "assembly must declare its x87 requirement")

        allowed = {
            "addl", "andl", "call", "cmpl", "faddl", "faddp", "fadds",
            "fiaddl", "fildl", "fldl", "flds", "fmull", "fstp", "fstps",
            "incl", "jge", "jg", "jle", "jl", "jmp", "jne", "jz", "leal",
            "movb", "movl", "popl", "pushl", "ret", "shll", "subl", "testl",
        }
        found = []
        source_without_comments = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
        for original in source_without_comments.splitlines():
            line = original.strip()
            if not line or line.startswith(("#", ".")) or line.endswith(":"):
                continue
            mnemonic = line.split(None, 1)[0].lower()
            found.append(mnemonic)
        self.assertTrue(found, "assembly source has no machine instructions")
        self.assertEqual(sorted(set(found) - allowed), [],
                         "unreviewed assembly mnemonics found")
        self.assertEqual(
            len(re.findall(r"(?im)^\s*call\s+TELEPORT_SPLASH_RAND\s*$", source)),
            6,
            "the assembly emitter must make six random calls per particle",
        )
        self.assertIn("call\tC(VectorNormalize)", source,
                      "the first port should share the C normalizer")
        self.assertIn("call\tC(VectorScale)", source,
                      "the first port should share the C scaler")
        self.assertNotRegex(
            source,
            r"(?im)^\s*(?:cmov\w*|emms|movq|padd\w*|psub\w*|\w*s[sd]\w*)\b",
        )

    def test_c_oracle_and_guarded_fixture_cover_lattice_and_pool_boundaries(self) -> None:
        c_source = read("src/r_part.c")
        fixture = read("src/bench486_teleportsplash.h")
        host = read("src/host_cmd.c")
        for contract in (
            "#define R_TeleportSplash R_TeleportSplash_C",
            "#if !defined(ASM486_TELEPORT_SPLASH) || defined(BENCH486)",
            "Bench486TeleportSplashRand",
        ):
            self.assertIn(contract, c_source, "missing C-oracle contract: " + contract)
        for mask in (7, 3, 63):
            self.assertRegex(
                c_source,
                r"TELEPORT_SPLASH_RAND\(\)\s*&\s*%d" % mask,
            )

        for contract in (
            "TS_GUARD_WORDS 8",
            "TS_EMIT_LIMIT 896",
            "TS_FREE_MAX (TS_EMIT_LIMIT + 1)",
            "outer = i / (8 * 14)",
            "middle = (i / 14) % 8",
            "inner = i % 14",
            "grid_x = -16 + outer * 4",
            "grid_y = -16 + middle * 4",
            "grid_z = -24 + inner * 4",
            '"empty"',
            '"one"',
            '"partial"',
            '"almost-full"',
            '"full"',
            '"one-extra"',
            '"libc-rng-continuation"',
            "emitted * 6",
            "Q_memcmp (bench486_teleportsplash_reference",
            "Q_memcmp (&particle->die, &expected_die",
            "Q_memcmp (particle->org, expected_org",
            "Q_memcmp (particle->vel, expected_vel",
            "bench486_teleportsplash_rand_calls",
            "Bench486TeleportSplashCases ();",
            '"-benchteleportsplash"',
        ):
            self.assertIn(contract, fixture + host,
                          "missing direct-fixture contract: " + contract)
        self.assertRegex(fixture, r'\{ "almost-full", 895,')
        self.assertRegex(fixture, r'\{ "full", 896,')
        self.assertRegex(fixture, r'\{ "one-extra", 897,')
        self.assertIn("bench486_teleportsplash_layout", fixture,
                      "fixture must pin the particle ABI layout")
        self.assertIn("offsetof(particle_t, ramp) == 32", fixture,
                      "fixture must cover the unused ramp field")
        self.assertIn("TS_GUARD_WORDS", fixture,
                      "fixture must retain canaries around its pool")

    def test_selector_and_runner_keep_c_reference_default(self) -> None:
        selectors = read("tools/selectors.ps1")
        build = read("tools/build-dos.ps1")
        bench = read("tools/bench-dos.ps1")
        run_tests = read("tools/run-tests.ps1")
        build_test = read("tools/test-build-dos.py")
        for contract in (
            "'TeleportSplashImplementation'",
            "ASM486_TELEPORT_SPLASH",
            "teleportsplashasm",
            "teleportSplashImplementation",
        ):
            self.assertIn(contract, selectors,
                          "missing TeleportSplash selector contract: " + contract)
        self.assertRegex(
            build,
            r"\[string\]\$TeleportSplashImplementation\s*=\s*'c'",
        )
        self.assertIn("[switch]$TeleportSplashOnly", bench,
                      "benchmark runner needs an isolated fixture mode")
        self.assertIn(
            "-TeleportSplashOnly requires -TeleportSplashImplementation asm",
            bench,
            "isolated fixture mode must select the assembly implementation",
        )
        self.assertIn("-benchteleportsplash -benchexit", bench,
                      "fixture must exit after checking libc RNG continuation")
        self.assertIn(
            'dump_flags("-TeleportSplashImplementation", "asm")',
            build_test,
            "build flag tests must verify selector source wiring",
        )
        self.assertIn("test-teleportsplash.py", run_tests,
                      "the host contract test must run in the normal workflow")

        for target in ("i386", "i486"):
            golden = json.loads(
                read("tools/golden/build-flags-%s.json" % target)
            )
            self.assertIn("r_teleportsplashasm.s", golden["assemblySources"],
                          "the %s source inventory must include TeleportSplash ASM" % target)


if __name__ == "__main__":
    unittest.main()
