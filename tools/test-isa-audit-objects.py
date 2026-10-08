#!/usr/bin/env python3
"""Exercise the real object ISA gate with assembled permitted/forbidden bytes.

Fixtures are disassembled, never executed. Keep reports under out/ for diagnosis.
Requires the pinned DJGPP toolchain; accepts --tool-root like isa-audit.ps1.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tool-root", type=Path)
    args = parser.parse_args()
    tool_root = args.tool_root or Path(os.environ["LOCALAPPDATA"]) / "486quake/tools"
    manifest = json.loads((ROOT / "tools/dos-toolchain.json").read_text(encoding="utf-8"))
    compiler = tool_root / manifest["djgpp"]["installDirectory"] / manifest["djgpp"]["compiler"]
    if not compiler.is_file():
        parser.error(f"missing pinned compiler: {compiler}; run bootstrap-dos.ps1")
    shell = shutil.which("pwsh") or shutil.which("powershell")
    if not shell:
        parser.error("PowerShell is required")
    out = ROOT / "out"
    out.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="isa-object-regression-", dir=out))

    permitted = {
        "imul": "0f af c3", "bswap": "0f c8", "xadd": "0f c1 d8",
        "cmpxchg": "0f b1 18", "setcc": "0f 95 c0", "fsin": "d9 fe",
        "fcos": "d9 ff", "fld80": "db 28", "fild64": "df 28",
        "fistp64": "df 38", "fucompp": "da e9", "fcompp": "de d9",
        "imul16": "66 0f af c3", "fld80_addr16": "67 db 28",
        "les": "c4 00", "lds": "c5 00", "bound": "62 00",
        "sgdt": "0f 01 00", "sidt": "0f 01 08", "lgdt": "0f 01 10",
        "lidt": "0f 01 18", "smsw": "0f 01 e0", "lmsw": "0f 01 f0",
        "invlpg": "0f 01 38",
        "invlpg_addr16": "67 0f 01 38",
        "long_imul": "64 69 05 78 56 34 12 ef cd ab 89",
        "int_patch_label": "cd 03",
        "popf": "9d", "popf16": "66 9d", "clts": "0f 06",
        "arpl": "63 c0", "pushgs": "0f a8", "popgs": "0f a9",
        "lss": "0f b2 00", "lfs": "0f b4 00", "lgs": "0f b5 00",
        "invd": "0f 08", "wbinvd": "0f 09",
        "rep_movs": "f3 a5", "repne_cmps": "f2 a7",
        "rep_ins": "f3 6d", "rep_outs": "f3 6f",
        "lock_add": "f0 01 18", "lock_not": "f0 f7 10",
        "lock_neg": "f0 f7 18", "lock_inc": "f0 ff 00",
        "lock_xadd": "f0 0f c1 18", "lock_cmpxchg": "f0 0f b1 18",
        "lock_bts": "f0 0f ab 18", "lock_bts_imm": "f0 0f ba 28 01",
    }
    forbidden = {
        "cpuid": "0f a2", "rdtsc": "0f 31", "cmpxchg8b": "0f c7 08",
        "mmx": "0f ef c0", "sse": "0f 57 c0", "sse2": "66 0f ef c0",
        "movnti": "0f c3 00", "nop_p6": "0f 1f 00",
        "vex2": "c5 f8 57 c0", "vex3": "c4 e1 78 57 c0",
        "cmov_prefixes": "2e 67 66 64 0f 45 c3",
        "monitor": "0f 01 c8", "mwait": "0f 01 c9",
        "xgetbv": "0f 01 d0", "xsetbv": "0f 01 d1",
        "rdtscp": "0f 01 f9", "syscall": "0f 05",
        "evex": "62 f1 7c 48 57 c0", "fcomip_prefix": "66 df f1",
        "reserved_a6": "0f a6 c0", "reserved_a7": "0f a7 c0",
        "reserved_82": "82 c0 00", "salc": "d6", "int1": "f1",
        "aam_other_base": "d4 09", "aad_other_base": "d5 09",
        "lea_register": "8d c0", "bound_register": "62 c0",
        "lss_register": "0f b2 c0", "lfs_register": "0f b4 c0",
        "lgs_register": "0f b5 c0", "bswap16": "66 0f c8",
        "pause": "f3 90", "rep_add": "f3 01 c0",
        "repne_movs": "f2 a5", "repne_lods": "f2 ad",
        "lock_register": "f0 01 c0", "lock_cmp": "f0 39 00",
        "lock_test": "f0 f7 00 00 00 00 00", "lock_bt": "f0 0f a3 00",
        "lock_bt_imm": "f0 0f ba 20 01", "lock_mov": "f0 89 00",
        "duplicate_operand": "66 66 90", "duplicate_address": "67 67 90",
        "duplicate_segment": "2e 64 90", "duplicate_repeat": "f2 f3 a4",
    }
    for cc in range(16):
        forbidden[f"cmov_{cc:x}"] = f"0f {0x40 + cc:02x} c3"
        forbidden[f"cmov16_{cc:x}"] = f"66 0f {0x40 + cc:02x} c3"
    for opcode in (0xDA, 0xDB):
        for modrm in range(0xC0, 0xE0):
            forbidden[f"fcmov_{opcode:x}_{modrm:x}"] = f"{opcode:02x} {modrm:02x}"
    for opcode in (0xDB, 0xDF):
        for modrm in range(0xE8, 0xF8):
            forbidden[f"fcomi_{opcode:x}_{modrm:x}"] = f"{opcode:02x} {modrm:02x}"
    for opcode in (0xDB, 0xDD, 0xDF):
        forbidden[f"fisttp_{opcode:x}"] = f"{opcode:02x} 08"

    # Independently transcribed from Intel 80387 PRM appendix A, A1--A4.
    # Include all 64 register operands and all eight memory groups for every
    # x87 primary opcode; aliases present only in later/undocumented hardware
    # must not inherit the age of an old-looking mnemonic.
    register_operands = {
        0xD8: set(range(0xC0, 0x100)),
        0xD9: set(range(0xC0, 0xD0)) | {0xD0,0xE0,0xE1,0xE4,0xE5}
              | set(range(0xE8, 0xEF)) | set(range(0xF0, 0x100)),
        0xDA: {0xE9}, 0xDB: set(range(0xE0, 0xE5)),
        0xDC: set(range(0xC0, 0xD0)) | set(range(0xE0, 0x100)),
        0xDD: set(range(0xC0, 0xC8)) | set(range(0xD0, 0xF0)),
        0xDE: set(range(0xC0, 0xD0)) | {0xD9} | set(range(0xE0, 0x100)),
        0xDF: {0xE0},
    }
    memory_groups = {
        0xD8: set(range(8)), 0xD9: {0,2,3,4,5,6,7},
        0xDA: set(range(8)), 0xDB: {0,2,3,5,7},
        0xDC: set(range(8)), 0xDD: {0,2,3,4,6,7},
        0xDE: set(range(8)), 0xDF: {0,2,3,4,5,6,7},
    }
    for opcode in range(0xD8, 0xE0):
        for operand in range(0xC0, 0x100):
            cases = permitted if operand in register_operands[opcode] else forbidden
            cases[f"x87_reg_{opcode:x}_{operand:x}"] = f"{opcode:02x} {operand:02x}"
        for group in range(8):
            cases = permitted if group in memory_groups[opcode] else forbidden
            cases[f"x87_mem_{opcode:x}_{group}"] = f"{opcode:02x} {group << 3:02x}"

    # Check group holes rather than trusting the mnemonic decoder to reject.
    for opcode, legal, immediate in (
        (0x8F, {0}, ""), (0xC6, {0}, " 00"), (0xC7, {0}, " 00 00 00 00"),
        (0xFE, {0,1}, ""), (0xFF, set(range(7)), ""),
        (0xF6, {0,2,3,4,5,6,7}, ""), (0xF7, {0,2,3,4,5,6,7}, ""),
    ):
        for group in range(8):
            suffix = immediate
            if opcode in (0xF6,0xF7) and group in (0,1):
                suffix = " 00" if opcode == 0xF6 else " 00 00 00 00"
            cases = permitted if group in legal else forbidden
            cases[f"group_{opcode:x}_{group}"] = f"{opcode:02x} {group << 3:02x}" + suffix
    for group in range(8):
        for opcode, legal in ((0x8C, set(range(6))), (0x8E, {0,2,3,4,5})):
            cases = permitted if group in legal else forbidden
            cases[f"segment_{opcode:x}_{group}"] = f"{opcode:02x} {0xc0 | group << 3:02x}"
        cases = permitted if group < 6 else forbidden
        cases[f"system_group_{group}"] = f"0f 00 {0xc0 | group << 3:02x}"
        cases = permitted if group >= 4 else forbidden
        cases[f"bit_imm_group_{group}"] = f"0f ba {0xc0 | group << 3:02x} 01"
        cases = permitted if group == 0 else forbidden
        cases[f"setcc_group_{group}"] = f"0f 95 {0xc0 | group << 3:02x}"
        for opcode in (0xC0,0xC1,0xD0,0xD1,0xD2,0xD3):
            cases = permitted if group != 6 else forbidden
            cases[f"shift_group_{opcode:x}_{group}"] = f"{opcode:02x} {0xc0 | group << 3:02x}" + (" 01" if opcode in (0xC0,0xC1) else "")

    # Intel's 386/486 special-register MOV encodings share opcode escapes with
    # later control registers. Check the register field, both directions and
    # both ends of the GPR field; a generic "MOV is old" rule is insufficient.
    # Intel i486 Programmer's Reference Manual, chapters 4 and 26 (MOV).
    for family, opcodes, legal_registers in (
        ("control", (0x20, 0x22), (0, 2, 3)),
        ("debug", (0x21, 0x23), (0, 1, 2, 3, 6, 7)),
        ("test", (0x24, 0x26), (3, 4, 5, 6, 7)),
    ):
        for opcode in opcodes:
            for special in range(8):
                for general in (0, 7):
                    modrm = 0xC0 | (special << 3) | general
                    cases = permitted if special in legal_registers else forbidden
                    cases[f"mov_{family}_{opcode:x}_{special}_{general}"] = f"0f {opcode:02x} {modrm:02x}"
            forbidden[f"mov_{family}_{opcode:x}_noncanonical"] = f"0f {opcode:02x} 00"

    failures = []
    for group, cases in (("permitted", permitted), ("forbidden", forbidden)):
        build = work / group
        objects = build / "obj"
        objects.mkdir(parents=True)
        source = build / "fixture.s"
        blocks = []
        for name, encoding in cases.items():
            block = f".p2align 5,0x90\n.globl _case_{name}\n_case_{name}:\n"
            if name == "int_patch_label":
                block += ".byte 0xcd\n.globl _interrupt_patch_byte\n_interrupt_patch_byte:\n.byte 0x03\n"
            else:
                block += ".byte " + ",".join("0x" + b for b in encoding.split()) + "\n"
            blocks.append(block + "ret\n")
        # Non-CODE data deliberately contains forbidden bytes; -D must select
        # only CODE sections and still cross the interior INT patch symbol.
        source.write_text(".text\n" + "".join(blocks) +
                          ".data\n.byte 0x0f,0x45,0xc0,0xda,0xc0\n", encoding="ascii")
        subprocess.run([str(compiler), "-c", "-x", "assembler", str(source),
                        "-o", str(objects / "fixture.obj")], check=True, capture_output=True)
        report = build / "audit.json"
        details = build / "instructions.jsonl"
        result = subprocess.run([
            shell, "-NoProfile", "-File", str(ROOT / "tools/isa-audit.ps1"),
            "-BuildRoot", str(build), "-ObjectRoot", str(objects),
            "-SkipExecutable", "-MaxIsa", "i486", "-FailOnViolation",
            "-ToolRoot", str(tool_root), "-OutputJson", str(report),
            "-InstructionDetailsJsonl", str(details),
        ], capture_output=True, text=True)
        (build / "audit-output.txt").write_text(result.stdout + result.stderr, encoding="utf-8")
        if not report.is_file() or not details.is_file():
            failures.append(f"{group}: audit did not produce reports: {result.stderr}")
            continue
        if (result.returncode == 0) != (group == "permitted"):
            failures.append(f"{group}: unexpected gate exit {result.returncode}")
        first_by_symbol = {}
        for line in details.read_text(encoding="utf-8-sig").splitlines():
            entry = json.loads(line)
            first_by_symbol.setdefault(entry["symbol"], entry)
        for name, encoding in cases.items():
            entry = first_by_symbol.get("_case_" + name)
            if entry is None:
                failures.append(f"{group}/{name}: missing instruction")
                continue
            accepted = entry["isa"] in ("i386", "i486")
            if accepted != (group == "permitted"):
                failures.append(f"{group}/{name}: {encoding} classified {entry['isa']} ({entry['decoded']})")
            if accepted and " ".join(entry["bytes"]).lower() != encoding:
                failures.append(f"{group}/{name}: incomplete byte decoding: {entry['bytes']}")
    for failure in failures:
        print("FAIL: " + failure)
    print(f"Object fixture reports: {work}")
    if failures:
        return 1
    print(f"PASS: {len(permitted)} permitted and {len(forbidden)} forbidden instruction fixtures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
