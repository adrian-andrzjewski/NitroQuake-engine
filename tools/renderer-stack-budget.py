#!/usr/bin/env python3
"""Check the renderer's generated stack frames against the runtime model."""

from __future__ import annotations

import argparse
import ast
import operator
import re
import sys
from dataclasses import dataclass
from pathlib import Path


CALL_BYTES = 4
CLIP_ARGUMENT_BYTES = 12
WORLD_WALK_FIXED_FRAME_BYTES = 64
WORLD_WALK_RECORD_EQUATE = "BSP_WALK_RECORD_BYTES"
WORLD_WALK_CLIP_ARGUMENT_BYTES = 8
POLY_ARGUMENT_BYTES = 8
TRANSFORM_VECTOR_ARGUMENT_BYTES = 8
MAX_PRECHECK_FRAME_BYTES = 512
FALLBACK_FRAME_BYTES = 64012
POLY_CALL_PATH_BYTES = 4648


@dataclass(frozen=True)
class FunctionFrame:
    symbol: str
    frame_bytes: int
    path: Path


def _safe_expression(expression: str, names: dict[str, int]) -> int:
    """Evaluate only integer arithmetic and already-resolved assembler names."""
    expression = expression.strip().replace("$", "")
    expression = re.sub(r"(?<=\d)[uUlL]+\b", "", expression)
    tree = ast.parse(expression, mode="eval")

    def visit(node: ast.AST) -> int:
        if isinstance(node, ast.Expression):
            return visit(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, int):
            return node.value
        if isinstance(node, ast.Name) and node.id in names:
            return names[node.id]
        if isinstance(node, ast.BinOp) and type(node.op) in _BINARY_OPERATORS:
            return _BINARY_OPERATORS[type(node.op)](visit(node.left), visit(node.right))
        if isinstance(node, ast.UnaryOp) and type(node.op) in _UNARY_OPERATORS:
            return _UNARY_OPERATORS[type(node.op)](visit(node.operand))
        raise ValueError(f"unsupported assembler integer expression: {expression}")

    return visit(tree)


_BINARY_OPERATORS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.FloorDiv: operator.floordiv,
    ast.Div: operator.floordiv,
}
_UNARY_OPERATORS = {ast.UAdd: operator.pos, ast.USub: operator.neg}


def _resolve_equates(lines: list[str]) -> dict[str, int]:
    expressions: dict[str, str] = {}
    for line in lines:
        match = re.match(r"\s*\.(?:equ|set)\s+([A-Za-z_.$][\w.$]*),\s*(.*?)\s*(?:#.*)?$", line)
        if match:
            expressions[match.group(1)] = match.group(2)

    values: dict[str, int] = {}
    pending = dict(expressions)
    while pending:
        progressed = False
        for name, expression in list(pending.items()):
            try:
                values[name] = _safe_expression(expression, values)
            except (SyntaxError, ValueError, ZeroDivisionError):
                continue
            del pending[name]
            progressed = True
        if not progressed:
            break
    return values


def _function_frame(lines: list[str], start: int, symbol: str, path: Path,
                    equates: dict[str, int]) -> FunctionFrame:
    frame = 0
    saw_prologue = False
    for line in lines[start + 1 :]:
        stripped = line.strip()
        if not stripped or stripped.startswith(("#", "/*", "*", ".")) or stripped.endswith(":"):
            continue
        push = re.match(r"push[l]?\s+%[A-Za-z0-9]+(?:\s|$)", stripped)
        if push:
            frame += 4
            saw_prologue = True
            continue
        subtract = re.match(r"sub[l]?\s+\$?([^,]+),\s*%esp(?:\s|$)", stripped)
        if subtract:
            amount = _safe_expression(subtract.group(1), equates)
            if amount < 0:
                raise ValueError(f"negative ESP reservation for {symbol} in {path}")
            frame += amount
            saw_prologue = True
            continue
        if re.match(r"mov[l]?\s+%esp,\s*%ebp(?:\s|$)", stripped):
            saw_prologue = True
            continue
        if not saw_prologue and re.match(r"(?:nop|endbr32)\b", stripped):
            continue
        break
    return FunctionFrame(symbol, frame, path)


def load_frames(object_root: Path) -> dict[str, list[FunctionFrame]]:
    files = sorted(object_root.rglob("*.s"))
    frames: dict[str, list[FunctionFrame]] = {}
    label = re.compile(r"^\s*([A-Za-z_.$][\w.$]*):\s*$")
    for path in files:
        try:
            lines = path.read_text(encoding="latin-1").splitlines()
        except OSError as error:
            raise ValueError(f"cannot read generated assembly {path}: {error}") from error
        equates = _resolve_equates(lines)
        for index, line in enumerate(lines):
            match = label.match(line)
            if not match:
                continue
            symbol = match.group(1)
            # GCC omits .globl directives for static C helpers. The selected
            # renderer symbols have an underscore-prefixed external spelling;
            # local .L labels and data expressions are irrelevant to the gate.
            if not symbol.startswith(("_R_", "_D_DrawPoly", "_TransformVector",
                                      "_Bench486Profile", "_Sys_FloatTime")):
                continue
            frames.setdefault(symbol, []).append(
                _function_frame(lines, index, symbol, path, equates))
    return frames


def choose_frame(frames: dict[str, list[FunctionFrame]], names: list[str], role: str) -> FunctionFrame:
    candidates = [frame for name in names for frame in frames.get(name, [])]
    if not candidates:
        raise ValueError(f"generated renderer assembly is missing the selected {role} entry ({', '.join(names)})")
    # Some release objects provide a public jump veneer alongside the real
    # implementation. The nonzero prologue is the frame that consumes stack.
    return max(candidates, key=lambda item: item.frame_bytes)


def choose_equate(object_root: Path, name: str) -> tuple[int, Path]:
    """Read a selected assembler constant from the generated build inputs."""
    definitions: list[tuple[int, Path]] = []
    for path in sorted(object_root.rglob("*.s")):
        try:
            lines = path.read_text(encoding="latin-1").splitlines()
        except OSError as error:
            raise ValueError(f"cannot read generated assembly {path}: {error}") from error
        value = _resolve_equates(lines).get(name)
        if value is not None:
            definitions.append((value, path))
    if not definitions:
        raise ValueError(f"generated renderer assembly is missing the {name} stack record size")
    values = {value for value, _ in definitions}
    if len(values) != 1:
        details = ", ".join(f"{path}={value}" for value, path in definitions)
        raise ValueError(f"generated renderer assembly disagrees on {name}: {details}")
    return definitions[0]


def choose_driver_noop(object_root: Path, symbol: str) -> FunctionFrame:
    """Recognize a generated DRIVER_NOOP whose assembler body is a bare ret."""
    invocation = re.compile(rf"^\s*DRIVER_NOOP\s+{re.escape(symbol)}\s*$")
    for path in sorted(object_root.rglob("*.pp.s")):
        lines = path.read_text(encoding="latin-1").splitlines()
        macro_start = next((index for index, line in enumerate(lines)
                            if re.match(r"\s*\.macro\s+DRIVER_NOOP\b", line)), None)
        if macro_start is None:
            continue
        macro_end = next((index for index in range(macro_start + 1, len(lines))
                          if re.match(r"\s*\.endm\b", lines[index])), None)
        if macro_end is None or not any(re.match(r"\s*ret\s*$", line)
                                        for line in lines[macro_start:macro_end]):
            continue
        if any(invocation.match(line) for line in lines[macro_end + 1:]):
            return FunctionFrame(symbol, 0, path)
    raise ValueError(f"generated assembly is missing the {symbol} entry or its zero-frame driver stub")


def polygon_call_path_bytes(poly_frame: int, transform_frame: int,
                            draw_poly_frame: int) -> tuple[int, int, int]:
    """Return the polygon frame plus its deepest generated child call path."""
    transform_path = (transform_frame + TRANSFORM_VECTOR_ARGUMENT_BYTES +
                      CALL_BYTES)
    draw_poly_path = draw_poly_frame + CALL_BYTES
    return (poly_frame + POLY_ARGUMENT_BYTES + CALL_BYTES +
            max(transform_path, draw_poly_path), transform_path, draw_poly_path)


def nested_callback_cost(frames: dict[str, list[FunctionFrame]], helper: str,
                         target: str, target_argument_bytes: int) -> int:
    helper_frame = choose_frame(frames, [helper], helper).frame_bytes
    target_frame = choose_frame(frames, [target], target).frame_bytes
    # The owner calls helper, then helper calls target. Count both return
    # addresses and target arguments as well as both generated frames.
    return helper_frame + CALL_BYTES + target_argument_bytes + CALL_BYTES + target_frame


def check(object_root: Path, *, asm_frame_control: bool, asm_edge: bool,
          asm_world: bool, asm_poly: bool, asm_clip: bool,
          asm_bsp_walk: bool, instrumented: bool) -> dict[str, int]:
    frames = load_frames(object_root)
    view = choose_frame(frames, ["_R_RenderView_"], "R_RenderView_")
    edge = choose_frame(frames,
                        ["_R_EdgeDrawing_asm486"] if asm_edge else ["_R_EdgeDrawing_C", "_R_EdgeDrawing"],
                        "R_EdgeDrawing")
    world = choose_frame(frames,
                         ["_R_RenderWorld_asm486"] if asm_world else ["_R_RenderWorld_C", "_R_RenderWorld"],
                         "R_RenderWorld")
    poly = choose_frame(frames,
                        ["_R_RenderPoly_asm486"] if asm_poly else ["_R_RenderPoly_C", "_R_RenderPoly"],
                        "R_RenderPoly")
    transform = choose_frame(frames, ["_TransformVector"], "TransformVector")
    draw_poly_candidates = frames.get("_D_DrawPoly", [])
    draw_poly = (max(draw_poly_candidates, key=lambda item: item.frame_bytes)
                 if draw_poly_candidates else
                 choose_driver_noop(object_root, "_D_DrawPoly"))
    clip = choose_frame(frames,
                        ["_R_RecursiveClipBPoly_asm486"] if asm_clip else ["_R_RecursiveClipBPoly_C", "_R_RecursiveClipBPoly"],
                        "recursive clipped-bmodel")
    if asm_bsp_walk:
        world_walk = choose_frame(frames, ["_R_RecursiveWorldNode_asm486"],
                                  "iterative BSP world walk")
        world_walk_clip = choose_frame(frames,
                                       ["_R_RecursiveWorldNodeClip_asm486"],
                                       "iterative BSP world-walk clip helper")
        world_walk_record, world_walk_record_path = choose_equate(
            object_root, WORLD_WALK_RECORD_EQUATE)
        world_walk_fixed = WORLD_WALK_FIXED_FRAME_BYTES + CALL_BYTES
        world_walk_step = (world_walk_record + world_walk_clip.frame_bytes +
                           CALL_BYTES + WORLD_WALK_CLIP_ARGUMENT_BYTES)
    else:
        world_walk = choose_frame(frames,
                                  ["_R_RecursiveWorldNode_C", "_R_RecursiveWorldNode"],
                                  "recursive BSP world walk")
        world_walk_record = 0
        world_walk_record_path = world_walk.path
        world_walk_clip = world_walk
        world_walk_fixed = 0
        # R_RecursiveWorldNode uses regparm(2), so its node and clip flags are
        # passed in registers. Each nested C call contributes its return word.
        world_walk_step = world_walk.frame_bytes + CALL_BYTES
    fallback = choose_frame(frames, ["_R_RenderViewStackFallback"], "warp fallback")
    dispatch = choose_frame(frames, ["_R_RenderViewDispatch"], "renderer dispatch")
    requirement = choose_frame(frames, ["_R_RenderStackRequirement"], "normal stack requirement")

    expected_view = 40 if instrumented else 12
    expected_edge = (128224 if instrumented else 128176) if asm_edge else (128160 if instrumented else 128108)
    expected_world = (40068 if instrumented else 40020) if asm_world else (40056 if instrumented else 40012)
    expected_step = (136 if instrumented else 128) if asm_clip else (136 if instrumented else 124)
    measured_poly_path, transform_call_path, draw_poly_call_path = polygon_call_path_bytes(
        poly.frame_bytes, transform.frame_bytes, draw_poly.frame_bytes)
    measured_step = clip.frame_bytes + 16

    checks = {
        "R_RenderView_": (view.frame_bytes, expected_view),
        "R_EdgeDrawing": (edge.frame_bytes, expected_edge),
        "R_RenderWorld": (world.frame_bytes, expected_world),
        "R_RenderPoly path": (measured_poly_path, POLY_CALL_PATH_BYTES),
        "recursive clipped-bmodel step": (measured_step, expected_step),
        "warp fallback frame": (fallback.frame_bytes, FALLBACK_FRAME_BYTES),
        "R_RenderViewDispatch preflight": (dispatch.frame_bytes, MAX_PRECHECK_FRAME_BYTES),
        "R_RenderStackRequirement preflight": (requirement.frame_bytes, MAX_PRECHECK_FRAME_BYTES),
    }
    failed = [(name, measured, budget) for name, (measured, budget) in checks.items() if measured > budget]
    if failed:
        details = "; ".join(f"{name} uses {measured} bytes (budget {budget})" for name, measured, budget in failed)
        raise ValueError(f"renderer stack budget failed: {details}")

    if fallback.frame_bytes != FALLBACK_FRAME_BYTES:
        raise ValueError(f"warp fallback frame changed from pinned {FALLBACK_FRAME_BYTES} to {fallback.frame_bytes} bytes")

    if measured_step != expected_step:
        raise ValueError(f"clipped-bmodel recursion uses {measured_step} bytes per level (budget {expected_step})")
    if world_walk_step > expected_step:
        raise ValueError(
            f"world BSP traversal uses {world_walk_step} bytes per depth "
                f"(clipped-bmodel tree-step budget {expected_step})")
    if asm_bsp_walk and world_walk.frame_bytes > WORLD_WALK_FIXED_FRAME_BYTES:
        raise ValueError(
            f"iterative BSP walk frame uses {world_walk.frame_bytes} bytes "
            f"(budget {WORLD_WALK_FIXED_FRAME_BYTES})")

    # Instrumentation adds direct callbacks while the large edge/world frames
    # are live. Bound the generated callback paths too, rather than adding an
    # undocumented blanket reserve to the runtime requirement.
    edge_callback = 0
    world_callback = 0
    if instrumented:
        if asm_edge:
            edge_callbacks = [
                ("_R_EdgeDrawingProfileEnter_asm486", "_Bench486ProfileEnter", 4),
                ("_R_EdgeDrawingProfileLeave_asm486", "_Bench486ProfileLeave", 0),
                ("_R_EdgeDrawingProfileWorldStart_asm486", "_Sys_FloatTime", 0),
                ("_R_EdgeDrawingProfileWorldEnd_asm486", "_Sys_FloatTime", 0),
                ("_R_EdgeDrawingProfileBrushEnter_asm486", "_Bench486ProfileEnter", 4),
                ("_R_EdgeDrawingProfileBrushLeave_asm486", "_Bench486ProfileWork", 12),
            ]
            edge_callback = max(nested_callback_cost(frames, *entry) for entry in edge_callbacks)
        else:
            edge_callback = max(
                choose_frame(frames, ["_Bench486ProfileEnter"], "profile enter").frame_bytes + 8,
                choose_frame(frames, ["_Bench486ProfileWork"], "profile work").frame_bytes + 16,
                choose_frame(frames, ["_Bench486ProfileLeave"], "profile leave").frame_bytes + 4,
            )

        if asm_world:
            world_callbacks = [
                ("_R_RenderWorldProfileEnter_asm486", "_Bench486ProfileEnter", 4),
                ("_R_RenderWorldProfileWork_asm486", "_Bench486ProfileWork", 12),
                ("_R_RenderWorldProfileLeave_asm486", "_Bench486ProfileLeave", 0),
            ]
            world_callback = max(nested_callback_cost(frames, *entry) for entry in world_callbacks)
        else:
            world_callback = max(
                choose_frame(frames, ["_Bench486ProfileEnter"], "profile enter").frame_bytes + 8,
                choose_frame(frames, ["_Bench486ProfileWork"], "profile work").frame_bytes + 16,
                choose_frame(frames, ["_Bench486ProfileLeave"], "profile leave").frame_bytes + 4,
            )

        if edge.frame_bytes + edge_callback > expected_edge:
            raise ValueError(f"instrumented edge frame and callback path use {edge.frame_bytes + edge_callback} bytes (budget {expected_edge})")
        if world.frame_bytes + world_callback > expected_world:
            raise ValueError(f"instrumented world frame and callback path use {world.frame_bytes + world_callback} bytes (budget {expected_world})")

    # Two call returns remain through view->edge and edge->world. A third is
    # charged for the dispatcher callback so the no-warp call path remains
    # covered even when other compiled branches become tail jumps.
    normal_fixed = (view.frame_bytes + expected_edge + expected_world +
                    POLY_CALL_PATH_BYTES + 3 * CALL_BYTES + world_walk_fixed)
    warp_fixed = normal_fixed + FALLBACK_FRAME_BYTES + CALL_BYTES
    return {
        "normalFixedBytes": normal_fixed,
        "normalTreeStepBytes": expected_step,
        "warpFallbackFixedBytes": warp_fixed,
        "warpTreeStepBytes": expected_step,
        "renderViewFrameBytes": view.frame_bytes,
        "edgeFrameBytes": expected_edge,
        "worldFrameBytes": expected_world,
        "worldTraversalFrameBytes": world_walk.frame_bytes,
        "worldTraversalFixedBytes": world_walk_fixed,
        "worldTraversalStepBytes": world_walk_step,
        "worldTraversalRecordBytes": world_walk_record,
        "worldTraversalRecordPath": str(world_walk_record_path),
        "worldTraversalClipFrameBytes": world_walk_clip.frame_bytes,
        "renderPolyFrameBytes": poly.frame_bytes,
        "transformVectorFrameBytes": transform.frame_bytes,
        "transformVectorCallPathBytes": transform_call_path,
        "drawPolyFrameBytes": draw_poly.frame_bytes,
        "drawPolyCallPathBytes": draw_poly_call_path,
        "polygonPathBytes": POLY_CALL_PATH_BYTES,
        "measuredPolygonPathBytes": measured_poly_path,
        "recursiveStepBytes": expected_step,
        "fallbackFrameBytes": FALLBACK_FRAME_BYTES,
        "edgeProfileCallbackBytes": edge_callback,
        "worldProfileCallbackBytes": world_callback,
        "asmFrameControl": int(asm_frame_control),
    }


def self_test() -> None:
    lines = [
        ".equ LOCAL_BYTES, 128000",
        ".globl _TestFrame",
        "_TestFrame:",
        "pushl %ebp",
        "movl %esp,%ebp",
        "subl $LOCAL_BYTES,%esp",
        "movl %eax,%ebx",
    ]
    frame = _function_frame(lines, 2, "_TestFrame", Path("synthetic.s"),
                            _resolve_equates(lines))
    if frame.frame_bytes != 128004:
        raise ValueError(f"assembly-frame parser self-test expected 128004, got {frame.frame_bytes}")
    poly_path, transform_path, draw_poly_path = polygon_call_path_bytes(4624, 0, 0)
    if (poly_path, transform_path, draw_poly_path) != (4648, 12, 4):
        raise ValueError("polygon-call model self-test did not preserve the 4648-byte path")
    print("renderer stack budget parser self-test: PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--object-root", type=Path)
    parser.add_argument("--asm-frame-control", action="store_true")
    parser.add_argument("--asm-edge", action="store_true")
    parser.add_argument("--asm-world", action="store_true")
    parser.add_argument("--asm-poly", action="store_true")
    parser.add_argument("--asm-clip", action="store_true")
    parser.add_argument("--asm-bsp-walk", action="store_true")
    parser.add_argument("--instrumented", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
            return 0
        if args.object_root is None:
            parser.error("--object-root is required unless --self-test is used")
        report = check(args.object_root, asm_frame_control=args.asm_frame_control,
                       asm_edge=args.asm_edge, asm_world=args.asm_world,
                       asm_poly=args.asm_poly, asm_clip=args.asm_clip,
                       asm_bsp_walk=args.asm_bsp_walk,
                       instrumented=args.instrumented)
        print("renderer stack budget: PASS")
        print("  normal renderer: {normalFixedBytes} + {normalTreeStepBytes} * world_depth bytes".format(**report))
        print("  warp fallback: {warpFallbackFixedBytes} + {warpTreeStepBytes} * world_depth bytes".format(**report))
        print("  generated frames: view={renderViewFrameBytes}, edge={edgeFrameBytes}, world={worldFrameBytes}, polygon-path={measuredPolygonPathBytes} (budget {polygonPathBytes}), fallback={fallbackFrameBytes}".format(**report))
        print("  world traversal: frame={worldTraversalFrameBytes}, fixed-with-call={worldTraversalFixedBytes}, path-per-depth={worldTraversalStepBytes}".format(**report))
        print("  polygon traversal: R_RenderPoly={renderPolyFrameBytes}, TransformVector path={transformVectorCallPathBytes}, D_DrawPoly path={drawPolyCallPathBytes}".format(**report))
        if args.asm_bsp_walk:
            print("  world continuation record: {worldTraversalRecordBytes} bytes ({worldTraversalRecordPath})".format(**report))
        if args.instrumented:
            print("  profile callback paths: edge={edgeProfileCallbackBytes}, world={worldProfileCallbackBytes} bytes".format(**report))
        return 0
    except (OSError, ValueError, SyntaxError) as error:
        print(f"renderer stack budget: FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
