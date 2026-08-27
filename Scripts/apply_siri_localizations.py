#!/usr/bin/env python3
"""Ensure every String Catalog key has all catalog locales (fills gaps from English)."""

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
    "Media Type": "Media Type",
    "Watchlist Title": "Watchlist Title",
    "Up Next Episode": "Up Next Episode",
    "Search Result": "Search Result",
    "Add a movie or TV show to your Cronica watchlist.": "Add a movie or TV show to your Cronica watchlist.",
    "Remove a title from your Cronica watchlist.": "Remove a title from your Cronica watchlist.",
    "Mark a movie or TV show as watched in Cronica.": "Mark a movie or TV show as watched in Cronica.",
    "Mark your next episode as watched in Cronica.": "Mark your next episode as watched in Cronica.",
    "See what episodes are up next in Cronica.": "See what episodes are up next in Cronica.",
    "Open Cronica search to find movies and TV shows.": "Open Cronica search to find movies and TV shows.",
    "Search for movies and TV shows in Cronica.": "Search for movies and TV shows in Cronica.",
    "Add a movie or TV show to your watchlist from a shared link.": "Add a movie or TV show to your watchlist from a shared link.",
    "Open a movie or TV show in Cronica.": "Open a movie or TV show in Cronica.",
    "Please say which title you mean.": "Please say which title you mean.",
    "Cronica couldn't find that movie or TV show.": "Cronica couldn't find that movie or TV show.",
    "That title isn't on your watchlist.": "That title isn't on your watchlist.",
    "That title is already on your watchlist.": "That title is already on your watchlist.",
    "That title hasn't been released yet.": "That title hasn't been released yet.",
    "You don't have any episodes up next.": "You don't have any episodes up next.",
    "Cronica couldn't reach TMDb. Try again in a moment.": "Cronica couldn't reach TMDb. Try again in a moment.",
    "Added %@ to your watchlist.": "Added %@ to your watchlist.",
    "Removed %@ from your watchlist.": "Removed %@ from your watchlist.",
    "Marked %@ as watched.": "Marked %@ as watched.",
    "Opening %@ in Cronica.": "Opening %@ in Cronica.",
    "Opening search in Cronica.": "Opening search in Cronica.",
    "Siri & Shortcuts": "Siri & Shortcuts",
    "Browse Cronica Shortcuts": "Browse Cronica Shortcuts",
    "Use Siri and the Shortcuts app to add titles, mark episodes watched, check what's up next, and open movies or shows in Cronica.": "Use Siri and the Shortcuts app to add titles, mark episodes watched, check what's up next, and open movies or shows in Cronica.",
    "Example phrases": "Example phrases",
    "“Add Dune to Cronica”": "“Add Dune to Cronica”",
    "“What's up next on Cronica?”": "“What's up next on Cronica?”",
    "“Mark my next episode as watched”": "“Mark my next episode as watched”",
    "“Open Severance in Cronica”": "“Open Severance in Cronica”",
    "Mark Up Next Watched": "Mark Up Next Watched",
    "Open the Shortcuts app to browse Cronica actions and add them to Siri.": "Open the Shortcuts app to browse Cronica actions and add them to Siri.",
    "Mark Next Episode Watched": "Mark Next Episode Watched",
    "Find movies and TV shows.": "Find movies and TV shows.",
    "Open your saved titles.": "Open your saved titles.",
    "See what's up next.": "See what's up next.",
    "Nothing Up Next": "Nothing Up Next",
    "Open Watchlist": "Open Watchlist",
    "Open Up Next": "Open Up Next",
    "Open your Cronica watchlist.": "Open your Cronica watchlist.",
    "Open your Up Next list in Cronica.": "Open your Up Next list in Cronica.",
    "Opening your watchlist in Cronica.": "Opening your watchlist in Cronica.",
    "Opening Up Next in Cronica.": "Opening Up Next in Cronica.",
    "Mark Watched": "Mark Watched",
    "Add to Reminders": "Add to Reminders",
    "Added to Reminders": "Added to Reminders",
    "Couldn't Add Reminder": "Couldn't Add Reminder",
    "Cronica added a reminder for the next release or episode.": "Cronica added a reminder for the next release or episode.",
    "There isn't an upcoming release or episode date for this title.": "There isn't an upcoming release or episode date for this title.",
    "Cronica needs Reminders access to create a reminder.": "Cronica needs Reminders access to create a reminder.",
    "Release: %@": "Release: %@",
    "Next episode: %@": "Next episode: %@",
    "Control Center": "Control Center",
    "On iOS 18 or later, add Cronica controls from Settings → Control Center for Up Next and Mark Watched.": "On iOS 18 or later, add Cronica controls from Settings → Control Center for Up Next and Mark Watched.",
    "“Open my watchlist in Cronica”": "“Open my watchlist in Cronica”",
    "“Open up next in Cronica”": "“Open up next in Cronica”",
    "To reminder yourself about a specific title, use Add to Reminders on its detail page.": "To reminder yourself about a specific title, use Add to Reminders on its detail page.",
}


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def main() -> int:
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    strings = data.setdefault("strings", {})
    filled = 0

    for key, en_value in SIRI_STRINGS.items():
        strings.setdefault(key, {})

    for key, entry in strings.items():
        localizations = entry.setdefault("localizations", {})
        en_value = (
            localizations.get("en", {}).get("stringUnit", {}).get("value")
            or SIRI_STRINGS.get(key)
            or key
        )
        if "en" not in localizations:
            localizations["en"] = unit(en_value)
            filled += 1
        for locale in LOCALES:
            if locale not in localizations:
                localizations[locale] = unit(en_value)
                filled += 1

    XCSTRINGS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Filled {filled} missing locale entries.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
