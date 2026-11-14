#!/usr/bin/env python3
"""Code-only ISA scan: what minimum CPU does the *compiled instructions* need?

Why this exists separately from `isa-audit.ps1`
-----------------------------------------------
The object-level audit disassembles whole `.text` sections.  That is the right
way to ask "which encodings exist in this binary", and for the retained i486
release it gives a clean, actionable answer.  It cannot answer the i386
question, and the reason is specific to this toolchain:

    no object produced by this build has a `.rodata` section.

DJGPP's GCC puts string literals and jump tables inside `.text`, so a linear
disassembly of the section decodes ASCII as x86.  `63 6b 20` -- "ck " -- reads as
`arpl`, `62 61 64` -- "bad" -- reads as `bound`.  On the i486 audit those land
below the threshold and are harmless; on an i386 gate they are 722 phantom
violations out of 1027.

So the two tools measure different things on purpose:

* `isa-audit.ps1`  -- encodings present in the built objects.  A superset.  Use
  it to catch an instruction appearing anywhere at all.
* this tool        -- ISA of executed instructions only, read from the compiler's
  own assembly output, where a `.string` directive is visibly a directive and an
  instruction is visibly an instruction.  No data/code ambiguity.

Both are needed.  A clean result from this tool is the claim "the code we
compile needs no more than X"; a clean result from the other is the claim "no
newer encoding has appeared anywhere in the binary".

How it works
------------
It does not duplicate the build's flag list.  It asks `build-dos.ps1 -DumpFlags`
for the exact `cFlags` this target compiles with, runs the compiler to `.s`, and
classifies each instruction line.  The assembly half is preprocessed with the
same `asmFlags` and classified the same way.

Mnemonic classification
-----------------------
Instructions are classified by mnemonic, not by byte, because at this stage a
line is known to be an instruction. IMUL operand count selects different
encodings, but all forms used by this 32-bit build are supported on the 386:

* `imull %ebx,%eax`  -- two operands, neither an immediate.  This is
  `IMUL r32, r/m32`, opcode 0F AF, documented in the Intel 80386 manual.
* `imull $10,%eax`   -- one operand.  This is `F7 /5`, one-operand IMUL, which is
  an i286 instruction and perfectly fine on a 386. The immediate two- and
  three-operand forms are also available on the 386.

An unrecognised mnemonic is reported as `unknown` and counts against the gate.
The table is a floor, not a ceiling: it must be extended rather than bypassed.

Usage
-----
    python tools/isa-audit-source.py -CpuTarget i386
    python tools/isa-audit-source.py -CpuTarget i386 -FailOnViolation
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from _nq import BuildFlagsError, dump_flags  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS_DIR = os.path.join(REPO_ROOT, "tools")
SOURCE_ROOT = os.path.join(REPO_ROOT, "src")


def source_path(name: str) -> str:
    """Resolve the build's stable basename inventory in the grouped source tree."""
    direct = os.path.join(SOURCE_ROOT, name)
    if os.path.isfile(direct):
        return direct
    matches = []
    for root, _dirs, files in os.walk(SOURCE_ROOT):
        if os.path.basename(name) in files:
            matches.append(os.path.join(root, os.path.basename(name)))
    if len(matches) != 1:
        raise SystemExit(
            "expected one source named %r under %s, found %d"
            % (name, SOURCE_ROOT, len(matches))
        )
    return matches[0]

ISA_RANK = {"i386": 0, "i486": 1, "i586": 2, "p6": 3, "unknown": 99}

# Mnemonics that exist only from the i486 upwards.
I486_MNEMONICS = {
    "set",            # the bare SETcc form
    "bswap",
    "shld", "shldl", "shldw",
    "shrd", "shrdl", "shrdw",
    "xadd", "xaddl", "xaddw", "xaddb",
    "cmpxchg", "cmpxchgl", "cmpxchgw", "cmpxchgb",
    "lldt", "ltr", "clts", "wbinvd", "bound", "arpl",
    # verr and verw used to sit here with the comment "386; kept here only so it is
    # never silently 486+ below", which says the opposite of what the entry does:
    # listing them here is what makes them i486, so an i386 gate would report a
    # phantom violation for a 386 instruction. They are in I386_SAFE now.
}

# Mnemonics that exist only from the Pentium upwards.
I586_MNEMONICS = {
    "popcnt", "popcntl", "popcntw",
    "cmpxchg8b", "cmpxchg16b",
    "rdmsr", "wrmsr", "rdtsc", "rdts", "rdpmc",
    "cpuid",
    "movnti", "movntil", "movntps", "movntpd",
    "fxsave", "fxrstor", "ldmxcsr", "stmxcsr", "emms",
    "ud2",             # the formal trap instruction; added with the Pentium
}

# Anything containing one of these is beyond the 486 target.
#
# MOVQ is intentionally handled separately in classify(): MMX/XMM operands are
# beyond the 486 target, and an unrecognized 64-bit spelling must not inherit the
# 386 MOV classification.
#
# _assert_no_shadowed_mnemonics below makes that class of mistake impossible to
# reintroduce silently: any name in both this tuple and I386_SAFE is a table bug,
# because whichever test runs first wins.
P6_SUBSTRINGS = (
    "movss", "movsd", "movaps", "movapd", "movups", "movupd", "movdqa", "movdqu",
    "movdqa32", "movdqu8", "movdqa16", "movdqu16", "movlps", "movhps",
    "addss", "addsd", "addps", "addpd", "subss", "subsd", "subps", "subpd",
    "mulss", "mulsd", "mulps", "mulpd", "divss", "divsd", "divps", "divpd",
    "cvtsi2ss", "cvtsi2sd", "cvtss2si", "cvtsd2si", "cvtt", "cvttss",
    "punpck", "packss", "padd", "psub", "pmul", "pand", "por", "pxor", "pcmpeq",
    "psll", "psrl", "psra", "emms", "movmskps", "shufps", "unpck", "pause",
    "fxsave", "fxrstor", "ldmxcsr", "stmxcsr",
)

# x87 P6 comparisons.  Note that FCOMI is DA/DB register form only; the byte-level
# tool handles that discrimination, here we go by what the compiler spelled.
P6_X87 = {"fcomi", "fcomip", "fucomi", "fucomip", "fisttp", "fisttpl", "fisttps"}

# x87.  No non-x87 x86 mnemonic begins with `f`, so a leading `f` means x87 --
# except for the handful of P6/SSE additions, which are named explicitly above.
# Getting this wrong is not hypothetical: the first version of this table
# treated the whole D8..DF byte range as potentially-P6 and reported 17 phantom
# FCOMIs that were really FILD m64int.
X87 = re.compile(r"^f[a-z0-9]{1,10}$")

# Everything a 386 can execute.  This is a whitelist, not a blacklist: a
# mnemonic that is not listed here and not positively identified as newer is
# reported as `unknown` and counts against the gate, so the table has to be
# extended deliberately rather than widened by accident.
I386_SAFE = {
    # data movement
    "mov", "movb", "movw", "movl", "movsb", "movsw", "movsl",
    # movzbq, movzwq and movswq were listed here. They are the sign/zero-extend-
    # to-64-bit forms: long mode only, so calling them i386 was a false claim. They
    # resolve to i386 anyway through the suffix-strip retry below, so removing them
    # changes no count and removes the wrong assertion.
    "movzbw", "movzwl", "movzbl", "movsbw", "movsbl", "movswl",
    "lea", "leal", "leaw",
    "xchg",           # register form only; the memory form is i486
    "push", "pushl", "pushw", "pushb", "pushfl", "pushfw",
    "pop", "popl", "popw", "popb", "popfl", "popfw",
    "lods", "lodsl", "lodsw", "lodsb",
    "stos", "stosl", "stosw", "stosb",
    "scas", "scasl", "scasw", "scasb",
    "cmps", "cmpsl", "cmpsw", "cmpsb",
    # verr and verw are 386 and belong here, not in I486_MNEMONICS.
    "verr", "verw",
    # arithmetic
    "add", "addb", "addw", "addl", "addq",
    "adc", "adcb", "adcw", "adcl", "adcq",
    "sub", "subb", "subw", "subl", "subq",
    "sbb", "sbbb", "sbbw", "sbbl", "sbbq",
    "cmp", "cmpb", "cmpw", "cmpl", "cmpq",
    "neg", "negb", "negw", "negl", "negq",
    "inc", "incb", "incw", "incl", "incq",
    "dec", "decb", "decw", "decl", "decq",
    "mul", "mulb", "mulw", "mull", "mulq",
    "div", "divb", "divw", "divl", "divq",
    "idiv", "idivb", "idivw", "idivl", "idivq",
    "daa", "das", "aaa", "aas", "aam", "aad",
    # logical
    "and", "andb", "andw", "andl", "andq",
    "or", "orb", "orw", "orl", "orl", "orq",
    "xor", "xorb", "xorw", "xorl", "xorq",
    "not", "notb", "notw", "notl", "notq",
    # shifts and rotates
    "shl", "shlb", "shlw", "shll", "shlq",
    "sal", "salb", "salw", "sall", "salq",
    "shr", "shrb", "shrw", "shrl", "shrq",
    "sar", "sarb", "sarw", "sarl", "sarq",
    "rol", "rolb", "rolw", "roll", "rolq",
    "ror", "rorb", "rorw", "rorl", "rorq",
    "rcl", "rclb", "rclw", "rcll", "rclq",
    "rcr", "rcrb", "rcrw", "rcrl", "rcrq",
    # bit scan
    "bsf", "bsfl", "bsfw", "bsfq", "bsr", "bsrl", "bsrw", "bsrq",
    # test
    "test", "testb", "testw", "testl", "testq",
    # control flow
    "jmp", "jmpl", "call", "calll", "ret", "retl", "retq", "retw",
    "leave", "leaveq", "loop", "loopl", "loope", "loopne", "loopz", "loopnz",
    "jcxz", "jecxz", "jrcxz", "enter",
    "int", "int3", "into", "iret", "iretl", "iretd", "iretq",
    "nop", "hlt", "wait",
    # flags
    "cld", "std", "clc", "stc", "cmc", "sahf", "lahf",
    "pushf", "pushfl", "popf", "popfl", "salc",
    # prefixes spelled on their own line
    "rep", "repe", "repz", "repne", "repnz", "lock", "data16", "addr32",
    # segment registers
    "pushfs", "pushgs", "popfs", "popgs", "pushes", "pushds", "popes", "popds",
    # sign extension: CBW/CWDE/CDQ (and their AX/DX short spellings)
    "cbw", "cwde", "cdq", "cwd", "cltd", "cwtl", "cqto", "cqo", "cltq",
    # port I/O and string I/O
    "in", "inb", "inw", "ind", "inl",
    "out", "outb", "outw", "outd", "outl",
    "ins", "insb", "insw", "insl", "insd",
    "outs", "outsb", "outsw", "outsl", "outsd",
}

# x86 conditional branches: jz/je/jne/jb/jnb/... plus the near/far jcc forms.
JCC = re.compile(r"^j[a-z]{1,3}$")


def _assert_no_shadowed_mnemonics() -> None:
    """Fail at import if a mnemonic's classification is decided by test order.

    classify() tries the exact-match tables first and the P6 substring test before
    I386_SAFE, so a name present in both I386_SAFE and P6_SUBSTRINGS is silently
    reported as p6 no matter what I386_SAFE says. That is not a hypothetical: movq
    was in both, and every movq was classified p6 until it was removed from the
    substring tuple.

    The same shape of mistake applies to the exact tables, which are checked in a
    fixed order, so a name in two of those is equally arbitrary. Both are checked
    here rather than left to review.
    """
    problems = []
    shadowed = sorted(set(I386_SAFE) & set(P6_SUBSTRINGS))
    for name in shadowed:
        problems.append(
            "%r is in both I386_SAFE and P6_SUBSTRINGS; P6 wins, so the i386 entry is dead" % name
        )
    for earlier, later in (
        (I386_SAFE, I486_MNEMONICS), (I386_SAFE, I586_MNEMONICS),
        (I486_MNEMONICS, I586_MNEMONICS), (I486_MNEMONICS, P6_X87),
        (I586_MNEMONICS, P6_X87),
    ):
        for name in sorted(set(earlier) & set(later)):
            problems.append("%r is in two exact-match tables" % name)
    if problems:
        raise AssertionError(
            "isa-audit-source.py: the mnemonic tables contradict each other:\n  "
            + "\n  ".join(problems)
            + "\nA mnemonic's classification must follow from one table only."
        )


_assert_no_shadowed_mnemonics()


def classify(mnemonic: str, operands: str) -> str:
    """Return the minimum ISA level for one instruction mnemonic."""
    if not mnemonic:
        return "unknown"
    m = mnemonic

    # --- imul ---------------------------------------------------------------
    # The 386 supports F7 /5, 0F AF, and the immediate 69/6B forms. Keep the
    # 64-bit mnemonic unknown: it is not an instruction in this 32-bit target.
    if m == "imulq":
        return "unknown"
    if m in ("imul", "imull", "imulw", "imulb"):
        return "i386"

    # --- setcc / cmovcc -----------------------------------------------------
    if re.match(r"^set[a-z]{1,3}$", m):
        return "i386"
    if m.startswith("cmov") and len(m) > 4 and m[4:].isalpha():
        # CMOVcc is P6. Accept suffix spellings such as cmovnel here too; the
        # final object-byte audit remains authoritative for malformed names.
        return "p6"
    if m == "movq":
        # In this 32-bit target, MOVQ with an MMX/XMM register is a SIMD
        # instruction. There is no general-purpose 64-bit MOV form; do not
        # let an unrecognized MOVQ spelling inherit the 386 MOV classification.
        return "p6" if re.search(r"%(?:mm|xmm)\d+\b", operands.lower()) else "unknown"

    # --- bit test with a register bit offset -------------------------------
    if m in ("bt", "bts", "btr", "btc"):
        # 0F BA (immediate bit offset) is i386; the register-offset form
        # 0F A3/AB/B3/BB is i486.
        return "i386" if operands.strip().startswith("$") else "i486"

    # --- positively newer, checked before the x87 rule so `fxsave` is not
    #     mistaken for x87 and `fcomi` for a 387 comparison.
    if m in I486_MNEMONICS:
        return "i486"
    if m in I586_MNEMONICS:
        return "i586"
    if m in P6_X87:
        return "p6"
    if any(token in m for token in P6_SUBSTRINGS):
        return "p6"

    if JCC.match(m):
        return "i386"
    if X87.match(m):
        return "i386"
    if m in I386_SAFE:
        return "i386"

    # Strip one size suffix and retry; `movsl` -> `movs` and friends.
    for suffix in ("ll", "l", "w", "b", "q"):
        if m.endswith(suffix) and len(m) > len(suffix):
            return classify(m[: -len(suffix)], operands)

    return "unknown"


DIRECTIVE = re.compile(r"^\s*[.\w$@%]")
LABEL_ONLY = re.compile(r"^\s*([A-Za-z_$.][\w$.]*)\s*:")
INSTRUCTION = re.compile(r"^\s*([a-z][a-z0-9]*)\b\s*(.*)$")


def iter_instructions(text: str):
    """Yield (line_number, mnemonic, operands) for instruction lines only.

    The distinction that matters: a `.string "bad"` line is data, and its bytes
    are not instructions, so it is skipped.  A `movl 4(%esp),%eax` line is code.
    """
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        # Block comments (gas under -x assembler-with-cpp has few, but be safe).
        if stripped.startswith("/*") or stripped.startswith("*"):
            continue
        if stripped.startswith("."):
            continue
        if LABEL_ONLY.match(stripped):
            continue
        match = INSTRUCTION.match(line)
        if not match:
            continue
        yield number, match.group(1), match.group(2).split("//")[0].strip()


def build_flags(cpu_target: str) -> dict:
    """Resolved supported configuration for a target, as build-dos.ps1 reports it."""
    try:
        arguments = ["-CpuTarget", cpu_target]
        if cpu_target == "i386":
            arguments = ["-Configuration", "c-reference", *arguments]
        return dump_flags(*arguments)
    except BuildFlagsError as error:
        raise SystemExit(str(error)) from error


def toolchain_env(tool_root: str) -> tuple:
    """Return (environment, compiler path) for driving the DJGPP compiler.

    Mirrors build-dos.ps1's own environment: DJDIR, GCC_EXEC_PREFIX with its
    trailing separator, and the two bin directories ahead of PATH.  The trailing
    separator matters -- without it the driver looks for 'cc1' rather than
    'lib/gcc/<version>/cc1' -- which is why this duplicates the PowerShell rather
    than guessing.

    -ToolRoot is honoured because every other tool in this directory takes it, and
    a caller with the toolchain somewhere other than %LOCALAPPDATA% could not run
    this one at all.  os.environ['LOCALAPPDATA'] is also read defensively: it can
    be unset, and a bare KeyError names neither the cause nor the fix.
    """
    if not tool_root:
        local_app_data = os.environ.get("LOCALAPPDATA")
        if not local_app_data:
            raise SystemExit(
                "LOCALAPPDATA is not set and no -ToolRoot was given. Pass -ToolRoot, "
                "or run tools/bootstrap-dos.ps1 on a normal Windows account."
            )
        tool_root = os.path.join(local_app_data, "486quake", "tools")

    manifest_path = os.path.join(TOOLS_DIR, "dos-toolchain.json")
    if not os.path.isfile(manifest_path):
        raise SystemExit("toolchain manifest not found: %s" % manifest_path)
    with open(manifest_path, "r", encoding="ascii") as handle:
        manifest = json.load(handle)

    djgpp = os.path.join(tool_root, manifest["djgpp"]["installDirectory"])
    env = dict(os.environ)
    env["DJDIR"] = os.path.join(djgpp, "i586-pc-msdosdjgpp")
    env["GCC_EXEC_PREFIX"] = os.path.join(djgpp, "lib", "gcc") + os.sep
    env["PATH"] = os.pathsep.join(
        [os.path.join(djgpp, "bin"),
         os.path.join(djgpp, "i586-pc-msdosdjgpp", "bin"),
         env["PATH"]]
    )
    compiler = os.path.join(djgpp, *manifest["djgpp"]["compiler"].split("/"))
    if not os.path.isfile(compiler):
        raise SystemExit(
            "%s does not exist. Run tools/bootstrap-dos.ps1, or pass -ToolRoot." % compiler
        )
    return env, compiler


def load_baseline(path: str) -> dict:
    if not os.path.isfile(path):
        raise SystemExit(
            "missing ISA source baseline %s; run with --record once the figures are "
            "known to be right" % path
        )
    with open(path, "r", encoding="ascii") as handle:
        return json.load(handle)


def record_baseline(path: str, cpu_target: str, totals: dict, above: int) -> None:
    """Write the figures this target just produced.

    This records independently measured compiler output. The above-target count
    should remain zero for a 486 build; a count that goes up is a build failure.
    """
    baseline = load_baseline_or_empty(path)
    baseline["targets"][cpu_target] = {
        "recorded": time.strftime("%Y-%m-%d"),
        "isaTotals": {k: totals[k] for k in ("i386", "i486", "i586", "p6", "unknown")},
        "aboveTarget": above,
    }
    with open(path, "w", encoding="ascii", newline="\n") as handle:
        json.dump(baseline, handle, indent=2, sort_keys=False)
        handle.write("\n")


def load_baseline_or_empty(path: str) -> dict:
    if os.path.isfile(path):
        return load_baseline(path)
    return {
        "schema": "nitroquake-isa-source-ratchet-baseline/1",
        "note": (
            "Source-level ISA ratchet for tools/isa-audit-source.py. Unlike "
            "tools/golden/isa-baseline.json these are figures from the compiler's "
            "own output rather than from disassembled objects, so they count one hit "
            "per source construct instead of one per inlined copy and are expected to "
            "land near, not on, the object-level numbers. Compare the two as a "
            "cross-check: agreement is the evidence that isa-audit.ps1's 62/63 "
            "string-data exclusion is sound rather than convenient. The end state is "
            "all zeros."
        ),
        "absoluteRules": {
            "unclassifiedMustBeZero": True,
            "p6MustBeZero": True,
        },
        "targets": {},
    }


def check_against_baseline(baseline: dict, cpu_target: str, totals: dict, above: int) -> list:
    """Return the list of gate failures; empty means the ratchet holds."""
    problems = []
    # Absolute rules. An unclassified instruction never passes, and p6 is never
    # acceptable in this tree at all.
    if totals["unknown"]:
        problems.append(
            "unclassified instructions: %d (must be 0; a gap in the mnemonic table "
            "is not a pass)" % totals["unknown"]
        )
    if totals["p6"]:
        problems.append(
            "p6 (MMX/SSE/3DNow) instructions: %d (must be 0)" % totals["p6"]
        )

    recorded = baseline.get("targets", {}).get(cpu_target)
    if recorded is None:
        problems.append(
            "no baseline recorded for target %r; the gate fails closed. Record one "
            "with --record." % cpu_target
        )
        return problems

    # Ratchet on each ISA bucket separately as well as on the total, so a change
    # that trades 3 i486 for 5 i586 cannot hide inside an unchanged sum.
    for key in ("i486", "i586"):
        want = recorded.get("isaTotals", {}).get(key)
        if want is not None and totals[key] > want:
            problems.append("%s: %d above baseline %d" % (key, totals[key], want))
    want_above = recorded.get("aboveTarget")
    if want_above is not None and above > want_above:
        problems.append(
            "above-target total: %d above baseline %d" % (above, want_above)
        )
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-CpuTarget", default="i386", choices=["i386", "i486"])
    parser.add_argument("-MaxIsa", default=None, choices=["i386", "i486", "i586", "p6"])
    parser.add_argument("-ToolRoot", default=None,
                        help="toolchain directory; defaults to %%LOCALAPPDATA%%\\486quake\\tools")
    parser.add_argument("-OutputJson", default=None)
    parser.add_argument("-FailOnViolation", action="store_true")
    parser.add_argument("-Baseline", default=None,
                        help="ratchet baseline; defaults to tools/golden/isa-source-baseline.json")
    parser.add_argument("--record", action="store_true",
                        help="re-record the ratchet baseline for this target")
    args = parser.parse_args()

    max_isa = args.MaxIsa or args.CpuTarget
    max_rank = ISA_RANK[max_isa]

    flags = build_flags(args.CpuTarget)
    env, compiler = toolchain_env(args.ToolRoot)

    totals = {"i386": 0, "i486": 0, "i586": 0, "p6": 0, "unknown": 0}
    violations: dict[tuple, dict] = {}
    unknown: dict[tuple, dict] = {}

    def record(bucket: dict, path: str, line: int, mnemonic: str, isa: str, operands: str):
        key = (path, mnemonic, isa)
        if key in bucket:
            bucket[key]["count"] += 1
        else:
            bucket[key] = {
                "file": path, "line": line, "mnemonic": mnemonic,
                "required": isa, "count": 1, "example": operands,
            }

    def scan(name: str, completed, env_arg, is_c: bool) -> None:
        """Classify one compilation unit's instructions into the two buckets.

        The two halves differ in what they run and in what their line numbers mean,
        so they are one function with one flag rather than two copies of the same
        eight lines.
        """
        if completed.returncode != 0:
            verb = "compiling %s to assembly" % name if is_c else "preprocessing %s" % name
            raise SystemExit("%s failed:\n%s" % (verb, completed.stderr.strip()))
        for line, mnemonic, operands in iter_instructions(completed.stdout):
            isa = classify(mnemonic, operands)
            totals[isa] += 1
            if ISA_RANK[isa] > max_rank:
                record(violations, name, line, mnemonic, isa, operands)
            if isa == "unknown":
                record(unknown, name, line, mnemonic, isa, operands)

    # --- C half: ask the compiler for assembly ----------------------------
    # The line numbers here index the compiler's -S output, not the C file, because
    # that is the text being scanned. They are reported under the C file's name
    # because that is the file a reader needs to open to find the code, but they
    # are not lines OF that file and must not be cited as such. asmLineNumber is
    # what they are; see the report's lineNumberKind field.
    for name in flags["cSources"]:
        source = source_path(name)
        source_flags = flags.get("cSourceExtraFlags", {}).get(name, [])
        scan(name, subprocess.run(
            [compiler, *flags["cFlags"], *source_flags, "-S", "-o", "-", source],
            capture_output=True, text=True, env=env,
        ), env, True)

    # --- assembly half: preprocess with the build's asmFlags ---------------
    # Here the line numbers really are lines of the named file's preprocessed text,
    # which is what the reader wants to see.
    for name in flags["assemblySources"]:
        source = source_path(name)
        scan(name, subprocess.run(
            [compiler, *flags["asmFlags"], "-E", source],
            capture_output=True, text=True, env=env,
        ), env, False)

    report = {
        "schema": 1,
        "cpuTarget": args.CpuTarget,
        "maxIsa": max_isa,
        # What the `line` on each row means, so no reader mistakes one for the
        # other. For a .c row it is a line of the compiler's generated assembly,
        # not a line of the C file; for a .s row it is a line of that file's
        # preprocessed text. Neither is a line number that survives an edit to the
        # file it is filed under, which is why docs/ledger/INDEX.md's rule is to
        # cite these findings by file and heading, never by ":NNNN".
        "lineNumberKind": {
            ".c": "line of the compiler's -S output for that file, filed under the C file's name",
            ".s": "line of that file's preprocessed (-E) output",
        },
        "cSourceCount": len(flags["cSources"]),
        "assemblySourceCount": len(flags["assemblySources"]),
        "instructionCount": sum(totals.values()),
        "isaTotals": totals,
        "violationCount": sum(row["count"] for row in violations.values()),
        "unclassifiedCount": sum(row["count"] for row in unknown.values()),
        "result": "PASS" if not violations and not unknown else (
            "INCOMPLETE" if not violations else "FAIL"),
        "violations": sorted(violations.values(), key=lambda r: (r["required"], r["file"], r["line"])),
        "unclassified": sorted(unknown.values(), key=lambda r: (r["file"], r["line"])),
    }

    output = args.OutputJson or os.path.join(
        REPO_ROOT, "out", "isa-source-%s.json" % args.CpuTarget)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, "w", encoding="ascii") as handle:
        json.dump(report, handle, indent=2)

    print("ISA source scan: %s" % report["result"])
    print("  target              %s (max %s)" % (args.CpuTarget, max_isa))
    print("  sources             %d C + %d assembly"
          % (report["cSourceCount"], report["assemblySourceCount"]))
    print("  instructions        %d" % report["instructionCount"])
    print("  i386 %d  i486 %d  i586 %d  p6 %d  unknown %d"
          % (totals["i386"], totals["i486"], totals["i586"], totals["p6"], totals["unknown"]))
    print("  above %s          %d" % (max_isa, report["violationCount"]))
    print("  unclassified        %d" % report["unclassifiedCount"])
    print("  report              %s" % os.path.relpath(output, REPO_ROOT))

    if report["unclassifiedCount"]:
        print("\nUnclassified mnemonics -- extend the table, do not bypass it:")
        for row in report["unclassified"][:40]:
            print("  %-24s:%-6d %-10s %s"
                  % (row["file"], row["line"], row["mnemonic"], row["example"]))
    if report["violationCount"]:
        print("\nAbove %s:" % max_isa)
        for row in report["violations"][:60]:
            print("  %-24s:%-6d %-6s %-10s x%d"
                  % (row["file"], row["line"], row["required"], row["mnemonic"], row["count"]))
        if len(report["violations"]) > 60:
            print("  ... %d more in the report" % (len(report["violations"]) - 60))

    if args.FailOnViolation and (report["violationCount"] or report["unclassifiedCount"]):
        print("\nFAILED: the compiled code for %s needs more than %s."
              % (args.CpuTarget, max_isa))
        return 1

    # --- the ratchet --------------------------------------------------------
    # The baseline ratchets each ISA bucket and keeps unknown and P6 instructions
    # at zero. -FailOnViolation is also available for an absolute ISA check.
    baseline_path = args.Baseline or os.path.join(
        TOOLS_DIR, "golden", "isa-source-baseline.json")

    if args.record:
        record_baseline(baseline_path, args.CpuTarget, totals, report["violationCount"])
        print("\nISA source baseline recorded for %s: %d above-%s instruction(s)."
              % (args.CpuTarget, report["violationCount"], max_isa))
        print("  %s" % os.path.relpath(baseline_path, REPO_ROOT))
        print("  diff it and confirm every changed figure is one you meant to change.")
        return 0

    try:
        baseline = load_baseline(baseline_path)
    except SystemExit as exc:
        print("\n%s" % exc)
        return 1

    problems = check_against_baseline(baseline, args.CpuTarget, totals, report["violationCount"])
    recorded = baseline.get("targets", {}).get(args.CpuTarget, {})
    want_above = recorded.get("aboveTarget")
    progress = ("baseline %s, now %d" % (want_above, report["violationCount"])
                if want_above is not None else "no baseline")
    print("  ratchet          %s  [%s]" % (
        "PASS" if not problems else "FAIL", progress))
    if problems:
        print("")
        for problem in problems:
            print("  %s" % problem)
        print("\nThe source-level ISA count moved the wrong way, or an absolute rule "
              "was broken. This is a ratchet, not an absolute pass: see %s."
              % os.path.relpath(baseline_path, REPO_ROOT))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
