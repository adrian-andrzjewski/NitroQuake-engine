#!/usr/bin/env python3
"""Source-level contract checks for the i486 R_LavaSplash slice.

The DOS BENCH486 fixture remains the authority for C/ASM state and RNG parity;
this host test guards the selector wiring, fixture coverage, and source ISA
mnemonics without compiling or generating build artifacts.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class LavaSplashSourceContractTests(unittest.TestCase):
    def test_i486_source_uses_only_audited_integer_and_x87_mnemonics(self) -> None:
        source = read("src/r_lavasplashasm.s")
        self.assertIn(".arch i486", source)
        self.assertIn(".arch .387", source)

        allowed = {
            "addl", "andl", "call", "cmpl", "faddl", "faddp", "fadds",
            "fiaddl", "fildl", "fldl", "flds", "fmull", "fstp", "fstps",
            "incl", "jge", "jmp", "jz", "leal", "movb", "movl", "popl",
            "pushl", "ret", "shll", "subl", "testl",
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
        self.assertEqual(source.count("call\tLAVA_SPLASH_RAND"), 6)
        self.assertIn("call\tC(VectorNormalize)", source)
        self.assertIn("call\tC(VectorScale)", source)
        self.assertNotRegex(source, r"(?im)^\s*(?:cmov\w*|emms|movq|padd\w*|psub\w*|\w*s[sd]\w*)\b")

    def test_c_oracle_and_guarded_fixture_cover_pool_and_rng_boundaries(self) -> None:
        c_source = read("src/r_part.c")
        fixture = read("src/bench486_lavasplash.h")
        host = read("src/host_cmd.c")
        for contract in (
            "#define R_LavaSplash R_LavaSplash_C",
            "#if !defined(ASM486_LAVA_SPLASH) || defined(BENCH486)",
            "Bench486LavaSplashRand",
            "LAVA_SPLASH_RAND()&31",
            "LAVA_SPLASH_RAND()&63",
        ):
            self.assertIn(contract, c_source)
        for case in ("empty", "one", "partial", "almost-full", "full",
                     "one-extra", "libc-rng-continuation"):
            self.assertIn('"%s"' % case, fixture)
        for contract in (
            "LS_GUARD_WORDS",
            "LS_EMIT_LIMIT 1024",
            "emitted * 6",
            "c_next != a_next",
            "Q_memcmp (bench486_lavasplash_reference",
            "Q_memcmp (&particle->die, &expected_die",
            "Q_memcmp (particle->org, expected_org",
            "Q_memcmp (particle->vel, expected_vel",
            "bench486_lavasplash_rand_calls",
            "Bench486LavaSplashCases ();",
            '"-benchlavasplash"',
        ):
            self.assertIn(contract, fixture + host)

    def test_timedemo_records_lavasplash_after_the_renderer_returns(self) -> None:
        temp_entities = read("src/cl_tent.c")
        start = temp_entities.index("case TE_LAVASPLASH:")
        end = temp_entities.index("case TE_TELEPORT:", start)
        branch = temp_entities[start:end]
        self.assertLess(branch.index("R_LavaSplash (pos);"), branch.index("Bench486RecordLavaSplashEvent ();"))
        self.assertIn("#ifdef BENCH486", branch)

        host = read("src/host_cmd.c")
        header = read("src/quakedef.h")
        for contract in (
            "BENCH486_LAVA_SPLASH_EVENT_MAX 32",
            "bench486_lava_splash_event_count = 0;",
            '"lava-splash-events %lu frames"',
            "bench486_lava_splash_event_overflow",
        ):
            self.assertIn(contract, host)
        self.assertIn("Bench486RecordLavaSplashEvent (void);", header)

    def test_selector_and_runner_keep_c_reference_default(self) -> None:
        selectors = read("tools/selectors.ps1")
        build = read("tools/build-dos.ps1")
        runner = read("tools/bench-dos.ps1")
        build_test = read("tools/test-build-dos.py")
        timedemo = read("tools/timedemo-dos.ps1")
        for contract in (
            "'LavaSplashImplementation'",
            "ASM486_LAVA_SPLASH",
            "lavasplashasm",
            "lavaSplashImplementation",
        ):
            self.assertIn(contract, selectors)
        self.assertRegex(build, r"\[string\]\$LavaSplashImplementation\s*=\s*'c'")
        self.assertIn("[switch]$LavaSplashOnly", runner)
        self.assertIn("-LavaSplashOnly requires -LavaSplashImplementation asm", runner)
        self.assertIn("-benchlavasplash -benchexit", runner)
        self.assertIn('dump_flags("-LavaSplashImplementation", "asm")', build_test)
        self.assertRegex(
            timedemo,
            r"(?m)^\s*\[string\]\$LavaSplashImplementation\s*=\s*'c'",
        )
        self.assertIn("LavaSplashImplementation             = $LavaSplashImplementation", timedemo)
        self.assertIn("lavaSplashImplementation = $LavaSplashImplementation", timedemo)

        for target in ("i386", "i486"):
            golden = json.loads(read("tools/golden/build-flags-%s.json" % target))
            self.assertEqual(golden["allAssemblySourceCount"], 53)
            self.assertIn("r_lavasplashasm.s", golden["assemblySources"])


if __name__ == "__main__":
    unittest.main()
