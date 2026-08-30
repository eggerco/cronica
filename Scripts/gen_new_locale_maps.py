#!/usr/bin/env python3
"""Sequentially fill new-locale JSON maps via MyMemory (+ Google fallback).

Resumes from Scripts/translations/new_locales/<locale>.json checkpoints.
Protects format tokens and brand names. Does not store English stubs on failure.
"""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path
from typing import Optional

import requests

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
    "Control Center", "App Store",
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


def restore(text: str, tokens) -> str:
    out = text
    for i, tok in enumerate(tokens):
        for pattern in (f"XTOK{i}X", f"XTOK{i}x", f"xtok{i}x", f"Xtok{i}X"):
            if pattern in out:
                out = out.replace(pattern, tok)
                break
        else:
            low = out.lower()
            needle = f"xtok{i}x"
            idx = low.find(needle)
            if idx >= 0:
                out = out[:idx] + tok + out[idx + len(needle) :]
    return out


def is_format_only(value: str) -> bool:
    stripped = re.sub(r"%[\d]*\$?[@lldhmsf.]+", "", value)
    stripped = re.sub(r"[•·/\-+()EeSs%\s]", "", stripped)
    return len(stripped.strip()) < 2


def mymemory_translate(text: str, tl: str) -> str:
    url = "https://api.mymemory.translated.net/get"
    chunk = text if len(text) <= 450 else text[:447] + "..."
    r = requests.get(url, params={"q": chunk, "langpair": f"en|{tl}"}, timeout=20)
    r.raise_for_status()
    data = r.json()
    if int(data.get("responseStatus", 0)) != 200:
        raise RuntimeError(data.get("responseDetails") or "mymemory error")
    translated = (data.get("responseData") or {}).get("translatedText") or ""
    if not translated:
        raise RuntimeError("empty mymemory translation")
    if translated.upper().startswith("MYMEMORY WARNING"):
        raise RuntimeError(translated)
    return translated


def google_translate(text: str, tl: str) -> str:
    url = "https://translate.googleapis.com/translate_a/single"
    params = {"client": "gtx", "sl": "en", "tl": tl, "dt": "t", "q": text}
    r = requests.get(url, params=params, timeout=20)
    if r.status_code == 429:
        raise requests.HTTPError("429", response=r)
    r.raise_for_status()
    data = r.json()
    return "".join(part[0] for part in data[0] if part and part[0])


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


def translate_one(en: str, tl: str) -> Optional[str]:
    if en in ALLOW_IDENTICAL or is_format_only(en):
        return en
    protected, tokens = protect(en)
    last_err = None
    backoff = 2.0
    for attempt in range(8):
        try:
            if attempt % 2 == 0:
                translated = mymemory_translate(protected, tl)
            else:
                translated = google_translate(protected, tl)
            if translated:
                return restore(translated, tokens).replace("  ", " ").strip()
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            msg = str(exc)
            if "429" in msg or "WARNING" in msg.upper() or "QUOTA" in msg.upper():
                print(f"  rate-limit {tl}, sleep {backoff:.0f}s ({exc})", flush=True)
                time.sleep(backoff)
                backoff = min(backoff * 1.7, 90)
            else:
                time.sleep(1.2)
    print(f"  FAIL {tl}: {en[:50]!r} ({last_err})", flush=True)
    return None


def needs_work(en: str, current: Optional[str]) -> bool:
    if current is None:
        return True
    if current != en:
        return False
    if en in ALLOW_IDENTICAL or is_format_only(en):
        return False
    return True  # English copy left from prior failure


def fill_locale(locale: str, gcode: str, strings: list) -> tuple:
    out_path = OUT_DIR / f"{locale}.json"
    result = {}
    if out_path.exists():
        result = json.loads(out_path.read_text(encoding="utf-8"))

    pending = [s for s in strings if needs_work(s, result.get(s))]
    print(f"[{locale}] have={len(result)} pending={len(pending)}", flush=True)

    for i, en in enumerate(pending, 1):
        translated = translate_one(en, gcode)
        if translated is None:
            time.sleep(5.0)
            continue
        result[en] = translated
        if i % 15 == 0 or i == len(pending):
            out_path.write_text(
                json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
            print(f"[{locale}] progress {i}/{len(pending)} (total keys {len(result)})", flush=True)
        time.sleep(0.55)

    out_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
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
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    strings = english_strings()
    only = sys.argv[1:]
    locales = [k for k in LOCALES if not only or k in only]

    def pending_count(loc: str) -> int:
        p = OUT_DIR / f"{loc}.json"
        result = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
        return sum(1 for s in strings if needs_work(s, result.get(s)))

    locales = sorted(locales, key=pending_count, reverse=True)
    print("Order:", ", ".join(f"{l}:{pending_count(l)}" for l in locales), flush=True)

    for locale in locales:
        fill_locale(locale, LOCALES[locale], strings)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
