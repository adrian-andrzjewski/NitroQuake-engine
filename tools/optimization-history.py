"""Count recorded optimization decisions, never builds or benchmark samples.

Normal ledger names encode one accepted/rejected candidate. The legacy map
describes imported multi-attempt reports and records without outcome names.
Git supplies reachable historical records, including subsequently deleted ones.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


def git(root: Path, *args: str) -> str:
    result = subprocess.run(["git", "-c", "color.ui=false", "-c", "core.quotepath=false",
                             "-c", "log.showSignature=false", "-C", str(root), *args],
                            capture_output=True, encoding="utf-8", check=True)
    return result.stdout


def inventory(root: Path) -> dict:
    root = root.resolve()
    if Path(git(root, "rev-parse", "--show-toplevel").strip()).resolve() != root:
        raise ValueError("Build identity requires this checkout's own Git history")
    if git(root, "rev-parse", "--is-shallow-repository").strip() != "false":
        raise ValueError("Build identity requires complete Git history; fetch --unshallow first")
    metadata_path = root / "tools/optimization-history-legacy.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    legacy = metadata["records"]
    aliases = metadata["supersededDocuments"]
    documents = {p.relative_to(root).as_posix(): p.read_text(encoding="utf-8-sig")
                 for p in (root / "docs/ledger").glob("*.md")}
    for path in metadata.get("additionalSources", []):
        documents[path] = (root / path).read_text(encoding="utf-8-sig")
    # An unstaged removal does not erase a previously recorded attempt either.
    for path in git(root, "ls-tree", "-r", "--name-only", "HEAD", "--", "docs/ledger").splitlines():
        if path.endswith(".md") and path not in documents:
            documents[path] = git(root, "show", "HEAD:" + path)
    # Only this revision's ancestry participates, never unrelated worktree branches.
    historical = git(root, "log", "HEAD", "--format=", "--name-status",
                     "--diff-filter=DR", "--find-renames", "--", "docs/ledger")
    renamed = set()
    rename_sources = {}
    deleted = set()
    for line in historical.splitlines():
        fields = line.split("\t")
        if fields[0].startswith("R"):
            renamed.add(fields[1])
            rename_sources.setdefault(fields[2], fields[1])
        elif fields[0] == "D":
            deleted.add(fields[1])
    for path in sorted(deleted - renamed - set(documents)):
        name = Path(path).name
        if name in aliases:
            if "docs/ledger/" + aliases[name] not in documents:
                raise ValueError("Missing replacement ledger: " + aliases[name])
            continue
        revision = git(root, "log", "HEAD", "-1", "--diff-filter=AMR",
                       "--format=%H", "--", path).strip()
        if revision:
            documents[path] = git(root, "show", revision + ":" + path)
    attempts = {}
    sources = {"tools/optimization-history-legacy.json":
               hashlib.sha256(metadata_path.read_text(encoding="utf-8").encode()).hexdigest()}
    excluded = []
    for path, text in sorted(documents.items()):
        name = Path(path).name
        if name in aliases:
            continue
        sources[path] = hashlib.sha256(text.replace("\r\n", "\n").encode()).hexdigest()
        # Preserve multi-attempt classifications when a historical report moves.
        origin = path
        seen = set()
        while origin in rename_sources and origin not in seen:
            seen.add(origin)
            origin = rename_sources[origin]
        legacy_name = name if name in legacy else Path(origin).name
        markers = re.findall(r"<!-- optimization-attempt: ([a-zA-Z0-9_.#-]+) (accepted|rejected) -->", text)
        if markers:
            entries = [dict(id=attempt_id, outcome=outcome) for attempt_id, outcome in markers]
        elif "<!-- optimization-attempts: none -->" in text:
            entries = []
        elif legacy_name in legacy:
            entries = legacy[legacy_name]
        elif "-rejected" in name:
            entries = [{"outcome": "rejected"}]
        elif any(token in name for token in ("-promoted", "-promotion", "-assembly-port", "-release-default")):
            entries = [{"outcome": "accepted"}]
        else:
            raise ValueError("Ledger needs an accepted/rejected outcome or legacy classification: " + name)
        if not entries:
            excluded.append(path)
        for entry in entries:
            outcome = entry["outcome"]
            if outcome not in ("accepted", "rejected"):
                raise ValueError("Invalid optimization outcome in " + path)
            heading = entry.get("heading")
            if heading and not re.search(r"^#{1,6} " + re.escape(heading) + r"\s*$", text, re.M):
                raise ValueError("Legacy source heading no longer exists: " + path + " / " + heading)
            if entry.get("quote") and entry["quote"] not in text:
                raise ValueError("Legacy source evidence no longer exists: " + path + " / " + entry["id"])
            attempt_id = entry.get("id", Path(origin).stem)
            if len(entries) > 1 and "id" not in entry:
                raise ValueError("Multi-attempt reports require distinct IDs: " + path)
            record = dict(id=attempt_id, outcome=outcome, document=path)
            if heading:
                record["heading"] = heading
            if entry.get("quote"):
                record["quote"] = entry["quote"]
            if attempt_id in attempts:
                if attempts[attempt_id]["outcome"] != outcome:
                    raise ValueError("Conflicting outcomes for " + attempt_id)
                continue
            attempts[attempt_id] = record
    # A few early accepted changes were committed without their own report.
    # Pin those exact revisions; never infer attempts from commit-message counts.
    reachable = set(git(root, "rev-list", "HEAD").splitlines())
    for entry in metadata.get("gitOnlyAttempts", []):
        revision = entry["commit"]
        if revision not in reachable:
            continue
        if entry["outcome"] not in ("accepted", "rejected") or entry["id"] in attempts:
            raise ValueError("Invalid or duplicate Git-only optimization: " + entry["id"])
        source = "git:" + revision
        evidence = git(root, "cat-file", "commit", revision)
        sources[source] = hashlib.sha256(evidence.encode()).hexdigest()
        attempts[entry["id"]] = dict(id=entry["id"], outcome=entry["outcome"],
                                     document=source, description=entry["description"])
    records = sorted(attempts.values(), key=lambda x: x["id"])
    counts = {outcome: sum(r["outcome"] == outcome for r in records)
              for outcome in ("accepted", "rejected")}
    canonical = json.dumps(dict(attempts=records, sources=sources), sort_keys=True,
                           ensure_ascii=True, separators=(",", ":")).encode()
    return dict(schemaVersion=1, status="complete", complete=True,
                buildNumber=len(records), **counts,
                inventorySha256=hashlib.sha256(canonical).hexdigest(),
                gitRevision=git(root, "rev-parse", "HEAD").strip(),
                attempts=records, sources=sources, excludedDocuments=excluded)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        result = inventory(args.repo_root)
    except (ValueError, subprocess.CalledProcessError) as error:
        parser.error("Cannot derive build identity; complete Git history and classified optimization reports are required: " + str(error))
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items()
                      if k not in ("attempts", "sources", "excludedDocuments")}))


if __name__ == "__main__":
    main()
