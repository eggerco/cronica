#!/usr/bin/env python3
"""Find stale / unused keys in Localizable.xcstrings."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS = ROOT / "Shared/Localization/Localizable.xcstrings"

SKIP_PREFIXES = ("Scripts/", ".git/", "build/", ".build/")


def swift_sources() -> str:
    chunks = []
    for path in ROOT.rglob("*.swift"):
        rel = str(path.relative_to(ROOT))
        if any(rel.startswith(p) for p in SKIP_PREFIXES):
            continue
        try:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            pass
    return "\n".join(chunks)


def normalize_apostrophe(s: str) -> str:
    return s.replace("\u2019", "'").replace("\u2018", "'")


def referenced_in_swift(key: str, source: str) -> bool:
    if not key or key.strip() == "":
        return True  # layout spacers
    if key in source:
        return True
    norm_key = normalize_apostrophe(key)
    if norm_key in source:
        return True
    # Interpolated strings: "Delete \(n) Items" -> catalog key "Delete %lld Items"
    if "%" in key:
        stem = re.split(r"%\d*\$?[@lldhmsf.]+", key)[0].strip()
        if len(stem) >= 10 and stem in source:
            return True
    # Long keys: allow match on first 40 chars if unique enough
    if len(key) >= 40:
        snippet = normalize_apostrophe(key[:40])
        if snippet in source:
            return True
    return False


def main() -> int:
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    keys = data["strings"]
    source = swift_sources()

    orphans = []
    for key in sorted(keys):
        if not referenced_in_swift(key, source):
            orphans.append(key)

    # duplicate groups (apostrophe / casing)
    groups: dict[str, list[str]] = {}
    for key in keys:
        norm = normalize_apostrophe(key).casefold()
        groups.setdefault(norm, []).append(key)
    dupes = {n: ks for n, ks in groups.items() if len(ks) > 1}

    print(f"Catalog keys: {len(keys)}")
    print(f"Likely orphaned (no Swift reference): {len(orphans)}\n")

    for key in orphans[:30]:
        display = key if len(key) <= 100 else key[:97] + "..."
        print(f"  • {display!r}")
    if len(orphans) > 30:
        print(f"  … and {len(orphans) - 30} more")

    if dupes:
        print(f"\nDuplicate key groups: {len(dupes)}")
        for _, ks in sorted(dupes.items(), key=lambda x: x[1][0]):
            print(f"  {ks}")

    stale_scripts = [
        p for p in (ROOT / "Scripts").rglob("*")
        if p.is_file()
        and (
            p.name.startswith("_")
            or p.suffix in {".txt"}
            or p.name in {
                "apply_siri_localizations.py",
                "build_missing_translations.py",
                "generate_missing_translations.py",
                "generate_locale_translations.py",
                "locale_translation_data.py",
                "localization_stale_export.json",
                "localization_remaining_export.json",
            }
        )
    ]
    stale_scripts = sorted({p.relative_to(ROOT) for p in stale_scripts})

    print(f"\nStale generator/export files in Scripts/: {len(stale_scripts)}")
    for p in stale_scripts[:15]:
        print(f"  {p}")
    if len(stale_scripts) > 15:
        print(f"  … and {len(stale_scripts) - 15} more")

    return 0


if __name__ == "__main__":
    sys.exit(main())
