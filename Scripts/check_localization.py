#!/usr/bin/env python3
"""Report localization health for all String Catalog locales."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS = ROOT / "Shared/Localization/Localizable.xcstrings"

CATALOG_LOCALES = (
    "en", "de", "fr", "it", "pt-BR", "pt-PT", "sk", "es-MX",
    "ar", "bn", "ca", "cs", "da", "el", "es", "fi", "gu", "he", "hi", "hr",
    "hu", "id", "ja", "kn", "ko", "ml", "mr", "ms", "nb", "nl", "or", "pa",
    "pl", "ro", "ru", "sl", "sv", "ta", "te", "th", "tr", "uk", "ur", "vi",
    "zh-Hans", "zh-Hant",
)

ALLOW_IDENTICAL = {
    "TMDB", "SIMKL", "Cronica", "iCloud", "iPhone", "iPad", "Apple", "JSON", "API",
    "SIMKL API Rules", "SIMKL Website", "TMDB API Terms", "TMDB Terms", "TMDB Website",
    "Link", "Person", "Information", "Details", "Filters", "Week", "Card", "Query",
    "Episode %lld", "Version %@ • %@", "%lld items", "Trending", "Presentation",
    "iCloud Sync", "Fireball", "Mint", "Lavender", "Teal", "Pink", "Superhero", "Slovak",
    "Belgium", "Croatia", "Denmark", "Finland", "Hungary", "Ireland", "Lithuania",
    "New Zealand", "Norway", "Poland", "Sweden", "Switzerland", "United Kingdom",
    "Open ${title} in Cronica", "“Open Severance in Cronica”",
    "TV", "OK", "URL", "CloudKit", "YouTubePlayerKit", "The Movie Database", "SIMKL API",
    "X (Twitter)", "An Egger & Co Product", "Kevin Manca", "Luis Felipe Lerma Alvarez",
    "Pierre Quéré", "Simon Boer", "Tomáš Švec", "Egger", "Nuke", "ID", "Anime", "🛠️",
    "Control Center", "SwiftUI Preview", "Live Activities", "Icon Designer",
    "Hong Kong", "Portugal", "Argentina", "Canada", "India", "Israel", "France",
    "Australia", "Austria", "Bulgaria", "Estonia", "Indonesia", "Philippines",
    "Serbia", "Slovakia", "Japan", "Italy", "Mexico", "Brazil", "Spain",
    "Feedback", "Backup", "Design", "Digital", "Drama", "Standard", "Test", "Thriller",
    "Alien", "Action", "Animation", "Fantasy", "Romance", "Genres", "Notes", "Notifications",
    "Production", "Orange", "Cyan", "Indigo", "Coral", "Turquoise", "Episode", "Premiere",
    "Poster", "Region", "Status", "System", "Type", "Trailers", "Filter", "Horror",
    "Mystery", "Crime", "Account", "Description", "General", "Version %1$@",
    "%1$d min", "%lld min", "%lld%%", "Watchlist",
}


def is_format_only(value: str) -> bool:
    stripped = re.sub(r"%[\d]*\$?[@lldhmsf.]+", "", value)
    stripped = re.sub(r"[•·/\-+()EeSs%]", "", stripped)
    return len(stripped.strip()) < 2


def main() -> int:
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    strings = data["strings"]
    total = len(strings)
    issues = 0

    print(f"Catalog locales: {len(CATALOG_LOCALES)}")
    print(f"Total keys: {total}\n")

    for locale in CATALOG_LOCALES:
        missing = 0
        identical = 0
        for key, entry in strings.items():
            locs = entry.get("localizations", {})
            en = locs.get("en", {}).get("stringUnit", {}).get("value") or key
            val = locs.get(locale, {}).get("stringUnit", {}).get("value")
            if val is None:
                missing += 1
            elif locale != "en" and val == en and en not in ALLOW_IDENTICAL and not is_format_only(en):
                identical += 1

        coverage = total - missing
        status = "OK" if missing == 0 else "MISSING"
        print(f"{locale:8} {coverage}/{total} ({coverage / total * 100:.1f}%) {status}")
        issues += missing

    print()
    if issues:
        print(f"Found {issues} missing translation(s).")
        return 1
    print("All catalog locales are complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
