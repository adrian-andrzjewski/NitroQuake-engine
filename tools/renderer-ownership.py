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
SYMBOL = re.compile(r"^\[\s*\d+\]\(sec\s+[1-9]\d*\).*?0x([0-9a-fA-F]+) (\S+)$")
INSTRUCTION = re.compile(r"^\s*([0-9a-fA-F]+):\s+(?:[0-9a-fA-F]{2}\s+)+\s*(\S+)(?:\s+(.*))?$")
RELOCATION = re.compile(r"^\s*([0-9a-fA-F]+):\s+(DISP32|DIR32)\s+(\S+)\s*$", re.IGNORECASE)
RENDER_SUPPORT = {"Mod_PointInLeaf", "Mod_LeafPVS", "Mod_DecompressVis"}

D_DRAWSPANS_TARGETS = {
    "_D_DrawSpans8": "d_draw.s",
    "_D_DrawSpans16": "d_draw16.s",
}


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


def _instruction_at(function: dict, offset: int) -> dict | None:
    for instruction in function["instructions"]:
        if int(instruction["offset"], 16) == offset:
            return instruction
    return None


def _branch_target(instruction: dict) -> int | None:
    match = re.match(r"^\s*([0-9a-fA-F]+)(?:\s|$)", instruction["operands"])
    return int(match[1], 16) if match else None


def _writes_register(instruction: dict, register: str) -> bool:
    """Conservatively detect explicit writes to one GPR in an instruction."""
    operation = instruction["operation"].lower()
    operands = [part.strip() for part in instruction["operands"].split(",") if part.strip()]
    if not operands or operation.startswith(("cmp", "test", "push", "call", "jmp", "ret", "j")):
        return False
    if operation.startswith("xchg"):
        return f"%{register}" in operands
    if operation.startswith("set"):
        return operands[-1] == f"%{register}"
    return operands[-1] == f"%{register}"


def _renderer_function(symbol: str, source: str, entries: dict[str, dict],
                       units: dict[str, dict], closure: str = "d_drawspans") -> tuple[dict, dict]:
    entry = entries.get(symbol)
    if entry is None or entry["source"] != source or entry["language"] != "assembly":
        raise ValueError(f"{closure} closure requires assembly entry {symbol} from {source}")
    unit = units[entry["object"]]
    address = unit["symbols"].get(symbol)
    function = unit["functions"].get(address)
    if function is None:
        raise ValueError(f"{closure} closure cannot inspect {symbol} in {entry['object']}")
    return entry, function


def resolve_d_drawspans_targets(manifest: dict, units: dict[str, dict],
                                entries: dict[str, dict]) -> list[dict]:
    """Prove the combined assembly surface path's runtime span-kernel target set.

    The proof is deliberately narrow: D_DrawSurfaces must load the d_drawspans
    pointer at its indirect call, and the selected assembly D_SetupFrame must
    have only the two relocation-backed stores to that pointer, one per kernel.
    Its conditional branch must select between those loads and merge at the
    shared pointer store. The target definitions must themselves be assembly
    entries from the selected d_draw.s and d_draw16.s objects.
    """
    if (manifest.get("surfaceDrawImplementation") != "asm" or
            manifest.get("drawingDriverImplementation") != "asm"):
        return []

    required_sources = {
        "asm486_experiments.s", "d_driverasm.s", "d_draw.s", "d_draw16.s",
    }
    selected_assembly = set(manifest.get("assemblySources", []))
    missing_sources = sorted(required_sources - selected_assembly)
    if missing_sources:
        raise ValueError("combined d_drawspans profile omits assembly sources: " + ", ".join(missing_sources))

    consumer_entry, consumer = _renderer_function(
        "_D_DrawSurfaces", "asm486_experiments.s", entries, units)
    setter_entry, setter = _renderer_function(
        "_D_SetupFrame", "d_driverasm.s", entries, units)

    pointer_loads = [relocation for relocation in consumer["relocations"]
                     if relocation["symbol"].lower() == "_d_drawspans"]
    if len(pointer_loads) != 1:
        raise ValueError("d_drawspans closure expected one pointer load in _D_DrawSurfaces")
    pointer_load = pointer_loads[0]
    if pointer_load["type"] != "DIR32":
        raise ValueError("d_drawspans closure requires a DIR32 relocation for the global pointer load")
    load_instruction = _instruction_at(consumer, int(pointer_load["instructionOffset"], 16))
    if (load_instruction is None or load_instruction["operation"] not in {"mov", "movl"} or
            re.fullmatch(r"0x[0-9a-fA-F]+,%eax", load_instruction["operands"].replace(" ", "")) is None):
        raise ValueError("d_drawspans closure found an unexpected _D_DrawSurfaces pointer load")

    consumer_instructions = consumer["instructions"]
    load_index = consumer_instructions.index(load_instruction)
    if load_index + 1 >= len(consumer_instructions):
        raise ValueError("d_drawspans closure found no indirect call after the pointer load")
    call_instruction = consumer_instructions[load_index + 1]
    if call_instruction["operation"] != "call" or call_instruction["operands"].replace(" ", "") != "*%eax":
        raise ValueError("d_drawspans closure found no call through the loaded _d_drawspans pointer")
    call_address = int(call_instruction["offset"], 16)
    if any(instruction["operation"].startswith("j") and _branch_target(instruction) == call_address
           for instruction in consumer_instructions):
        raise ValueError("d_drawspans closure found a branch that bypasses the pointer load")
    call_offset = "0x" + call_instruction["offset"]
    if not any(item["offset"] == call_offset and item["instruction"] == "call *%eax"
               for item in consumer_entry["indirectTransfers"]):
        raise ValueError("d_drawspans closure call does not match the reported indirect transfer")

    target_relocations = [relocation for relocation in setter["relocations"]
                          if relocation["symbol"] in D_DRAWSPANS_TARGETS]
    target_counts = {symbol: sum(relocation["symbol"] == symbol for relocation in target_relocations)
                     for symbol in D_DRAWSPANS_TARGETS}
    if target_counts != {"_D_DrawSpans8": 1, "_D_DrawSpans16": 1}:
        raise ValueError("d_drawspans closure requires exactly one D_DrawSpans8 and one D_DrawSpans16 assignment")
    unexpected_targets = [relocation["symbol"] for relocation in setter["relocations"]
                          if relocation["symbol"].startswith("_D_DrawSpans") and
                          relocation["symbol"] not in D_DRAWSPANS_TARGETS]
    if unexpected_targets:
        raise ValueError("d_drawspans closure found unexpected span targets: " + ", ".join(sorted(set(unexpected_targets))))

    pointer_stores = [relocation for relocation in setter["relocations"]
                      if relocation["symbol"].lower() == "_d_drawspans"]
    if len(pointer_stores) != 1:
        raise ValueError("d_drawspans closure expected one pointer store in _D_SetupFrame")
    target_instructions: dict[str, dict] = {}
    for relocation in target_relocations:
        if relocation["type"] != "DIR32":
            raise ValueError(f"d_drawspans closure target {relocation['symbol']} requires a DIR32 address relocation")
        instruction = _instruction_at(setter, int(relocation["instructionOffset"], 16))
        if (instruction is None or instruction["operation"] not in {"mov", "movl"} or
                re.fullmatch(r"\$0x[0-9a-fA-F]+,%eax", instruction["operands"].replace(" ", "")) is None):
            raise ValueError(f"d_drawspans closure target {relocation['symbol']} is not loaded into %eax")
        target_instructions[relocation["symbol"]] = instruction

    store_relocation = pointer_stores[0]
    if store_relocation["type"] != "DIR32":
        raise ValueError("d_drawspans closure requires a DIR32 relocation for the global pointer store")
    store_instruction = _instruction_at(setter, int(store_relocation["instructionOffset"], 16))
    if (store_instruction is None or store_instruction["operation"] not in {"mov", "movl"} or
            re.fullmatch(r"%eax,0x[0-9a-fA-F]+", store_instruction["operands"].replace(" ", "")) is None):
        raise ValueError("d_drawspans closure pointer store does not write the selected %eax target")

    instructions = setter["instructions"]
    index_by_offset = {int(instruction["offset"], 16): index
                       for index, instruction in enumerate(instructions)}
    eight = target_instructions["_D_DrawSpans8"]
    sixteen = target_instructions["_D_DrawSpans16"]
    store_offset = int(store_instruction["offset"], 16)
    eight_index = index_by_offset[int(eight["offset"], 16)]
    sixteen_index = index_by_offset[int(sixteen["offset"], 16)]
    store_index = index_by_offset[store_offset]
    if (sixteen_index == 0 or sixteen_index + 1 >= len(instructions) or
            eight_index + 1 >= len(instructions) or
            not instructions[sixteen_index - 1]["operation"].startswith("j") or
            instructions[sixteen_index - 1]["operation"] == "jmp" or
            _branch_target(instructions[sixteen_index - 1]) != int(eight["offset"], 16) or
            instructions[sixteen_index + 1]["operation"] != "jmp" or
            _branch_target(instructions[sixteen_index + 1]) != store_offset or
            instructions[eight_index + 1] is not store_instruction or
            not sixteen_index < eight_index < store_index):
        raise ValueError("d_drawspans closure could not prove the two branch paths merge at the pointer store")
    branch_to_eight = [instruction for instruction in instructions
                       if instruction["operation"].startswith("j") and
                       _branch_target(instruction) == int(eight["offset"], 16)]
    branch_to_store = [instruction for instruction in instructions
                       if instruction["operation"].startswith("j") and
                       _branch_target(instruction) == store_offset]
    if (branch_to_eight != [instructions[sixteen_index - 1]] or
            branch_to_store != [instructions[sixteen_index + 1]]):
        raise ValueError("d_drawspans closure found an alternate branch into the target selection or pointer store")

    targets = []
    for symbol, source in sorted(D_DRAWSPANS_TARGETS.items()):
        target_entry, _ = _renderer_function(symbol, source, entries, units)
        targets.append({key: target_entry[key] for key in ("symbol", "source", "object", "language")})
    return [{
        "pointer": "_d_drawspans",
        "consumer": consumer_entry["symbol"],
        "consumerSource": consumer_entry["source"],
        "consumerObject": consumer_entry["object"],
        "callSiteOffset": call_offset,
        "setter": setter_entry["symbol"],
        "setterSource": setter_entry["source"],
        "setterObject": setter_entry["object"],
        "selectionAssignments": [
            {"target": "_D_DrawSpans16", "offset": "0x" + sixteen["offset"]},
            {"target": "_D_DrawSpans8", "offset": "0x" + eight["offset"]},
        ],
        "pointerStoreOffset": "0x" + store_instruction["offset"],
        "profile": {
            "surfaceDrawImplementation": manifest["surfaceDrawImplementation"],
            "drawingDriverImplementation": manifest["drawingDriverImplementation"],
        },
        "targets": targets,
        "proof": "structural disassembly and DIR32 relocations show _D_SetupFrame selects only these two assembly addresses; this does not enumerate writers outside the selected setter",
    }]


PDRAW_FUNC_TARGETS = {
    "_R_GenerateSpans": "r_edgea.s",
    "_R_GenerateSpansBackward": "r_publicbindingsasm.s",
}
PDRAW_FUNC_PRIVATE_ALIASES = {
    "_R_GenerateSpans_asm486": "r_edgea.s",
    "_R_GenerateSpansBackward_asm486": "asm486_experiments.s",
}


def resolve_pdrawfunc_targets(manifest: dict, units: dict[str, dict],
                              entries: dict[str, dict]) -> list[dict]:
    """Prove the selected edge-span dispatcher has only its two asm targets.

    The selected R_BeginEdgeFrame assembly entry chooses between the forward
    and backward span functions and stores that address in pdrawfunc. The
    selected R_ScanEdges assembly entry must load that pointer immediately
    before each of its two indirect calls. The backward public entry is a
    small assembly tail binding to R_GenerateSpansBackward_asm486.
    """
    if (manifest.get("worldControlImplementation") != "asm" or
            manifest.get("scanEdgesImplementation") != "asm" or
            manifest.get("backwardSpansImplementation") != "asm"):
        return []

    required_sources = {
        "r_worldcontrolasm.s", "asm486_experiments.s", "r_edgea.s",
        "r_publicbindingsasm.s",
    }
    selected_assembly = set(manifest.get("assemblySources", []))
    missing_sources = sorted(required_sources - selected_assembly)
    if missing_sources:
        raise ValueError("_pdrawfunc closure requires assembly sources: " + ", ".join(missing_sources))

    span_aliases = {
        symbol for unit in units.values() for symbol in unit["symbols"]
        if symbol.startswith("_R_GenerateSpans") and symbol.endswith("_asm486")
    }
    expected_aliases = set(PDRAW_FUNC_PRIVATE_ALIASES)
    unexpected_aliases = sorted(span_aliases - expected_aliases)
    missing_aliases = sorted(expected_aliases - span_aliases)
    if unexpected_aliases:
        raise ValueError("_pdrawfunc closure found unexpected span aliases: " + ", ".join(unexpected_aliases))
    if missing_aliases:
        raise ValueError("_pdrawfunc closure requires private span aliases: " + ", ".join(missing_aliases))

    for symbol, source in PDRAW_FUNC_PRIVATE_ALIASES.items():
        _renderer_function(symbol, source, entries, units, "_pdrawfunc")

    setter_entry, setter = _renderer_function(
        "_R_BeginEdgeFrame", "r_worldcontrolasm.s", entries, units, "_pdrawfunc")
    consumer_entry, consumer = _renderer_function(
        "_R_ScanEdges_asm486", "asm486_experiments.s", entries, units, "_pdrawfunc")

    target_relocations = [relocation for relocation in setter["relocations"]
                          if relocation["symbol"] in PDRAW_FUNC_TARGETS]
    target_counts = {symbol: sum(relocation["symbol"] == symbol for relocation in target_relocations)
                     for symbol in PDRAW_FUNC_TARGETS}
    if target_counts != {"_R_GenerateSpans": 1, "_R_GenerateSpansBackward": 1}:
        raise ValueError("_pdrawfunc closure requires exactly one forward and one backward span assignment")
    unexpected_targets = [relocation["symbol"] for relocation in setter["relocations"]
                          if relocation["symbol"].startswith("_R_GenerateSpans") and
            relocation["symbol"] not in PDRAW_FUNC_TARGETS]
    if unexpected_targets:
        raise ValueError("_pdrawfunc closure found unexpected span targets: " +
                         ", ".join(sorted(set(unexpected_targets))))

    pointer_stores = [relocation for relocation in setter["relocations"]
                      if relocation["symbol"].lower() == "_pdrawfunc"]
    if len(pointer_stores) != 1:
        raise ValueError("_pdrawfunc closure expected one pointer store in _R_BeginEdgeFrame")

    target_instructions: dict[str, dict] = {}
    target_registers: dict[str, str] = {}
    for relocation in target_relocations:
        if relocation["type"] != "DIR32":
            raise ValueError(f"_pdrawfunc closure target {relocation['symbol']} requires a DIR32 address relocation")
        instruction = _instruction_at(setter, int(relocation["instructionOffset"], 16))
        match = (re.fullmatch(r"\$0x[0-9a-fA-F]+,%([a-z0-9]+)",
                              instruction["operands"].replace(" ", ""))
                 if instruction and instruction["operation"] in {"mov", "movl"} else None)
        if match is None:
            raise ValueError(f"_pdrawfunc closure target {relocation['symbol']} is not loaded from its address")
        target_instructions[relocation["symbol"]] = instruction
        target_registers[relocation["symbol"]] = match[1]

    store_relocation = pointer_stores[0]
    if store_relocation["type"] != "DIR32":
        raise ValueError("_pdrawfunc closure requires a DIR32 relocation for the global pointer store")
    store_instruction = _instruction_at(setter, int(store_relocation["instructionOffset"], 16))
    store_match = (re.fullmatch(r"%([a-z0-9]+),0x[0-9a-fA-F]+",
                                store_instruction["operands"].replace(" ", ""))
                   if store_instruction and store_instruction["operation"] in {"mov", "movl"} else None)
    if store_match is None:
        raise ValueError("_pdrawfunc closure pointer store does not write the selected register")
    selected_register = store_match[1]
    if any(register != selected_register for register in target_registers.values()):
        raise ValueError("_pdrawfunc closure target loads do not feed the shared pointer store")

    instructions = setter["instructions"]
    index_by_offset = {int(instruction["offset"], 16): index
                       for index, instruction in enumerate(instructions)}
    forward = target_instructions["_R_GenerateSpans"]
    backward = target_instructions["_R_GenerateSpansBackward"]
    store_offset = int(store_instruction["offset"], 16)
    forward_index = index_by_offset[int(forward["offset"], 16)]
    backward_index = index_by_offset[int(backward["offset"], 16)]
    store_index = index_by_offset[store_offset]
    backward_address = int(backward["offset"], 16)
    selector_branches = [instruction for instruction in instructions
                         if instruction["operation"].startswith("j") and
                         _branch_target(instruction) == backward_address]
    store_branches = [instruction for instruction in instructions
                      if instruction["operation"].startswith("j") and
                      _branch_target(instruction) == store_offset]
    if (not forward_index < store_index < backward_index or
            len(selector_branches) != 1 or len(store_branches) != 1 or
            selector_branches[0]["operation"] in {"jmp", "jmpq"}):
        raise ValueError("_pdrawfunc closure could not identify the forward/backward selection paths")
    selector_index = index_by_offset[int(selector_branches[0]["offset"], 16)]
    merge_index = index_by_offset[int(store_branches[0]["offset"], 16)]
    if (selector_index + 1 != forward_index or merge_index <= backward_index or
            store_branches[0]["operation"] != "jmp" or
            not any(instruction["operation"].startswith("ret")
                    for instruction in instructions[store_index + 1:backward_index]) or
            any(instruction["operation"].startswith("j")
                for instruction in instructions[forward_index + 1:store_index]) or
            any(instruction["operation"].startswith("j")
                for instruction in instructions[backward_index + 1:merge_index]) or
            any(instruction["operation"].startswith("j") and
                _branch_target(instruction) in {
                    int(item["offset"], 16)
                    for item in instructions[forward_index:store_index + 1] +
                    instructions[backward_index:merge_index + 1]
                } and
                instruction not in selector_branches + store_branches
                for instruction in instructions)):
        raise ValueError("_pdrawfunc closure found a branch bypassing or splitting target selection")
    if (any(_writes_register(instruction, selected_register)
            for instruction in instructions[forward_index + 1:store_index]) or
            any(_writes_register(instruction, selected_register)
                for instruction in instructions[backward_index + 1:merge_index])):
        raise ValueError("_pdrawfunc closure found a selected-register clobber before the pointer store")

    pointer_loads = [relocation for relocation in consumer["relocations"]
                     if relocation["symbol"].lower() == "_pdrawfunc"]
    if len(pointer_loads) != 2:
        raise ValueError("_pdrawfunc closure expected two pointer loads in _R_ScanEdges_asm486")
    pointer_load_offsets = [int(relocation["instructionOffset"], 16)
                            for relocation in pointer_loads]
    if len(set(pointer_load_offsets)) != len(pointer_load_offsets):
        raise ValueError("_pdrawfunc closure found duplicate pointer-load relocation records")
    call_instructions = [instruction for instruction in consumer["instructions"]
                         if instruction["operation"] == "call" and
                         instruction["operands"].replace(" ", "").startswith("*")]
    if len(call_instructions) != 2:
        raise ValueError("_pdrawfunc closure expected two indirect calls in _R_ScanEdges_asm486")
    if len(consumer_entry["indirectTransfers"]) != 2:
        raise ValueError("_pdrawfunc closure found an unpaired indirect transfer in _R_ScanEdges_asm486")

    call_offsets = []
    for relocation in pointer_loads:
        if relocation["type"] != "DIR32":
            raise ValueError("_pdrawfunc closure requires DIR32 relocations for pointer loads")
        load_instruction = _instruction_at(consumer, int(relocation["instructionOffset"], 16))
        if (load_instruction is None or load_instruction["operation"] not in {"mov", "movl"} or
                re.fullmatch(r"0x[0-9a-fA-F]+,%eax", load_instruction["operands"].replace(" ", "")) is None):
            raise ValueError("_pdrawfunc closure found an unexpected _R_ScanEdges_asm486 pointer load")
        load_index = consumer["instructions"].index(load_instruction)
        if load_index + 1 >= len(consumer["instructions"]):
            raise ValueError("_pdrawfunc closure found no indirect call after a pointer load")
        call_instruction = consumer["instructions"][load_index + 1]
        if call_instruction["operation"] != "call" or call_instruction["operands"].replace(" ", "") != "*%eax":
            raise ValueError("_pdrawfunc closure found no call through the loaded _pdrawfunc pointer")
        call_address = int(call_instruction["offset"], 16)
        if any(instruction["operation"].startswith("j") and _branch_target(instruction) == call_address
               for instruction in consumer["instructions"]):
            raise ValueError("_pdrawfunc closure found a branch that bypasses a pointer load")
        call_offset = "0x" + call_instruction["offset"]
        if not any(item["offset"] == call_offset and item["instruction"] == "call *%eax"
                   for item in consumer_entry["indirectTransfers"]):
            raise ValueError("_pdrawfunc closure call does not match the reported indirect transfer")
        call_offsets.append(call_offset)
    if (len(set(call_offsets)) != len(call_offsets) or
            {int(offset, 16) for offset in call_offsets} !=
            {int(instruction["offset"], 16) for instruction in call_instructions}):
        raise ValueError("_pdrawfunc closure did not pair each unique pointer load with one unique indirect call")

    targets = []
    for symbol, source in sorted(PDRAW_FUNC_TARGETS.items()):
        target_entry, _ = _renderer_function(symbol, source, entries, units, "_pdrawfunc")
        targets.append({key: target_entry[key] for key in ("symbol", "source", "object", "language")})
    backward_public, backward_public_function = _renderer_function(
        "_R_GenerateSpansBackward", "r_publicbindingsasm.s", entries, units, "_pdrawfunc")
    backward_impl, _ = _renderer_function(
        "_R_GenerateSpansBackward_asm486", "asm486_experiments.s", entries, units, "_pdrawfunc")
    forward_entry = entries["_R_GenerateSpans"]
    forward_impl, _ = _renderer_function(
        "_R_GenerateSpans_asm486", "r_edgea.s", entries, units, "_pdrawfunc")
    if (forward_entry["object"] != forward_impl["object"] or
            forward_entry["offset"] != forward_impl["offset"]):
        raise ValueError("_pdrawfunc forward target must alias _R_GenerateSpans_asm486 at the same address")
    backward_transfers = [instruction for instruction in backward_public_function["instructions"]
                          if instruction["operation"] in {"call", "jmp"}]
    if (backward_public["calls"] != ["_R_GenerateSpansBackward_asm486"] or
            backward_public_function["indirectTransfers"] or
            len(backward_transfers) != 1 or
            backward_transfers[0]["operation"] != "jmp"):
        raise ValueError("_pdrawfunc closure requires the backward public entry to tail-transfer to its asm implementation")
    return [{
        "pointer": "_pdrawfunc",
        "consumer": consumer_entry["symbol"],
        "consumerSource": consumer_entry["source"],
        "consumerObject": consumer_entry["object"],
        "callSiteOffsets": call_offsets,
        "setter": setter_entry["symbol"],
        "setterSource": setter_entry["source"],
        "setterObject": setter_entry["object"],
        "selectionAssignments": [
            {"target": "_R_GenerateSpans", "offset": "0x" + forward["offset"]},
            {"target": "_R_GenerateSpansBackward", "offset": "0x" + backward["offset"]},
        ],
        "pointerStoreOffset": "0x" + store_instruction["offset"],
        "profile": {
            "worldControlImplementation": manifest["worldControlImplementation"],
            "scanEdgesImplementation": manifest["scanEdgesImplementation"],
            "backwardSpansImplementation": manifest["backwardSpansImplementation"],
        },
        "targets": targets,
        "implementations": [
            {key: forward_impl[key] for key in ("symbol", "source", "object", "language")},
            {key: backward_impl[key] for key in ("symbol", "source", "object", "language")},
        ],
        "proof": "structural disassembly and DIR32 relocations show _R_BeginEdgeFrame selects only these two assembly span entries and both _R_ScanEdges_asm486 indirect calls reload _pdrawfunc immediately before transfer; writers outside the selected setter are not enumerated",
    }]


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
                unit = units.setdefault(name, {
                    "symbols": {}, "symbolClasses": {}, "functions": {},
                })
                current = last_instruction = None
                continue
            if unit is None:
                continue
            match = SYMBOL.match(line)
            if match:
                unit["symbols"][match[2]] = int(match[1], 16)
                storage_class = re.search(r"\(scl\s+(\d+)\)", line)
                unit["symbolClasses"][match[2]] = int(storage_class[1]) if storage_class else None
                continue
            match = HEADER.match(line)
            if match:
                # DJGPP objdump labels local assembler branches with storage
                # class 6 as disassembly headers. They split one machine-code
                # routine into display blocks; keep those instructions and
                # relocations in the enclosing global/static function.
                storage_class = unit["symbolClasses"].get(match[2])
                if storage_class not in {2, 3, 6}:
                    raise ValueError(
                        f"objdump header {match[2]} in {name} has unclassified or unsupported "
                        f"COFF storage class {storage_class!r}")
                if storage_class != 6:
                    current = unit["functions"].setdefault(int(match[1], 16), {
                        "displaySymbol": match[2], "calls": {}, "indirectTransfers": [],
                        "instructions": [], "relocations": [],
                    })
                last_instruction = None
                continue
            if current is None:
                continue
            match = RELOCATION.match(line)
            if match:
                relocation_offset, relocation_type, symbol = match.groups()
                if last_instruction:
                    current["relocations"].append({
                        "offset": relocation_offset.lower(),
                        "type": relocation_type.upper(),
                        "symbol": symbol,
                        "instructionOffset": last_instruction["offset"],
                    })
                # Object disassembly prints a placeholder target before the
                # relocation. It is not an additional call to that function.
                if (last_instruction and last_instruction["operation"] in {"call", "jmp"} and
                        relocation_type.upper() == "DISP32"):
                    current["calls"][last_instruction["offset"]] = symbol
                continue
            match = INSTRUCTION.match(line)
            if not match:
                continue
            address, operation, operands = match[1], match[2], match[3] or ""
            instruction = {
                "offset": address.lower(), "operation": operation.lower(),
                "operands": operands,
            }
            current["instructions"].append(instruction)
            last_instruction = instruction
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
    selected_setter_target_sets = resolve_d_drawspans_targets(manifest, units, entries)
    for proof in selected_setter_target_sets:
        unreachable = [symbol for symbol in (proof["consumer"], proof["setter"]) if symbol not in seen]
        if unreachable:
            raise ValueError("d_drawspans closure is outside the production renderer path: " + ", ".join(unreachable))
    selected_indirect_target_sets = resolve_pdrawfunc_targets(manifest, units, entries)
    for proof in selected_indirect_target_sets:
        unreachable = [symbol for symbol in (proof["consumer"], proof["setter"]) if symbol not in seen]
        if unreachable:
            raise ValueError("_pdrawfunc closure is outside the production renderer path: " + ", ".join(unreachable))
    return {
        "schemaVersion": 1, "purpose": "renderer-machine-code-ownership-inventory",
        "completeCallGraph": False,
        "limitations": ["Indirect transfers require explicit review.", "Runtime-library calls are resolved by the separate linked ISA audit.",
                        "Unreached C oracle/debug entries are listed separately from directly reachable C dependencies."],
        "roots": roots, "objectsInspected": len(units), "rendererEntries": owned,
        "explicitTraversalBoundaries": boundaries,
        "directlyReachableRendererC": pending,
        "directlyReachableIndirectTransfers": [entries[name] for name in sorted(seen) if entries[name]["indirectTransfers"]],
        "selectedSetterTargetSets": selected_setter_target_sets,
        "selectedIndirectTargetSets": selected_indirect_target_sets,
        "unresolvedDirectCallees": sorted(unresolved),
        "summary": {"rendererEntries": len(owned), "directlyReachableEntries": len(seen),
                    "directlyReachableRendererC": len(pending), "unresolvedDirectCallees": len(unresolved),
                    "selectedSetterTargetSets": len(selected_setter_target_sets),
                    "selectedIndirectTargetSets": len(selected_indirect_target_sets)},
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
