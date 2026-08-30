#!/usr/bin/env python3
"""Fill new-locale JSON maps via Google Cloud Translation API (official).

Resumes from Scripts/translations/new_locales/<locale>.json checkpoints.
Protects format tokens and brand names. Does not store English stubs on failure.

Requires a Cloud Translation API key — see Scripts/cloud_translate.py / Docs/LOCALIZATION.md.
"""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cloud_translate import (  # noqa: E402
    DEFAULT_BATCH_SIZE,
    require_api_key,
    translate_batch,
)

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS = ROOT / "Shared/Localization/Localizable.xcstrings"
OUT_DIR = Path(__file__).resolve().parent / "translations" / "new_locales"

LOCALES = {
    "bn": "bn",
    "ca": "ca",
    "gu": "gu",
    "kn": "kn",
    "ml": "ml",
    "mr": "mr",
    "or": "or",
    "pa": "pa",
    "sl": "sl",
    "ta": "ta",
    "te": "te",
    "th": "th",
    "ur": "ur",
    "vi": "vi",
}

BRANDS = [
    "YouTubePlayerKit", "The Movie Database", "Letterboxd", "JustWatch",
    "CloudKit", "Cronica", "SIMKL", "TMDB", "TMDb", "iCloud", "YouTube",
    "Apple TV", "Apple Watch", "Apple ID", "Apple", "IMDb", "Trakt",
    "Secrets.xcconfig", "SIMKL_CLIENT_ID", "TMDB_API_KEY",
    "support@cronica.watch", "simkl.com/pin", "SwiftUI", "Live Activities",
    "Control Center", "App Store", "Share Sheet",
]

FMT_RE = re.compile(r"(\$\{[A-Za-z0-9_]+\}|%[\d]*\$?[a-zA-Z@.]+|%[\d.]*[a-zA-Z])")

ALLOW_IDENTICAL = {
    "", " ", "%@", "ID", "OK", "TV", "%@\n", "%lld", "Nuke", "TMDB", "SIMKL",
    "Test", "Cyan", "Coral", "Indigo", "Anime", "Drama", "E%lld", "%lld%%",
    "Backup", "Design", "Filter", "Genres", "Horror", "Poster", "Status",
    "System", "• %1$@", "%@ • %@", "Cronica", "Episode", "Fantasy", "Romance",
    "%1$d min", "%lld min", "CloudKit", "Feedback", "Premiere", "Standard",
    "Thriller", "Trailers", "Watchlist", "%1$@ %2$@", "Adventure", "Animation",
    "Hong Kong", "Portugal", "S%d · E%d", "SIMKL API", "Turquoise", "%lld items",
    "Argentina", "Australia", "Canada", "India", "Israel", "France", "Austria",
    "Bulgaria", "Estonia", "Indonesia", "Philippines", "Serbia", "Slovakia",
    "Japan", "Italy", "Mexico", "Brazil", "Spain", "Notes", "Notifications",
    "Production", "Orange", "Account", "Description", "General", "Version %1$@",
    "Action", "Crime", "Mystery", "Alien", "Region", "Type", "Digital",
    "%lld / %lld", "X (Twitter)", "The Movie Database", "YouTubePlayerKit",
    "An Egger & Co Product", "Kevin Manca", "Luis Felipe Lerma Alvarez",
    "Pierre Quéré", "Simon Boer", "Tomáš Švec", "Egger",
    "S%d, E%d", "%1$lld · %2$@", "%1$.1f hours", "%d%% watched",
    "Version %@ • %@", "%1$@ • %2$@ %3$@", "%lld hr %lld min",
    "%@ Seasons • %@ Episodes", "%lld Seasons • %lld Episodes",
    "SIMKL request failed (%lld).", "Rating star %@ of 5.",
    "Rating star %lld of 5.", "Rated %1$lld of 5", "Icon Designer",
    "Control Center", "App Store", "Live Activities", "Share Sheet",
    "%lld hr", "Croatia", "Hungary", "Ireland", "New Zealand",
}


def protect(text: str):
    tokens = []
    out = text
    for brand in sorted(BRANDS, key=len, reverse=True):
        if brand in out:
            tokens.append(brand)
            out = out.replace(brand, f"XTOK{len(tokens) - 1}X")

    def stash(match):
        tokens.append(match.group(0))
        return f"XTOK{len(tokens) - 1}X"

    return FMT_RE.sub(stash, out), tokens


CORRUPT_TOKEN_RE = re.compile(r"X\s*T\s*K\s*O+K?\s*\d+\s*X", re.I)


def restore(text: str, tokens) -> str:
    out = text
    for i, tok in enumerate(tokens):
        patterns = (
            f"XTOK{i}X",
            f"XTOK{i}x",
            f"xtok{i}x",
            f"Xtok{i}X",
            f"XTKO{i}X",
            f"XTKOK{i}X",
            f"xtko{i}x",
            f"xtkok{i}x",
        )
        replaced = False
        for pattern in patterns:
            if pattern in out:
                out = out.replace(pattern, tok)
                replaced = True
                break
        if replaced:
            continue
        low = out.lower()
        for needle in (f"xtok{i}x", f"xtko{i}x", f"xtkok{i}x"):
            idx = low.find(needle)
            if idx >= 0:
                out = out[:idx] + tok + out[idx + len(needle) :]
                low = out.lower()
                break
    remaining = [t for t in tokens if t not in out]
    while remaining:
        match = CORRUPT_TOKEN_RE.search(out)
        if not match:
            break
        out = out[: match.start()] + remaining.pop(0) + out[match.end() :]
    return out


def is_format_only(value: str) -> bool:
    stripped = re.sub(r"%[\d]*\$?[@lldhmsf.]+", "", value)
    stripped = re.sub(r"[•·/\-+()EeSs%\s]", "", stripped)
    return len(stripped.strip()) < 2


def english_strings() -> list:
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    out = []
    seen = set()
    for key, entry in data["strings"].items():
        en = (entry.get("localizations") or {}).get("en", {}).get("stringUnit", {}).get("value")
        if en is None:
            en = key
        if en not in seen:
            seen.add(en)
            out.append(en)
    return out


def needs_work(en: str, current: Optional[str]) -> bool:
    if current is None:
        return True
    if current != en:
        return False
    if en in ALLOW_IDENTICAL or is_format_only(en):
        return False
    return True


def fill_locale(locale: str, gcode: str, strings: list, api_key: str) -> tuple:
    out_path = OUT_DIR / f"{locale}.json"
    result = {}
    if out_path.exists():
        result = json.loads(out_path.read_text(encoding="utf-8"))

    pending = [s for s in strings if needs_work(s, result.get(s))]
    print(f"[{locale}] have={len(result)} pending={len(pending)}", flush=True)
    if not pending:
        return len(result), 0

    # Translate in batches (protect tokens per string).
    for start in range(0, len(pending), DEFAULT_BATCH_SIZE):
        chunk = pending[start : start + DEFAULT_BATCH_SIZE]
        protected_list = []
        token_lists = []
        passthrough = []  # indices that should stay English
        for en in chunk:
            if en in ALLOW_IDENTICAL or is_format_only(en):
                protected_list.append(en)
                token_lists.append([])
                passthrough.append(True)
            else:
                protected, tokens = protect(en)
                protected_list.append(protected)
                token_lists.append(tokens)
                passthrough.append(False)

        translated = translate_batch(protected_list, gcode, api_key=api_key)
        for en, raw, tokens, skip in zip(chunk, translated, token_lists, passthrough):
            if skip:
                result[en] = en
            else:
                result[en] = restore(raw, tokens).replace("  ", " ").strip()

        out_path.write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        done = min(start + len(chunk), len(pending))
        print(f"[{locale}] progress {done}/{len(pending)} (total keys {len(result)})", flush=True)
        time.sleep(0.2)

    identical = sum(
        1 for k, v in result.items()
        if v == k and k not in ALLOW_IDENTICAL and not is_format_only(k)
    )
    still = sum(1 for s in strings if needs_work(s, result.get(s)))
    print(
        f"[{locale}] DONE keys={len(result)} identical={identical} still_pending={still}",
        flush=True,
    )
    return len(result), identical


def main() -> int:
    api_key = require_api_key()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    strings = english_strings()
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    locales = [k for k in LOCALES if not only or k in only]

    def pending_count(loc: str) -> int:
        p = OUT_DIR / f"{loc}.json"
        result = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
        return sum(1 for s in strings if needs_work(s, result.get(s)))

    locales = sorted(locales, key=pending_count, reverse=True)
    print("Using Google Cloud Translation API", flush=True)
    print("Order:", ", ".join(f"{l}:{pending_count(l)}" for l in locales), flush=True)

    for locale in locales:
        fill_locale(locale, LOCALES[locale], strings, api_key)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
