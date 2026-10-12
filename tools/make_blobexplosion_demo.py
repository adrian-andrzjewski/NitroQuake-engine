#!/usr/bin/env python3
"""Create a short Quake demo with one selected server event.

The source demo is read in-place from a PACK archive. Only the requested
prefix is copied into the output demo, so this does not duplicate game data.
See --help for the relationship between PACK records and timedemo frames.
"""

from __future__ import annotations

import argparse
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO, Iterable


PAK_HEADER_BYTES = 12
PAK_ENTRY_BYTES = 64
PAK_NAME_BYTES = 56
MAX_MSGLEN = 8000  # Quake's MAX_MSGLEN
SVC_TEMP_ENTITY = 23
SVC_DAMAGE = 19
SVC_PARTICLE = 18
SVC_DISCONNECT = 2
SVC_DAMAGE_ARMOR = 24
SVC_DAMAGE_BLOOD = 48
TE_TAREXPLOSION = 4
TE_WIZSPIKE = 7
TE_LAVASPLASH = 10
TE_TELEPORT = 11
SUPPORTED_TEMP_ENTITY_EVENTS = (TE_TAREXPLOSION, TE_WIZSPIKE, TE_LAVASPLASH, TE_TELEPORT)
SUPPORTED_DEMO_EVENTS = SUPPORTED_TEMP_ENTITY_EVENTS + (SVC_PARTICLE, SVC_DAMAGE)
MAX_DEMO_TRACK_LINE = 128


@dataclass(frozen=True)
class PackMember:
    offset: int
    length: int


@dataclass(frozen=True)
class FixtureInfo:
    source_member: str
    source_records: int
    first_post_signon_record: int
    kept_post_signon_records: int
    event_record: int
    event_type: int
    output_bytes: int


def _read_exact(stream: BinaryIO, length: int, label: str) -> bytes:
    data = stream.read(length)
    if len(data) != length:
        raise ValueError(f"truncated {label}: expected {length} bytes, got {len(data)}")
    return data


def _normalise_member_name(name: str) -> str:
    return name.replace("\\", "/").lstrip("/").casefold()


def find_pack_member(pak_path: Path, member_name: str) -> PackMember:
    """Find a member in an uncompressed Quake PACK archive without extracting it."""
    archive_size = pak_path.stat().st_size
    with pak_path.open("rb") as pak:
        header = _read_exact(pak, PAK_HEADER_BYTES, "PACK header")
        if header[:4] != b"PACK":
            raise ValueError(f"{pak_path} is not a Quake PACK archive")
        directory_offset, directory_length = struct.unpack_from("<ii", header, 4)
        directory_end = directory_offset + directory_length
        if (
            directory_offset < PAK_HEADER_BYTES
            or directory_length <= 0
            or directory_length % PAK_ENTRY_BYTES
            or directory_end > archive_size
        ):
            raise ValueError(f"{pak_path} has an invalid PACK directory range")

        wanted = _normalise_member_name(member_name)
        pak.seek(directory_offset)
        for _ in range(directory_length // PAK_ENTRY_BYTES):
            entry = _read_exact(pak, PAK_ENTRY_BYTES, "PACK directory entry")
            raw_name = entry[:PAK_NAME_BYTES].split(b"\0", 1)[0]
            try:
                name = raw_name.decode("ascii")
            except UnicodeDecodeError as error:
                raise ValueError("PACK member name is not ASCII") from error
            offset, length = struct.unpack_from("<ii", entry, PAK_NAME_BYTES)
            end = offset + length
            overlaps_directory = offset < directory_end and end > directory_offset
            if (
                offset < PAK_HEADER_BYTES
                or length < 0
                or end > archive_size
                or overlaps_directory
            ):
                raise ValueError(f"PACK member {name!r} has an invalid data range")
            if _normalise_member_name(name) == wanted:
                return PackMember(offset, length)

    raise ValueError(f"PACK member {member_name!r} was not found in {pak_path}")


def _read_track_line(stream: BinaryIO, remaining: int) -> tuple[bytes, int]:
    line = bytearray()
    while len(line) < MAX_DEMO_TRACK_LINE:
        if remaining <= 0:
            raise ValueError("demo member ends before its force-track line")
        byte = _read_exact(stream, 1, "demo force-track line")
        line.extend(byte)
        remaining -= 1
        if byte == b"\n":
            break
    else:
        raise ValueError("demo force-track line is too long")

    try:
        track_text = bytes(line[:-1]).decode("ascii")
        int(track_text, 10)
    except (UnicodeDecodeError, ValueError) as error:
        raise ValueError("demo has an invalid force-track line") from error
    return bytes(line), remaining


def _encode_demo_event(event_type: int, coord_shorts: Iterable[int]) -> bytes:
    coords = tuple(coord_shorts)
    if len(coords) != 3:
        raise ValueError("exactly three coordinate shorts are required")
    for coord in coords:
        if not -32768 <= coord <= 32767:
            raise ValueError(f"coordinate short {coord} is outside signed 16-bit range")

    if event_type == SVC_DAMAGE:
        # svc_damage is opcode, armor byte, blood byte, then three protocol coords.
        # Keep the damage magnitudes fixed so paired renderer runs receive identical
        # damage-feedback state and the fixture remains byte-for-byte deterministic.
        return bytes((SVC_DAMAGE, SVC_DAMAGE_ARMOR, SVC_DAMAGE_BLOOD)) + struct.pack(
            "<hhh", *coords
        )
    if event_type == SVC_PARTICLE:
        # svc_particle carries three protocol coords, three signed direction
        # bytes, count and color. Use the 255 sentinel (1024 particles) and
        # high-bit signed directions to exercise the assembly parser in-game.
        return bytes((SVC_PARTICLE,)) + struct.pack("<hhh", *coords) + bytes(
            (0x80, 0x7F, 0xFF, 255, 0xE1)
        )
    if event_type not in SUPPORTED_TEMP_ENTITY_EVENTS:
        raise ValueError(f"unsupported temp-entity type {event_type}")
    return bytes((SVC_TEMP_ENTITY, event_type)) + struct.pack("<hhh", *coords)


def create_blob_demo(
    pak_path: Path,
    output_path: Path,
    *,
    member_name: str,
    first_post_signon_record: int,
    keep_post_signon_records: int,
    event_record: int,
    event_type: int = TE_TAREXPLOSION,
    coord_shorts: Iterable[int] = (0, 0, 0),
) -> FixtureInfo:
    """Write the source demo through a selected post-signon prefix.

    Record indices are zero-based physical .dem records. The caller supplies
    the first record fetched after `cls.signon == SIGNONS` becomes true. The
    retained records are a consecutive prefix beginning there; `event_record`
    is an absolute, zero-based source record index within that prefix. The event
    is appended without parsing or rewriting the selected message. A separate
    one-byte `svc_disconnect` packet follows the prefix, matching the original
    demo's termination and exercising Quake's normal timedemo finish path.
    """
    if first_post_signon_record < 0:
        raise ValueError("first post-signon record must be non-negative")
    if keep_post_signon_records <= 0:
        raise ValueError("at least one post-signon record must be retained")
    end_record = first_post_signon_record + keep_post_signon_records
    if not first_post_signon_record <= event_record < end_record:
        raise ValueError("event record must fall inside the retained post-signon prefix")
    if pak_path.resolve() == output_path.resolve():
        raise ValueError("demo output path must not be the source PACK archive")
    if output_path.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {output_path}")

    event_bytes = _encode_demo_event(event_type, coord_shorts)
    member = find_pack_member(pak_path, member_name)
    source_records = 0
    written_bytes = 0
    output_created = False
    last_angles = None

    try:
        with pak_path.open("rb") as pak:
            pak.seek(member.offset)
            remaining = member.length
            track_line, remaining = _read_track_line(pak, remaining)
            with output_path.open("xb") as output:
                output_created = True
                output.write(track_line)
                written_bytes += len(track_line)
                for record_index in range(end_record):
                    if remaining < 4:
                        raise ValueError(f"demo member ends before record {record_index}")
                    length_bytes = _read_exact(pak, 4, f"demo record {record_index} length")
                    remaining -= 4
                    message_length = struct.unpack("<i", length_bytes)[0]
                    if message_length < 0 or message_length > MAX_MSGLEN:
                        raise ValueError(
                            f"demo record {record_index} has invalid message length {message_length}"
                        )
                    if remaining < 12 + message_length:
                        raise ValueError(f"demo record {record_index} exceeds its PACK member")
                    angles = _read_exact(pak, 12, f"demo record {record_index} view angles")
                    last_angles = angles
                    payload = _read_exact(pak, message_length, f"demo record {record_index} message")
                    remaining -= 12 + message_length
                    source_records += 1

                    if record_index == event_record:
                        payload += event_bytes
                        if len(payload) > MAX_MSGLEN:
                            raise ValueError(
                                f"event would grow demo record {record_index} beyond MAX_MSGLEN"
                            )
                        length_bytes = struct.pack("<i", len(payload))

                    output.write(length_bytes)
                    output.write(angles)
                    output.write(payload)
                    written_bytes += 16 + len(payload)

                if last_angles is None:
                    raise ValueError("demo fixture must retain at least one source record")
                disconnect = bytes((SVC_DISCONNECT,))
                output.write(struct.pack("<i", len(disconnect)))
                output.write(last_angles)
                output.write(disconnect)
                written_bytes += 16 + len(disconnect)
    except Exception:
        if output_created:
            try:
                output_path.unlink()
            except OSError:
                pass
        raise

    return FixtureInfo(
        source_member=member_name,
        source_records=source_records,
        first_post_signon_record=first_post_signon_record,
        kept_post_signon_records=keep_post_signon_records,
        event_record=event_record,
        event_type=event_type,
        output_bytes=written_bytes,
    )


def create_override_pak(demo_path: Path, pak_output_path: Path, member_name: str) -> int:
    """Wrap a short demo in a one-member PACK archive for pak2-style overrides."""
    encoded_name = member_name.replace("\\", "/").lstrip("/").encode("ascii")
    if not encoded_name or len(encoded_name) >= PAK_NAME_BYTES or b"\0" in encoded_name:
        raise ValueError("override member name must be 1..55 ASCII bytes")
    if demo_path.resolve() == pak_output_path.resolve():
        raise ValueError("PACK output path must differ from the demo path")
    if pak_output_path.exists():
        raise FileExistsError(f"refusing to overwrite existing output: {pak_output_path}")

    data_length = demo_path.stat().st_size
    if data_length > 0x7FFFFFFF:
        raise ValueError("demo is too large for the signed 32-bit PACK format")
    directory_offset = PAK_HEADER_BYTES + data_length
    directory = bytearray(PAK_ENTRY_BYTES)
    directory[: len(encoded_name)] = encoded_name
    struct.pack_into("<ii", directory, PAK_NAME_BYTES, PAK_HEADER_BYTES, data_length)
    pak_created = False
    try:
        with pak_output_path.open("xb") as pak:
            pak_created = True
            pak.write(struct.pack("<4sii", b"PACK", directory_offset, PAK_ENTRY_BYTES))
            with demo_path.open("rb") as demo:
                while True:
                    block = demo.read(64 * 1024)
                    if not block:
                        break
                    pak.write(block)
            pak.write(directory)
    except Exception:
        if pak_created:
            try:
                pak_output_path.unlink()
            except OSError:
                pass
        raise
    return PAK_HEADER_BYTES + data_length + PAK_ENTRY_BYTES


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Extract a short prefix from a demo stored inside pak0.pak and append "
            "one supported Quake server message to a chosen record."
        ),
        epilog=(
            "CL_GetMessage reads one demo record at most once per host frame after "
            "cls.signon reaches SIGNONS (cl_demo.c). The supplied first-record index "
            "is therefore the zero-based physical record immediately after the record "
            "that completes signon. `event-record` is an absolute packet/record index, "
            "not CL_FinishTimeDemo's reported frame count: that count subtracts one "
            "warm-up frame. The frame checksum/event instrumentation has its own "
            "zero-based rendered-frame counter. Coordinates are signed protocol "
            "shorts in eighths of a Quake world unit (MSG_ReadCoord multiplies by 1/8)."
        ),
    )
    parser.add_argument("--pak0", required=True, type=Path, help="source pak0.pak")
    parser.add_argument("--output", required=True, type=Path, help="new .dem output path")
    parser.add_argument(
        "--member", default="demo2.dem", help="demo member name inside pak0 (default: %(default)s)"
    )
    parser.add_argument(
        "--first-post-signon-record",
        required=True,
        type=int,
        help="zero-based source record index immediately after the signon-completing record",
    )
    parser.add_argument(
        "--keep-post-signon-records",
        required=True,
        type=int,
        help="number of consecutive post-signon records to keep",
    )
    parser.add_argument(
        "--event-record",
        required=True,
        type=int,
        help="absolute zero-based source record index within the retained post-signon prefix",
    )
    parser.add_argument(
        "--event-type",
        type=int,
        choices=SUPPORTED_DEMO_EVENTS,
        default=TE_TAREXPLOSION,
        help=(
            "Quake event type (4=TAREXPLOSION, 7=WIZSPIKE, 10=LAVASPLASH, "
            "11=TELEPORT, 18=svc_particle with fixed signed directions/count/color, "
            "19=svc_damage with fixed armor=24/blood=48; "
            "default: %(default)s)"
        ),
    )
    parser.add_argument(
        "--coord-shorts",
        nargs=3,
        type=int,
        metavar=("X", "Y", "Z"),
        default=(0, 0, 0),
        help="signed protocol coord shorts (1/8 world-unit); default: 0 0 0",
    )
    parser.add_argument(
        "--pak-output",
        type=Path,
        help="optional tiny one-member PACK override, typically a pak2.pak output path",
    )
    parser.add_argument(
        "--pak-entry",
        default="demo2.dem",
        help="member name in --pak-output (default: %(default)s)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(sys.argv[1:] if argv is None else argv)
    if args.pak_output and args.pak_output.resolve() in {
        args.pak0.resolve(),
        args.output.resolve(),
    }:
        raise ValueError("PACK output must differ from both source archive and demo output")
    info = create_blob_demo(
        args.pak0,
        args.output,
        member_name=args.member,
        first_post_signon_record=args.first_post_signon_record,
        keep_post_signon_records=args.keep_post_signon_records,
        event_record=args.event_record,
        event_type=args.event_type,
        coord_shorts=args.coord_shorts,
    )
    if args.pak_output:
        try:
            pack_bytes = create_override_pak(args.output, args.pak_output, args.pak_entry)
        except Exception:
            args.output.unlink(missing_ok=True)
            raise
        print(f"PACK override: {args.pak_output} ({pack_bytes} bytes; {args.pak_entry})")
    print(
        f"Demo fixture: {args.output} ({info.output_bytes} bytes; "
        f"{info.source_records} records; event type {info.event_type} at source record {info.event_record})"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
