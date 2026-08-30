#!/usr/bin/env python3
"""Google Cloud Translation API (v2) helper for Cronica localization scripts.

Auth (first match wins):
  1. GOOGLE_TRANSLATE_API_KEY environment variable
  2. Scripts/google_translate_api_key (single-line file, gitignored)
  3. Scripts/google_translate_api_key.json → {"api_key": "..."}

Usage:
  from cloud_translate import translate_batch, require_api_key
  require_api_key()
  out = translate_batch(["Hello", "Watchlist"], "vi")
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Optional

import requests

SCRIPTS_DIR = Path(__file__).resolve().parent
API_URL = "https://translation.googleapis.com/language/translate/v2"

# Cloud Translation language codes (target).
# https://cloud.google.com/translate/docs/languages
CLOUD_CODES = {
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
    "pt": "pt",
    "pt-PT": "pt",
    "pt-BR": "pt",
    "zh-CN": "zh-CN",
    "zh-TW": "zh-TW",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
    "ar": "ar",
    "cs": "cs",
    "da": "da",
    "nl": "nl",
    "fi": "fi",
    "fr": "fr",
    "de": "de",
    "el": "el",
    "he": "he",
    "hi": "hi",
    "hr": "hr",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "ms": "ms",
    "no": "no",
    "nb": "no",
    "pl": "pl",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "es": "es",
    "sv": "sv",
    "tr": "tr",
    "uk": "uk",
}

# Keep batches modest — token-protected strings can be long.
DEFAULT_BATCH_SIZE = 40


def load_api_key() -> Optional[str]:
    env = os.environ.get("GOOGLE_TRANSLATE_API_KEY", "").strip()
    if env:
        return env

    plain = SCRIPTS_DIR / "google_translate_api_key"
    if plain.exists():
        key = plain.read_text(encoding="utf-8").strip().splitlines()[0].strip()
        if key and not key.startswith("#"):
            return key

    json_path = SCRIPTS_DIR / "google_translate_api_key.json"
    if json_path.exists():
        data = json.loads(json_path.read_text(encoding="utf-8"))
        key = (data.get("api_key") or data.get("key") or "").strip()
        if key:
            return key

    return None


def require_api_key() -> str:
    key = load_api_key()
    if key:
        return key
    raise SystemExit(
        "Google Cloud Translation API key required.\n\n"
        "1. Create a key: Google Cloud Console → APIs & Services → Credentials\n"
        "   Enable \"Cloud Translation API\", then create an API key.\n"
        "2. Store it (gitignored):\n"
        "     echo 'YOUR_KEY' > Scripts/google_translate_api_key\n"
        "   or export GOOGLE_TRANSLATE_API_KEY=YOUR_KEY\n"
        "See Docs/LOCALIZATION.md for details."
    )


def cloud_code(locale: str) -> str:
    return CLOUD_CODES.get(locale, locale)


def translate_batch(
    texts: list[str],
    target_locale: str,
    *,
    api_key: Optional[str] = None,
    source: str = "en",
    retries: int = 5,
) -> list[str]:
    """Translate a list of strings with Cloud Translation v2. Preserves order."""
    if not texts:
        return []
    key = api_key or require_api_key()
    target = cloud_code(target_locale)
    payload = {
        "q": texts,
        "source": source,
        "target": target,
        "format": "text",
    }
    last_err: Optional[Exception] = None
    backoff = 1.5
    for attempt in range(retries):
        try:
            r = requests.post(
                API_URL,
                params={"key": key},
                json=payload,
                timeout=60,
            )
            if r.status_code == 429:
                raise RuntimeError(f"429 Too Many Requests: {r.text[:200]}")
            if r.status_code >= 400:
                raise RuntimeError(f"HTTP {r.status_code}: {r.text[:400]}")
            data = r.json()
            translations = data["data"]["translations"]
            if len(translations) != len(texts):
                raise RuntimeError(
                    f"expected {len(texts)} translations, got {len(translations)}"
                )
            return [t["translatedText"] for t in translations]
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            time.sleep(backoff)
            backoff = min(backoff * 1.8, 60)
    raise RuntimeError(f"Cloud Translation failed after retries: {last_err}")


def translate_batched(
    texts: list[str],
    target_locale: str,
    *,
    batch_size: int = DEFAULT_BATCH_SIZE,
    api_key: Optional[str] = None,
    pause_s: float = 0.15,
) -> list[str]:
    """Translate many strings in chunks."""
    key = api_key or require_api_key()
    out: list[str] = []
    for i in range(0, len(texts), batch_size):
        chunk = texts[i : i + batch_size]
        out.extend(translate_batch(chunk, target_locale, api_key=key))
        if i + batch_size < len(texts) and pause_s > 0:
            time.sleep(pause_s)
    return out
