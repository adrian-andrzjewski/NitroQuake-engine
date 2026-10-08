#!/usr/bin/env python3
"""Inventory built renderer entries and their direct machine-code callees.

This is an ownership/gap report, separate from the ISA audit. C code that passes
the ISA gate is still C-owned. Indirect calls/jumps are reported for explicit
review; direct reachability alone is never advertised as a complete call graph.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import deque
from pathlib import Path


HEADER = re.compile(r"^([0-9a-fA-F]+) <([^>]+)>:")
SYMBOL = re.compile(r"^\[\s*\d+\]\(sec\s+1\).*?0x([0-9a-fA-F]+) (\S+)$")
INSTRUCTION = re.compile(r"^\s*([0-9a-fA-F]+):\s+(?:[0-9a-fA-F]{2}\s+)+\s*(\S+)(?:\s+(.*))?$")
RELOCATION = re.compile(r"^\s*[0-9a-fA-F]+:\s+DISP32\s+(\S+)\s*$")
RENDER_SUPPORT = {"Mod_PointInLeaf", "Mod_LeafPVS", "Mod_DecompressVis"}


def original_function(symbol: str) -> str:
    """Map GCC clone symbols back to the C definition that owns their code."""
    return re.sub(r"\.(?:part|constprop|isra|cold|split)(?:\.[0-9]+)?(?:\..*)?$", "", symbol.lstrip("_"))


def c_functions(path: Path) -> set[str]:
    source = path.read_text(encoding="latin1")
    source = re.sub(r"/\*.*?\*/|//[^\n]*", " ", source, flags=re.S)
    source = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '""', source)
    source = re.sub(r"^\s*#[^\n]*", "", source, flags=re.M)
    names = set()
    for match in re.finditer(r"\b(\w+)\s*\(", source):
        if match[1] in {"if", "while", "for", "switch", "sizeof", "__attribute__"}:
            continue
        depth = 1
        end = match.end()
        while end < len(source) and depth:
            depth += (source[end] == '(') - (source[end] == ')')
            end += 1
        if not depth and source[end:].lstrip().startswith('{'):
            names.add(match[1])
    return names


def renderer_source(name: str, symbol: str) -> bool:
    return (name.startswith(("r_", "d_", "v_")) or name in {"view.c", "draw.c", "mathlib.c", "math.s", "chase.c", "asm486_experiments.s"}
            or (name == "model.c" and original_function(symbol) in RENDER_SUPPORT))


def inventory(manifest: dict, objects: Path, repo: Path, objdump: Path, roots: list[str], boundaries: list[str]) -> dict:
    source_by_object = {Path(name).stem + ".obj": name
                        for name in manifest["cSources"] + manifest["assemblySources"]}
    c_names = {name: c_functions(repo / "src" / name) for name in manifest["cSources"]}
    units: dict[str, dict] = {}
    paths = [objects / name for name in source_by_object]
    missing = [str(path) for path in paths if not path.is_file()]
    if missing:
        raise ValueError("missing selected objects: " + ", ".join(missing))
    for begin in range(0, len(paths), 32):
        run = subprocess.run([str(objdump), "-t", "-dr", *map(str, paths[begin:begin + 32])],
                             text=True, capture_output=True, check=True)
        unit = None
        current = None
        last_instruction = None
        for line in run.stdout.splitlines():
            file_match = re.match(r"^(.+\.obj):\s+file format\s+coff-go32", line)
            if file_match:
                name = Path(file_match[1]).name
                unit = units.setdefault(name, {"symbols": {}, "functions": {}})
                current = last_instruction = None
                continue
            if unit is None:
                continue
            match = SYMBOL.match(line)
            if match:
                unit["symbols"][match[2]] = int(match[1], 16)
                continue
            match = HEADER.match(line)
            if match:
                current = unit["functions"].setdefault(int(match[1], 16), {
                    "displaySymbol": match[2], "calls": {}, "indirectTransfers": [],
                })
                last_instruction = None
                continue
            if current is None:
                continue
            match = RELOCATION.match(line)
            if match and last_instruction and last_instruction[1] in {"call", "jmp"}:
                # Object disassembly prints a placeholder target before the
                # relocation. It is not an additional call to that function.
                current["calls"][last_instruction[0]] = match[1]
                continue
            match = INSTRUCTION.match(line)
            if not match:
                continue
            address, operation, operands = match[1], match[2], match[3] or ""
            last_instruction = (address, operation, operands)
            if operation in {"call", "jmp"}:
                if operands.startswith("*"):
                    current["indirectTransfers"].append({"offset": "0x" + address, "instruction": operation + " " + operands})
                else:
                    target = re.search(r"<([^>+]+)(?:\+0x[0-9a-f]+)?>", operands)
                    if target and "+" not in operands and target[1] != ".text":
                        current["calls"][address] = target[1]

    entries: dict[str, dict] = {}
    for object_name, unit in units.items():
        source = source_by_object[object_name]
        for symbol, address in unit["symbols"].items():
            function = unit["functions"].get(address)
            if function is None or symbol.startswith("."):
                continue
            # C constants and dispatch tables also occupy .text in COFF. Only
            # names defined as functions in the C source are C-owned entries.
            original_name = original_function(symbol)
            if source.endswith(".c") and original_name not in c_names[source]:
                continue
            entries[symbol] = {
                "symbol": symbol, "source": source, "object": object_name,
                "offset": hex(address), "language": "assembly" if source.endswith(".s") else "C",
                "rendererOwned": renderer_source(source, symbol),
                "calls": sorted(set(function["calls"].values()) - {symbol}),
                "indirectTransfers": function["indirectTransfers"],
            }

    absent_roots = [root for root in roots if root not in entries]
    if absent_roots:
        raise ValueError("unresolved rendering roots: " + ", ".join(absent_roots))
    seen: set[str] = set()
    parents: dict[str, str | None] = {root: None for root in roots}
    queue = deque(roots)
    unresolved: set[str] = set()
    while queue:
        symbol = queue.popleft()
        if symbol in seen:
            continue
        seen.add(symbol)
        if symbol in boundaries:
            continue
        for callee in entries[symbol]["calls"]:
            if callee not in entries:
                unresolved.add(callee)
            elif callee not in parents:
                parents[callee] = symbol
                queue.append(callee)
    for symbol in seen:
        trace = [symbol]
        while parents[trace[-1]] is not None:
            trace.append(parents[trace[-1]])
        entries[symbol]["directRootTrace"] = list(reversed(trace))
    owned = sorted((entry for entry in entries.values() if entry["rendererOwned"]), key=lambda entry: (entry["source"], entry["symbol"]))
    pending = [entry for entry in owned if entry["language"] == "C" and entry["symbol"] in seen]
    return {
        "schemaVersion": 1, "purpose": "renderer-machine-code-ownership-inventory",
        "completeCallGraph": False,
        "limitations": ["Indirect transfers require explicit review.", "Runtime-library calls are resolved by the separate linked ISA audit.",
                        "Unreached C oracle/debug entries are listed separately from directly reachable C dependencies."],
        "roots": roots, "objectsInspected": len(units), "rendererEntries": owned,
        "explicitTraversalBoundaries": boundaries,
        "directlyReachableRendererC": pending,
        "directlyReachableIndirectTransfers": [entries[name] for name in sorted(seen) if entries[name]["indirectTransfers"]],
        "unresolvedDirectCallees": sorted(unresolved),
        "summary": {"rendererEntries": len(owned), "directlyReachableEntries": len(seen),
                    "directlyReachableRendererC": len(pending), "unresolvedDirectCallees": len(unresolved)},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--object-root", type=Path, required=True)
    parser.add_argument("--objdump", type=Path, required=True)
    parser.add_argument("--root", action="append", default=[])
    parser.add_argument("--boundary", action="append", default=[])
    parser.add_argument("--output-json", type=Path, required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    try:
        manifest = json.loads(args.manifest.read_text(encoding="utf-8-sig"))
        report = inventory(manifest, args.object_root, repo, args.objdump,
                           args.root or ["_R_RenderView", "_V_RenderView", "_V_UpdatePalette"], args.boundary)
        report["manifest"] = str(args.manifest.resolve())
        report["executable"] = manifest["executable"]
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        parser.error(str(exc))
    print(json.dumps(report["summary"]))
    for entry in report["directlyReachableRendererC"]:
        print(f"C dependency: {entry['source']}:{entry['symbol']} via " + " -> ".join(entry["directRootTrace"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
