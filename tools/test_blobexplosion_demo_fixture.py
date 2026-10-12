"""Format-level tests for deterministic Quake server-event demo fixtures."""

from __future__ import annotations

import json
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_blobexplosion_demo as fixture  # noqa: E402


MEMBER_NAME = "demo2.dem"
TOOLS = Path(__file__).resolve().parent


def make_demo(records: list[tuple[bytes, bytes]]) -> bytes:
    output = bytearray(b"-1\n")
    for payload, angles in records:
        if len(angles) != 12:
            raise ValueError("test angle block must be 12 bytes")
        output.extend(struct.pack("<i", len(payload)))
        output.extend(angles)
        output.extend(payload)
    return bytes(output)


def make_pak(path: Path, member_name: str, data: bytes) -> None:
    encoded_name = member_name.encode("ascii")
    if len(encoded_name) >= fixture.PAK_NAME_BYTES:
        raise ValueError("test member name too long")
    directory_offset = fixture.PAK_HEADER_BYTES + len(data)
    directory_entry = bytearray(fixture.PAK_ENTRY_BYTES)
    directory_entry[: len(encoded_name)] = encoded_name
    struct.pack_into("<ii", directory_entry, fixture.PAK_NAME_BYTES,
                     fixture.PAK_HEADER_BYTES, len(data))
    path.write_bytes(
        struct.pack("<4sii", b"PACK", directory_offset, fixture.PAK_ENTRY_BYTES)
        + data
        + directory_entry
    )


def read_demo(path: Path) -> tuple[bytes, list[tuple[bytes, bytes]]]:
    data = path.read_bytes()
    line_end = data.index(b"\n") + 1
    track_line = data[:line_end]
    cursor = line_end
    records = []
    while cursor < len(data):
        if cursor + 16 > len(data):
            raise AssertionError("truncated test output record")
        length = struct.unpack_from("<i", data, cursor)[0]
        cursor += 4
        angles = data[cursor : cursor + 12]
        cursor += 12
        payload = data[cursor : cursor + length]
        if len(payload) != length:
            raise AssertionError("truncated test output payload")
        cursor += length
        records.append((payload, angles))
    return track_line, records


class BlobExplosionDemoFixtureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="blob-demo-fixture-")
        self.root = Path(self.temp.name)
        self.pak0 = self.root / "pak0.pak"
        self.source_records = [
            (bytes((0x10 + index,)), struct.pack("<fff", index + 0.25, 2.5, -3.0))
            for index in range(6)
        ]
        self.source_demo = make_demo(self.source_records)
        make_pak(self.pak0, MEMBER_NAME, self.source_demo)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_supported_event_values_match_quake_protocol(self) -> None:
        protocol = (TOOLS.parent / "src" / "protocol.h").read_text(encoding="utf-8")
        for name, value in (
            ("TE_TAREXPLOSION", fixture.TE_TAREXPLOSION),
            ("TE_WIZSPIKE", fixture.TE_WIZSPIKE),
            ("TE_LAVASPLASH", fixture.TE_LAVASPLASH),
            ("TE_TELEPORT", fixture.TE_TELEPORT),
            ("svc_particle", fixture.SVC_PARTICLE),
            ("svc_damage", fixture.SVC_DAMAGE),
        ):
            with self.subTest(event=name):
                match = re.search(rf"(?m)^#define\s+{name}\s+(\d+)\b", protocol)
                self.assertIsNotNone(match, f"missing {name} in src/protocol.h")
                assert match is not None
                self.assertEqual(value, int(match.group(1)))

    def test_preserves_signon_and_selected_post_signon_prefix_and_wraps_pak(self) -> None:
        output = self.root / "short.dem"
        info = fixture.create_blob_demo(
            self.pak0,
            output,
            member_name=MEMBER_NAME,
            first_post_signon_record=2,
            keep_post_signon_records=3,
            event_record=3,
            coord_shorts=(-8, 0, 32767),
        )

        track_line, result = read_demo(output)
        self.assertEqual(track_line, b"-1\n")
        self.assertEqual(len(result), 6)
        self.assertEqual(info.source_records, 5)
        self.assertEqual(info.event_record, 3)
        self.assertEqual(result[0], self.source_records[0])
        self.assertEqual(result[1], self.source_records[1])
        self.assertEqual(result[2], self.source_records[2])
        self.assertEqual(result[3][1], self.source_records[3][1])
        self.assertEqual(
            result[3][0],
            self.source_records[3][0] + bytes((fixture.SVC_TEMP_ENTITY, fixture.TE_TAREXPLOSION))
            + struct.pack("<hhh", -8, 0, 32767),
        )
        self.assertEqual(result[4], self.source_records[4])
        self.assertEqual(result[5], (bytes((fixture.SVC_DISCONNECT,)), self.source_records[4][1]))
        self.assertEqual(info.output_bytes, output.stat().st_size)
        self.assertEqual(info.event_type, fixture.TE_TAREXPLOSION)

        override = self.root / "pak2.pak"
        expected_size = fixture.create_override_pak(output, override, MEMBER_NAME)
        self.assertEqual(override.stat().st_size, expected_size)
        self.assertEqual(fixture.find_pack_member(override, MEMBER_NAME).length, output.stat().st_size)
        with override.open("rb") as pack:
            member = fixture.find_pack_member(override, MEMBER_NAME)
            pack.seek(member.offset)
            self.assertEqual(pack.read(member.length), output.read_bytes())

    def test_rejects_invalid_event_selection_and_coordinate_short(self) -> None:
        output = self.root / "invalid.dem"
        with self.assertRaisesRegex(ValueError, "inside the retained post-signon prefix"):
            fixture.create_blob_demo(
                self.pak0,
                output,
                member_name=MEMBER_NAME,
                first_post_signon_record=2,
                keep_post_signon_records=2,
                event_record=4,
            )
        with self.assertRaisesRegex(ValueError, "signed 16-bit"):
            fixture.create_blob_demo(
                self.pak0,
                output,
                member_name=MEMBER_NAME,
                first_post_signon_record=2,
                keep_post_signon_records=2,
                event_record=2,
                coord_shorts=(0, 0, 32768),
            )
        with self.assertRaisesRegex(ValueError, "unsupported temp-entity type"):
            fixture.create_blob_demo(
                self.pak0,
                output,
                member_name=MEMBER_NAME,
                first_post_signon_record=2,
                keep_post_signon_records=2,
                event_record=2,
                event_type=12,
            )
        self.assertFalse(output.exists())

    def test_injects_exact_lavasplash_message_bytes(self) -> None:
        output = self.root / "lavasplash.dem"
        info = fixture.create_blob_demo(
            self.pak0,
            output,
            member_name=MEMBER_NAME,
            first_post_signon_record=2,
            keep_post_signon_records=3,
            event_record=3,
            event_type=fixture.TE_LAVASPLASH,
            coord_shorts=(-2136, 17413, 9968),
        )

        _, result = read_demo(output)
        expected = bytes((fixture.SVC_TEMP_ENTITY, fixture.TE_LAVASPLASH))
        expected += struct.pack("<hhh", -2136, 17413, 9968)
        self.assertEqual(info.event_type, fixture.TE_LAVASPLASH)
        self.assertEqual(result[3][0], self.source_records[3][0] + expected)
        self.assertEqual(result[-1][0], bytes((fixture.SVC_DISCONNECT,)))

    def test_injects_exact_svc_damage_message_bytes(self) -> None:
        output = self.root / "svcdamage.dem"
        info = fixture.create_blob_demo(
            self.pak0,
            output,
            member_name=MEMBER_NAME,
            first_post_signon_record=2,
            keep_post_signon_records=3,
            event_record=3,
            event_type=fixture.SVC_DAMAGE,
            coord_shorts=(-2136, 17413, 9968),
        )

        _, result = read_demo(output)
        expected = bytes((
            fixture.SVC_DAMAGE,
            fixture.SVC_DAMAGE_ARMOR,
            fixture.SVC_DAMAGE_BLOOD,
        )) + struct.pack("<hhh", -2136, 17413, 9968)
        self.assertEqual(info.event_type, fixture.SVC_DAMAGE)
        self.assertEqual(result[3][0], self.source_records[3][0] + expected)
        self.assertEqual(result[-1][0], bytes((fixture.SVC_DISCONNECT,)))

    def test_injects_exact_svc_particle_packet_bytes(self) -> None:
        output = self.root / "svc-particle.dem"
        info = fixture.create_blob_demo(
            self.pak0,
            output,
            member_name=MEMBER_NAME,
            first_post_signon_record=2,
            keep_post_signon_records=3,
            event_record=3,
            event_type=fixture.SVC_PARTICLE,
            coord_shorts=(-2136, 17413, 9968),
        )

        _, result = read_demo(output)
        expected = bytes((fixture.SVC_PARTICLE,))
        expected += struct.pack("<hhh", -2136, 17413, 9968)
        expected += bytes((0x80, 0x7F, 0xFF, 255, 0xE1))
        self.assertEqual(info.event_type, fixture.SVC_PARTICLE)
        self.assertEqual(result[3][0], self.source_records[3][0] + expected)
        self.assertEqual(result[-1][0], bytes((fixture.SVC_DISCONNECT,)))

    def test_cli_accepts_svc_damage_selector(self) -> None:
        args = fixture._parse_args(
            [
                "--pak0", "pak0.pak",
                "--output", "svcdamage.dem",
                "--first-post-signon-record", "4",
                "--keep-post-signon-records", "11",
                "--event-record", "14",
                "--event-type", "19",
            ]
        )
        self.assertEqual(args.event_type, fixture.SVC_DAMAGE)

    def test_svc_damage_scenario_targets_the_dispatched_event_frame(self) -> None:
        profile = json.loads((TOOLS / "render-scenarios-svcdamage.json").read_text(encoding="utf-8"))
        self.assertEqual(len(profile["scenarios"]), 1)
        scenario = profile["scenarios"][0]
        self.assertIn("svcDamage", scenario["id"])
        self.assertEqual(scenario["expectedFrames"], 10)
        self.assertEqual(scenario["captureFrame"], 10)
        self.assertEqual(scenario["repeatRuns"], 2)
        self.assertEqual(scenario["requiredBenchEvents"], ["svcDamage"])
        self.assertEqual(scenario["expectedBenchEventFrames"], {"svcDamage": [10]})
        self.assertEqual(scenario["captureBenchEvents"], ["svcDamage"])
        self.assertIsNone(scenario["reference"])

        fixture_config = scenario["demoFixture"]
        self.assertEqual(fixture_config["sourceMember"], "demo2.dem")
        self.assertEqual(fixture_config["firstPostSignonRecord"], 4)
        self.assertEqual(fixture_config["keepPostSignonRecords"], 11)
        self.assertEqual(fixture_config["eventRecord"], 14)
        self.assertEqual(fixture_config["eventType"], fixture.SVC_DAMAGE)
        self.assertEqual(fixture_config["coordShorts"], [-2136, 17413, 9968])
        self.assertEqual(fixture_config["pakEntry"], "demo2.dem")
        self.assertEqual(fixture.SVC_DAMAGE_ARMOR, 24)
        self.assertEqual(fixture.SVC_DAMAGE_BLOOD, 48)

    def test_injects_exact_teleport_message_bytes(self) -> None:
        output = self.root / "teleport.dem"
        info = fixture.create_blob_demo(
            self.pak0,
            output,
            member_name=MEMBER_NAME,
            first_post_signon_record=2,
            keep_post_signon_records=3,
            event_record=3,
            event_type=fixture.TE_TELEPORT,
            coord_shorts=(-2136, 17413, 9968),
        )

        _, result = read_demo(output)
        expected = bytes((fixture.SVC_TEMP_ENTITY, fixture.TE_TELEPORT))
        expected += struct.pack("<hhh", -2136, 17413, 9968)
        self.assertEqual(info.event_type, fixture.TE_TELEPORT)
        self.assertEqual(result[3][0], self.source_records[3][0] + expected)
        self.assertEqual(result[-1][0], bytes((fixture.SVC_DISCONNECT,)))

    def test_injects_exact_wizspike_message_bytes(self) -> None:
        output = self.root / "wizspike.dem"
        info = fixture.create_blob_demo(
            self.pak0,
            output,
            member_name=MEMBER_NAME,
            first_post_signon_record=2,
            keep_post_signon_records=3,
            event_record=3,
            event_type=fixture.TE_WIZSPIKE,
            coord_shorts=(-2136, 17413, 9968),
        )

        _, result = read_demo(output)
        expected = bytes((fixture.SVC_TEMP_ENTITY, fixture.TE_WIZSPIKE))
        expected += struct.pack("<hhh", -2136, 17413, 9968)
        self.assertEqual(info.event_type, fixture.TE_WIZSPIKE)
        self.assertEqual(result[3][0], self.source_records[3][0] + expected)
        self.assertEqual(result[-1][0], bytes((fixture.SVC_DISCONNECT,)))

    def test_short_source_is_removed_after_format_failure(self) -> None:
        output = self.root / "too-short.dem"
        with self.assertRaisesRegex(ValueError, "record 6"):
            fixture.create_blob_demo(
                self.pak0,
                output,
                member_name=MEMBER_NAME,
                first_post_signon_record=2,
                keep_post_signon_records=5,
                event_record=2,
            )
        self.assertFalse(output.exists())


class BlobExplosionWorkflowWiringTests(unittest.TestCase):
    def test_render_validation_passes_fixture_json_and_gates_the_captured_frame(self) -> None:
        runner = (TOOLS / "render-validation-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("$scene.PSObject.Properties['demoFixture']", runner)
        self.assertIn("-DemoFixtureJson", runner)
        self.assertIn("ConvertTo-Json -InputObject $demoFixtureProperty.Value -Compress", runner)
        self.assertIn("$scene.PSObject.Properties['captureBenchEvents']", runner)
        self.assertIn("$eventFrames -contains $capturedFrameIndex", runner)
        self.assertIn("test = 'capture-bench-event'", runner)
        self.assertIn("captureBenchEvents = $captureBenchEvents", runner)
        self.assertIn("reference image unless golden comparison is deferred", runner)

    def test_timedemo_validates_fixture_ranges_paths_and_records_artifact_hashes(self) -> None:
        runner = (TOOLS / "timedemo-dos.ps1").read_text(encoding="utf-8")
        self.assertIn("[string]$DemoFixtureJson = ''", runner)
        for field in (
            "sourceMember",
            "firstPostSignonRecord",
            "keepPostSignonRecords",
            "eventRecord",
            "eventType",
            "coordShorts",
            "pakEntry",
        ):
            with self.subTest(field=field):
                self.assertIn(field, runner)
        self.assertIn("Get-FullPathUnderDirectory", runner)
        self.assertIn("$pakIndices.ContainsKey($expectedIndex)", runner)
        self.assertIn("$pakEntry.Equals($expectedEntry, [StringComparison]::Ordinal)", runner)
        self.assertNotIn("$pakEntry.Equals($expectedEntry, [StringComparison]::OrdinalIgnoreCase)", runner)
        self.assertIn("Get-FileHash -LiteralPath $fixtureDemPath -Algorithm SHA256", runner)
        self.assertIn("Get-FileHash -LiteralPath $overridePakPath -Algorithm SHA256", runner)
        self.assertIn("temporaryDemoRemoved = $true", runner)
        self.assertIn("$result['demoFixture'] = $demoFixtureResult", runner)
        self.assertIn("'--event-type', [string]$demoFixtureConfig.eventType", runner)
        self.assertIn("lavaSplashImplementation = $LavaSplashImplementation", runner)

    def test_svc_particle_scenario_dispatches_the_assembly_parser_on_capture_frame(self) -> None:
        manifest = json.loads(
            (TOOLS / "render-scenarios-parseparticleeffect.json").read_text(encoding="utf-8")
        )
        self.assertEqual(len(manifest["scenarios"]), 1)
        scene = manifest["scenarios"][0]
        self.assertEqual(scene["id"], "demo2-svc-particle-parser-event")
        self.assertIn("R_ParseParticleEffect", scene["description"])
        self.assertEqual(scene["expectedFrames"], 10)
        self.assertEqual(scene["captureFrame"], 10)
        self.assertEqual(scene["requiredBenchEvents"], ["runParticleEffect"])
        self.assertEqual(scene["expectedBenchEventFrames"], {"runParticleEffect": [10]})
        self.assertEqual(scene["captureBenchEvents"], ["runParticleEffect"])
        self.assertIsNone(scene["reference"])
        self.assertEqual(scene["demoFixture"]["eventType"], fixture.SVC_PARTICLE)
        self.assertEqual(scene["demoFixture"]["coordShorts"], [-2136, 17413, 9968])

        c_profile = json.loads(
            (TOOLS / "renderer-profiles/i486-parseparticleeffect-c.json").read_text(encoding="utf-8")
        )
        asm_profile = json.loads(
            (TOOLS / "renderer-profiles/i486-parseparticleeffect-asm.json").read_text(encoding="utf-8")
        )
        self.assertEqual(c_profile["selectors"], {
            "ParseParticleEffectImplementation": "c",
            "RunParticleEffectImplementation": "c",
        })
        self.assertEqual(asm_profile["selectors"], {
            "ParseParticleEffectImplementation": "asm",
            "RunParticleEffectImplementation": "c",
        })
        parser = (TOOLS.parent / "src" / "cl_parse.c").read_text(encoding="utf-8")
        particle_case = parser.split("case svc_particle:", 1)[1].split("case svc_spawnbaseline:", 1)[0]
        self.assertIn("R_ParseParticleEffect ();", particle_case)
        self.assertIn("Bench486RecordRunParticleEffectEvent ();", particle_case)

    def test_timedemo_rejects_mixed_case_pak_entry_before_staging(self) -> None:
        powershell = shutil.which("pwsh") or shutil.which("powershell")
        if powershell is None:
            self.skipTest("pwsh and powershell are unavailable")

        config = {
            "sourceMember": "demo2.dem",
            "firstPostSignonRecord": 4,
            "keepPostSignonRecords": 1,
            "eventRecord": 4,
            "eventType": fixture.TE_TAREXPLOSION,
            "coordShorts": [-2136, 17413, 9968],
            "pakEntry": "Demo2.dem",
        }
        out_root = TOOLS.parent / "out"
        out_existed_before = out_root.exists()
        staging_entries_before = (
            {path.name for path in out_root.glob("dos-timedemo-*")}
            if out_existed_before
            else set()
        )

        try:
            result = subprocess.run(
                [
                    powershell,
                    "-NoProfile",
                    "-NonInteractive",
                    "-File",
                    str(TOOLS / "timedemo-dos.ps1"),
                    "-DemoName",
                    "demo2",
                    "-DemoFixtureJson",
                    json.dumps(config, separators=(",", ":")),
                ],
                cwd=TOOLS.parent,
                capture_output=True,
                text=True,
                errors="replace",
                timeout=10,
                shell=False,
                check=False,
            )
        finally:
            self.assertEqual(out_root.exists(), out_existed_before)
            staging_entries_after = (
                {path.name for path in out_root.glob("dos-timedemo-*")}
                if out_root.exists()
                else set()
            )
            self.assertEqual(staging_entries_after, staging_entries_before)

        output = result.stdout + "\n" + result.stderr
        self.assertNotEqual(result.returncode, 0, output)
        self.assertIn(
            "demoFixture.pakEntry must exactly match the case-sensitive root member "
            "'demo2.dem' used by the timedemo command.",
            output,
        )

if __name__ == "__main__":
    unittest.main()
