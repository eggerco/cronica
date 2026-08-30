#!/usr/bin/env python3
"""Fill missing App Shortcut / Info.plist / Siri UI locales via maps + Google Translate.

Writes Scripts/translations/platform_new_locales.json, which
localize_platform_surfaces.py merges at runtime.

Usage:
  python3 Scripts/fill_platform_new_locales.py
  python3 Scripts/fill_platform_new_locales.py bn ca   # subset
"""

from __future__ import annotations

import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from localize_platform_surfaces import (  # noqa: E402
    APP_SHORTCUT_PHRASES,
    EXAMPLE_PHRASES,
    INFO_PLIST_STRINGS,
    LOCALES,
    MORE_UI,
    UI_STRINGS,
)
from siri_dialog_localizations import SIRI_DIALOG_STRINGS  # noqa: E402

TRANS_DIR = Path(__file__).resolve().parent / "translations" / "new_locales"
OUT_PATH = TRANS_DIR / "platform_new_locales.json"

NEW_LOCALES = (
    "bn", "ca", "gu", "kn", "ml", "mr", "or", "pt-PT", "pa",
    "sl", "ta", "te", "th", "ur", "vi",
)

GCODES = {
    "bn": "bn", "ca": "ca", "gu": "gu", "kn": "kn", "ml": "ml", "mr": "mr",
    "or": "or", "pa": "pa", "pt-PT": "pt", "sl": "sl", "ta": "ta", "te": "te",
    "th": "th", "ur": "ur", "vi": "vi",
}

FMT_RE = re.compile(r"\$\{[^}]+\}|%[\d]*\$?[@lldhmsf.]+")
BRANDS = ("Cronica", "Chronica", "SIMKL", "JustWatch", "TMDb", "Siri", "iCloud")


def protect(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []
    out = text
    for brand in BRANDS:
        if brand in out:
            tokens.append(brand)
            out = out.replace(brand, f"XTOK{len(tokens) - 1}X")

    def stash(match: re.Match[str]) -> str:
        tokens.append(match.group(0))
        return f"XTOK{len(tokens) - 1}X"

    out = FMT_RE.sub(stash, out)
    return out, tokens


def restore(text: str, tokens: list[str]) -> str:
    out = text
    for i, tok in enumerate(tokens):
        for pattern in (f"XTOK{i}X", f"XTOK{i}x", f"xtok{i}x"):
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


def mymemory_translate(text: str, tl: str) -> str:
    url = "https://api.mymemory.translated.net/get"
    chunk = text if len(text) <= 450 else text[:447] + "..."
    r = requests.get(url, params={"q": chunk, "langpair": f"en|{tl}"}, timeout=20)
    r.raise_for_status()
    data = r.json()
    if int(data.get("responseStatus", 0)) != 200:
        raise RuntimeError(data.get("responseDetails") or "mymemory error")
    translated = (data.get("responseData") or {}).get("translatedText") or ""
    if not translated or translated.upper().startswith("MYMEMORY WARNING"):
        raise RuntimeError(translated or "empty mymemory translation")
    return translated


def google_translate(text: str, tl: str) -> str:
    url = "https://translate.googleapis.com/translate_a/single"
    params = {"client": "gtx", "sl": "en", "tl": tl, "dt": "t", "q": text}
    r = requests.get(url, params=params, timeout=12)
    r.raise_for_status()
    data = r.json()
    return "".join(part[0] for part in data[0] if part and part[0])


def translate_one(en: str, tl: str) -> str:
    protected, tokens = protect(en)
    for attempt in range(6):
        try:
            translated = (
                mymemory_translate(protected, tl)
                if attempt % 2 == 0
                else google_translate(protected, tl)
            )
            if translated:
                return restore(translated, tokens).replace("  ", " ").strip()
        except Exception:  # noqa: BLE001
            time.sleep(1.2 * (attempt + 1))
    return en


def load_maps(locales: list[str]) -> dict[str, dict[str, str]]:
    maps: dict[str, dict[str, str]] = {}
    for loc in locales:
        path = TRANS_DIR / f"{loc}.json"
        if path.exists():
            maps[loc] = {str(k): str(v) for k, v in json.loads(path.read_text(encoding="utf-8")).items()}
        else:
            maps[loc] = {}
    return maps


def all_phrase_dicts() -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    for bag in (
        APP_SHORTCUT_PHRASES,
        UI_STRINGS,
        MORE_UI,
        EXAMPLE_PHRASES,
        INFO_PLIST_STRINGS,
        SIRI_DIALOG_STRINGS,
    ):
        out.update(bag)
    return out


def main() -> int:
    only = sys.argv[1:]
    locales = [loc for loc in NEW_LOCALES if loc in LOCALES and (not only or loc in only)]
    maps = load_maps(locales)
    phrases = all_phrase_dicts()

    overlay: dict[str, dict[str, str]] = {}
    if OUT_PATH.exists():
        try:
            overlay = json.loads(OUT_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            overlay = {}

    jobs: list[tuple[str, str, str]] = []  # key, locale, en
    for key, translations in phrases.items():
        en = translations.get("en", key)
        for loc in locales:
            if loc in translations:
                continue
            existing = overlay.get(key, {}).get(loc)
            if existing:
                continue
            mapped = maps[loc].get(en)
            if mapped:
                overlay.setdefault(key, {})[loc] = mapped
                continue
            jobs.append((key, loc, en))

    print(f"Locales={locales} mapped_fill={sum(len(v) for v in overlay.values())} pending_translate={len(jobs)}")

    def work(job: tuple[str, str, str]) -> tuple[str, str, str]:
        key, loc, en = job
        return key, loc, translate_one(en, GCODES[loc])

    done = 0
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(work, job) for job in jobs]
        for fut in as_completed(futures):
            key, loc, value = fut.result()
            overlay.setdefault(key, {})[loc] = value
            done += 1
            if done % 25 == 0 or done == len(jobs):
                OUT_PATH.write_text(
                    json.dumps(overlay, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )
                print(f"translated {done}/{len(jobs)}", flush=True)

    OUT_PATH.write_text(json.dumps(overlay, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_PATH.relative_to(ROOT)} keys={len(overlay)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
