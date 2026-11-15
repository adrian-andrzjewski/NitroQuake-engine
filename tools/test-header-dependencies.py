#!/usr/bin/env python3
"""Keep legacy umbrella and benchmark-interface dependencies explicit."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
LEGACY_LIST = ROOT / "docs" / "legacy-quakedef-includes.txt"
PROFILE_HEADER = SOURCE / "tests" / "bench486" / "bench486_profile.h"

INCLUDE_QUAKEDEF = re.compile(
    r'^\s*#\s*include\s*[<"]quakedef\.h[>"]', re.MULTILINE
)
for include_form in (
    '#include "quakedef.h"',
    "# include <quakedef.h>",
    '#include "quakedef.h" // legacy dependency',
):
    if not INCLUDE_QUAKEDEF.search(include_form):
        raise SystemExit(f"umbrella include detector missed: {include_form}")
INCLUDE_PROFILE = re.compile(
    r'^\s*#\s*include\s*"tests/bench486/bench486_profile\.h"\s*$',
    re.MULTILINE,
)
PROFILE_SYMBOL = re.compile(
    r"\b(?:BENCH486_PROFILE_[A-Za-z0-9_]+|BENCH486_TIMEDEMO_[A-Za-z0-9_]+|"
    r"bench486_[A-Za-z0-9_]+|Bench486[A-Za-z0-9_]+|Zone_ResetProfileCounters)\b"
)

production_sources = sorted(
    path for path in SOURCE.rglob("*.c")
    if "tests" not in path.relative_to(SOURCE).parts
)
legacy_sources = {
    path.relative_to(ROOT).as_posix()
    for path in production_sources
    if INCLUDE_QUAKEDEF.search(path.read_text(encoding="utf-8", errors="replace"))
}

listed = [
    line.strip()
    for line in LEGACY_LIST.read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]
if len(listed) != len(set(listed)):
    raise SystemExit("legacy-quakedef-includes.txt contains duplicate paths")
if set(listed) != legacy_sources:
    unlisted = sorted(legacy_sources - set(listed))
    stale = sorted(set(listed) - legacy_sources)
    raise SystemExit(
        "legacy quakedef include inventory differs; "
        f"unlisted={unlisted}, stale={stale}"
    )

umbrella = (SOURCE / "quakedef.h").read_text(encoding="utf-8", errors="replace")
profile_header_text = PROFILE_HEADER.read_text(encoding="utf-8", errors="replace")
if "#ifndef BENCH486_PROFILE_H" not in profile_header_text:
    raise SystemExit("benchmark profiling interface has no include guard")
profile_symbols = set(PROFILE_SYMBOL.findall(profile_header_text))
if any(re.search(r"\b" + re.escape(symbol) + r"\b", umbrella) for symbol in profile_symbols):
    raise SystemExit("profiling declarations remain in quakedef.h")
if re.search(r"(?m)^\s*#\s*ifdef\s+PROFILE486\b", umbrella):
    raise SystemExit("PROFILE486 declarations remain in quakedef.h")

profile_consumers = 0
for path in production_sources:
    text = path.read_text(encoding="utf-8", errors="replace")
    if any(re.search(r"\b" + re.escape(symbol) + r"\b", text) for symbol in profile_symbols):
        if not INCLUDE_PROFILE.search(text):
            raise SystemExit(
                "profiling consumer omits its direct interface include: "
                f"{path.relative_to(ROOT).as_posix()}"
            )
        profile_consumers += 1

print(
    "Header dependencies PASS: "
    f"{len(production_sources)} production C files, "
    f"{len(legacy_sources)} explicit legacy umbrella users, "
    f"{profile_consumers} direct profiling consumers"
)
