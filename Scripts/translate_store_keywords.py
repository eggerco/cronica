#!/usr/bin/env python3
"""Translate App Store keywords for every deliver locale via Google Cloud Translation.

Source keywords (English, deduplicated, Apple 100-char limit):
  watchlist,list,episode,tracker,movie,release,trailer,tmdb,watch,tvshow

Writes:
  fastlane/keywords/<locale>.txt
  fastlane/metadata/<locale>/keywords.txt

Brand token "tmdb" is never translated. English store locales copy the source string.
Ambiguous media terms are translated with short context; localized tokens are written
first, then any English originals that still fit under 100 characters (common ASO practice).
"""

from __future__ import annotations

import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KEYWORDS_DIR = ROOT / "fastlane" / "keywords"
METADATA_DIR = ROOT / "fastlane" / "metadata"

MAX_KEYWORDS_LEN = 100

# deliver locale → Cloud Translation target (matches translate_store_descriptions.py)
LOCALES = {
    "en-US": "en",
    "en-AU": "en",
    "en-CA": "en",
    "en-GB": "en",
    "ar-SA": "ar",
    "bn-BD": "bn",
    "ca": "ca",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
    "hr": "hr",
    "cs": "cs",
    "da": "da",
    "nl-NL": "nl",
    "fi": "fi",
    "fr-FR": "fr",
    "fr-CA": "fr",
    "de-DE": "de",
    "el": "el",
    "gu-IN": "gu",
    "he": "he",
    "hi": "hi",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "kn-IN": "kn",
    "ko": "ko",
    "ms": "ms",
    "ml-IN": "ml",
    "mr-IN": "mr",
    "no": "no",
    "or-IN": "or",
    "pl": "pl",
    "pt-BR": "pt",
    "pt-PT": "pt-PT",
    "pa-IN": "pa",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "sl-SI": "sl",
    "es-MX": "es",
    "es-ES": "es",
    "sv": "sv",
    "ta-IN": "ta",
    "te-IN": "te",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "ur-PK": "ur",
    "vi": "vi",
}

ENGLISH_LOCALES = {"en-US", "en-AU", "en-CA", "en-GB"}

# User-provided list with duplicates removed, stable order.
SOURCE_KEYWORDS = [
    "watchlist",
    "list",
    "episode",
    "tracker",
    "movie",
    "release",
    "trailer",
    "tmdb",
    "watch",
    "tvshow",
]

BRAND_TOKENS = {"tmdb", "imdb", "simkl", "cronica"}

# These are commonly searched in English on the App Store; raw MT often picks the
# wrong sense (trailer=vehicle, watch=timepiece). Keep English unless glossary overrides.
KEEP_ENGLISH = {"watchlist", "trailer", "tracker", "watch", "release"}

# Light context so MT prefers the entertainment sense. Multi-word results are
# reduced back to a single compact token in `keyword_from_translation`.
TRANSLATE_AS = {
    "watchlist": "watchlist",
    "list": "list",
    "episode": "episode",
    "tracker": "tracker",
    "movie": "movie",
    "release": "release",
    "trailer": "trailer",
    "watch": "watch",
    "tvshow": "tv show",
}

# Drop these when they appear as leftover context around media keywords.
CONTEXT_NOISE = {
    "film",
    "filme",
    "films",
    "movie",
    "movies",
    "cinema",
    "the",
    "a",
    "an",
    "de",
    "du",
    "la",
    "le",
    "el",
    "los",
    "las",
    "un",
    "una",
    "der",
    "die",
    "das",
    "فيلم",
    "الفيلم",
    "סרט",
    "הסרט",
    "映画",
    "영화",
    "영화의",
}

# High-confidence overrides when Cloud Translate picks the wrong sense.
GLOSSARY: dict[str, dict[str, str]] = {
    "de-DE": {
        "watchlist": "watchlist",
        "list": "liste",
        "episode": "folge",
        "tracker": "tracker",
        "movie": "film",
        "release": "erscheinung",
        "trailer": "trailer",
        "watch": "schauen",
        "tvshow": "serie",
    },
    "fr-FR": {
        "watchlist": "watchlist",
        "list": "liste",
        "episode": "episode",
        "tracker": "tracker",
        "movie": "film",
        "release": "sortie",
        "trailer": "bandeannonce",
        "watch": "regarder",
        "tvshow": "serie",
    },
    "fr-CA": {
        "watchlist": "watchlist",
        "list": "liste",
        "episode": "episode",
        "tracker": "tracker",
        "movie": "film",
        "release": "sortie",
        "trailer": "bandeannonce",
        "watch": "regarder",
        "tvshow": "serie",
    },
    "es-MX": {
        "watchlist": "watchlist",
        "list": "lista",
        "episode": "episodio",
        "tracker": "tracker",
        "movie": "pelicula",
        "release": "estreno",
        "trailer": "trailer",
        "watch": "ver",
        "tvshow": "serie",
    },
    "es-ES": {
        "watchlist": "watchlist",
        "list": "lista",
        "episode": "episodio",
        "tracker": "tracker",
        "movie": "pelicula",
        "release": "estreno",
        "trailer": "trailer",
        "watch": "ver",
        "tvshow": "serie",
    },
    "it": {
        "watchlist": "watchlist",
        "list": "lista",
        "episode": "episodio",
        "tracker": "tracker",
        "movie": "film",
        "release": "uscita",
        "trailer": "trailer",
        "watch": "guardare",
        "tvshow": "serie",
    },
    "pt-BR": {
        "watchlist": "watchlist",
        "list": "lista",
        "episode": "episodio",
        "tracker": "tracker",
        "movie": "filme",
        "release": "lancamento",
        "trailer": "trailer",
        "watch": "assistir",
        "tvshow": "serie",
    },
    "pt-PT": {
        "watchlist": "watchlist",
        "list": "lista",
        "episode": "episodio",
        "tracker": "tracker",
        "movie": "filme",
        "release": "lancamento",
        "trailer": "trailer",
        "watch": "ver",
        "tvshow": "serie",
    },
    "tr": {
        "watchlist": "izlemelistesi",
        "list": "liste",
        "episode": "bolum",
        "tracker": "tracker",
        "movie": "film",
        "release": "vizyon",
        "trailer": "fragman",
        "watch": "izle",
        "tvshow": "dizi",
    },
    "uk": {
        "watchlist": "вотчлист",
        "list": "список",
        "episode": "епізод",
        "tracker": "трекер",
        "movie": "фільм",
        "release": "реліз",
        "trailer": "трейлер",
        "watch": "дивитися",
        "tvshow": "серіал",
    },
    "ru": {
        "watchlist": "вотчлист",
        "list": "список",
        "episode": "эпизод",
        "tracker": "трекер",
        "movie": "фильм",
        "release": "релиз",
        "trailer": "трейлер",
        "watch": "смотреть",
        "tvshow": "сериал",
    },
    "ja": {
        "watchlist": "ウォッチリスト",
        "list": "リスト",
        "episode": "エピソード",
        "tracker": "トラッカー",
        "movie": "映画",
        "release": "公開",
        "trailer": "予告編",
        "watch": "視聴",
        "tvshow": "ドラマ",
    },
    "ko": {
        "watchlist": "관심목록",
        "list": "목록",
        "episode": "에피소드",
        "tracker": "트래커",
        "movie": "영화",
        "release": "개봉",
        "trailer": "예고편",
        "watch": "시청",
        "tvshow": "드라마",
    },
    "zh-Hans": {
        "watchlist": "片单",
        "list": "列表",
        "episode": "剧集",
        "tracker": "追踪",
        "movie": "电影",
        "release": "上映",
        "trailer": "预告片",
        "watch": "观看",
        "tvshow": "电视剧",
    },
    "zh-Hant": {
        "watchlist": "片單",
        "list": "列表",
        "episode": "劇集",
        "tracker": "追蹤",
        "movie": "電影",
        "release": "上映",
        "trailer": "預告片",
        "watch": "觀看",
        "tvshow": "電視劇",
    },
}


def collapse_token(text: str) -> str:
    t = text.strip().lower()
    t = t.replace("،", ",").replace("、", ",")
    t = re.sub(r"[,;/|]+", " ", t)
    t = re.sub(r"\s+", " ", t).strip()
    t = t.replace(" ", "")
    t = re.sub(r"[\"'`«»“”\-–—·]", "", t)
    t = re.sub(r"[\u0591-\u05C7\u064B-\u065F\u0670]", "", t)
    return t


def keyword_from_translation(source_kw: str, translated: str) -> str:
    """Pick a single App Store keyword token from an MT result."""
    words = [w for w in re.split(r"\s+", translated.strip()) if w]
    if not words:
        return source_kw

    cleaned = []
    for word in words:
        token = collapse_token(word)
        if not token:
            continue
        if token in CONTEXT_NOISE or word.casefold() in CONTEXT_NOISE:
            continue
        cleaned.append(token)

    if not cleaned:
        return collapse_token("".join(words)) or source_kw
    if len(cleaned) == 1:
        return cleaned[0]
    return "".join(cleaned)

def fit_keywords(parts: list[str], limit: int = MAX_KEYWORDS_LEN) -> str:
    kept: list[str] = []
    for part in parts:
        if not part:
            continue
        if any(part.casefold() == k.casefold() for k in kept):
            continue
        candidate = ",".join(kept + [part]) if kept else part
        if len(candidate) > limit:
            break
        kept.append(part)
    return ",".join(kept)


def write_locale(locale: str, body: str) -> None:
    KEYWORDS_DIR.mkdir(parents=True, exist_ok=True)
    meta = METADATA_DIR / locale
    meta.mkdir(parents=True, exist_ok=True)
    text = body.strip() + "\n"
    (KEYWORDS_DIR / f"{locale}.txt").write_text(text, encoding="utf-8")
    (meta / "keywords.txt").write_text(text, encoding="utf-8")


def main() -> int:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from cloud_translate import require_api_key, translate_batch

    require_api_key()

    en_body = fit_keywords(SOURCE_KEYWORDS)
    if len(en_body) > MAX_KEYWORDS_LEN:
        raise SystemExit(f"English keywords exceed {MAX_KEYWORDS_LEN} chars: {len(en_body)}")

    print(f"English source ({len(en_body)} chars): {en_body}")

    for locale, tl in LOCALES.items():
        if locale in ENGLISH_LOCALES or tl == "en":
            write_locale(locale, en_body)
            print(f"  {locale}: copy en ({len(en_body)})")
            continue

        glossary = GLOSSARY.get(locale, {})
        need_mt = [
            kw
            for kw in SOURCE_KEYWORDS
            if kw.casefold() not in BRAND_TOKENS
            and kw not in glossary
            and kw not in KEEP_ENGLISH
        ]
        mt_inputs = [TRANSLATE_AS.get(kw, kw) for kw in need_mt]
        translated = translate_batch(mt_inputs, tl) if mt_inputs else []
        mt_map = dict(zip(need_mt, translated))

        localized: list[str] = []
        for kw in SOURCE_KEYWORDS:
            if kw.casefold() in BRAND_TOKENS:
                localized.append(kw.lower())
            elif kw in glossary:
                localized.append(collapse_token(glossary[kw]))
            elif kw in KEEP_ENGLISH:
                localized.append(kw.lower())
            else:
                localized.append(keyword_from_translation(kw, mt_map[kw]))

        # Localized first, then English originals that still fit (helps EN searchers abroad).
        body = fit_keywords(localized + SOURCE_KEYWORDS)
        if not body:
            raise SystemExit(f"Empty keywords for {locale}")
        write_locale(locale, body)
        print(f"  {locale}: {len(body)} chars → {body}")
        time.sleep(0.12)

    print(f"Wrote {len(LOCALES)} locales under {KEYWORDS_DIR.relative_to(ROOT)} and metadata/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
