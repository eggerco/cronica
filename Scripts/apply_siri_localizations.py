#!/usr/bin/env python3
"""
Ensure Siri/platform Localizable keys exist for every catalog locale.

Prefer real translations from Scripts/localize_platform_surfaces.py.
This script only fills *missing* locales using English as a temporary fallback
with state "new" (not "translated"), so checks can still flag unfinished work.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS = ROOT / "Shared/Localization/Localizable.xcstrings"

LOCALES = (
    "en", "de", "fr", "it", "pt-BR", "sk", "es-MX",
    "ar", "cs", "da", "el", "es", "fi", "he", "hi", "hr", "hu", "id",
    "ja", "ko", "ms", "nb", "nl", "pl", "ro", "ru", "sv", "tr", "uk",
    "zh-Hans", "zh-Hant",
)

# Keys that must exist for Siri / platform surfaces. Values are English source.
SIRI_STRINGS: dict[str, str] = {
    "Add to Watchlist": "Add to Watchlist",
    "Remove from Watchlist": "Remove from Watchlist",
    "Mark as Watched": "Mark as Watched",
    "Mark Up Next as Watched": "Mark Up Next as Watched",
    "Get Up Next": "Get Up Next",
    "Open Search": "Open Search",
    "Search Titles": "Search Titles",
    "Add from Link": "Add from Link",
    "Open Title": "Open Title",
    "Open Watchlist": "Open Watchlist",
    "Open Up Next": "Open Up Next",
    "Media Type": "Media Type",
    "Watchlist Title": "Watchlist Title",
    "Up Next Episode": "Up Next Episode",
    "Search Result": "Search Result",
    "Siri & Shortcuts": "Siri & Shortcuts",
    "Example phrases": "Example phrases",
    "Control Center": "Control Center",
    "Mark Watched": "Mark Watched",
    "Mark Up Next": "Mark Up Next",
    "Add to Reminders": "Add to Reminders",
    "Added to Reminders": "Added to Reminders",
    "Couldn't Add Reminder": "Couldn't Add Reminder",
    "Mark Up Next Watched": "Mark Up Next Watched",
    "Mark Next Episode Watched": "Mark Next Episode Watched",
    "Nothing Up Next": "Nothing Up Next",
    "Find movies and TV shows.": "Find movies and TV shows.",
    "Open your saved titles.": "Open your saved titles.",
    "See what's up next.": "See what's up next.",
}


def unit(value: str, *, translated: bool) -> dict:
    return {
        "stringUnit": {
            "state": "translated" if translated else "new",
            "value": value,
        }
    }


def main() -> int:
    # Prefer full platform localization when available.
    platform = ROOT / "Scripts/localize_platform_surfaces.py"
    if platform.exists():
        import runpy
        runpy.run_path(str(platform), run_name="__main__")

    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    strings = data.setdefault("strings", {})
    filled = 0

    for key, en_value in SIRI_STRINGS.items():
        entry = strings.setdefault(key, {})
        locs = entry.setdefault("localizations", {})
        if "en" not in locs:
            locs["en"] = unit(en_value, translated=True)
            filled += 1
        for locale in LOCALES:
            if locale == "en":
                continue
            if locale not in locs:
                # Temporary English fallback — not marked translated.
                locs[locale] = unit(en_value, translated=False)
                filled += 1

    XCSTRINGS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Filled {filled} missing locale entries (new/untranslated fallbacks only).")
    print("Run Scripts/localize_platform_surfaces.py for real App Shortcut + UI translations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
