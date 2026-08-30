#!/usr/bin/env python3
"""Translate fastlane/description/en-US.txt into every App Store locale.

Writes:
  fastlane/description/<locale>.txt

English variants (en-AU/CA/GB) copy en-US.
Uses MyMemory with Google Translate fallback. Protects brand / product names.
"""

from __future__ import annotations

import re
import sys
import time
from pathlib import Path
from typing import Optional

import requests

ROOT = Path(__file__).resolve().parents[1]
DESC_DIR = ROOT / "fastlane" / "description"
EN_PATH = DESC_DIR / "en-US.txt"

# deliver locale → MyMemory / Google target code
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

BRANDS = [
    "Apple Vision Pro",
    "Apple Watch",
    "Apple TV",
    "Control Center",
    "Home Screen",
    "Share Sheet",
    "App Shortcuts",
    "Watch Providers",
    "Watch provider",
    "watch provider",
    "Letterboxd",
    "JustWatch",
    "cronica.watch",
    "iPhone",
    "iPad",
    "iCloud",
    "Shortcuts",
    "Widgets",
    "Up Next",
    "Cronica",
    "SIMKL",
    "TMDb",
    "IMDb",
    "Siri",
    "Mac",
]

# Light European Portuguese tweaks when deriving from Brazilian Portuguese.
PT_BR_TO_PT_PT = (
    (r"\bvocê\b", "tu"),
    (r"\bVocê\b", "Tu"),
    (r"\bcelular\b", "telemóvel"),
    (r"\btela\b", "ecrã"),
    (r"\barquivo\b", "ficheiro"),
    (r"\busuário\b", "utilizador"),
    (r"\bdeletar\b", "eliminar"),
    (r"\bsalvar\b", "guardar"),
    (r"\baplicativo\b", "aplicação"),
    (r"\bAssistir\b", "Ver"),
)


def protect(text: str):
    tokens = []
    out = text
    for brand in sorted(BRANDS, key=len, reverse=True):
        if brand in out:
            tokens.append(brand)
            out = out.replace(brand, f"XTOK{len(tokens) - 1}X")
    return out, tokens


def restore(text: str, tokens) -> str:
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
    r = requests.get(url, params={"q": chunk, "langpair": f"en|{tl}"}, timeout=25)
    r.raise_for_status()
    data = r.json()
    if int(data.get("responseStatus", 0)) != 200:
        raise RuntimeError(data.get("responseDetails") or "mymemory error")
    translated = (data.get("responseData") or {}).get("translatedText") or ""
    if not translated or translated.upper().startswith("MYMEMORY WARNING"):
        raise RuntimeError(translated or "empty mymemory")
    return translated


def google_translate(text: str, tl: str) -> str:
    # Google uses short codes; map zh-CN/zh-TW.
    gcode = {"zh-CN": "zh-CN", "zh-TW": "zh-TW", "pt-PT": "pt"}.get(tl, tl)
    url = "https://translate.googleapis.com/translate_a/single"
    params = {"client": "gtx", "sl": "en", "tl": gcode, "dt": "t", "q": text}
    r = requests.get(url, params=params, timeout=25)
    r.raise_for_status()
    data = r.json()
    return "".join(part[0] for part in data[0] if part and part[0])


def translate_chunk(text: str, tl: str) -> str:
    protected, tokens = protect(text)
    last_err: Optional[Exception] = None
    backoff = 3.0
    # Keep trying — free APIs rate-limit; do not abort mid-document.
    for attempt in range(20):
        try:
            # Prefer MyMemory; alternate to Google occasionally.
            if attempt % 3 == 2:
                raw = google_translate(protected, tl)
            else:
                raw = mymemory_translate(protected, tl)
            if raw:
                return restore(raw, tokens).replace("  ", " ").strip()
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            msg = str(exc)
            if "429" in msg or "WARNING" in msg.upper() or "QUOTA" in msg.upper():
                print(f"    rate-limit ({tl}), sleep {backoff:.0f}s", flush=True)
                time.sleep(backoff)
                backoff = min(backoff * 1.6, 120)
            else:
                time.sleep(1.5)
    raise RuntimeError(f"failed after retries: {last_err}")


def translate_document(en: str, tl: str) -> str:
    # Translate paragraph-by-paragraph to stay under API size limits.
    parts = re.split(r"(\n\n+)", en)
    out = []
    for part in parts:
        if not part.strip() or part.startswith("\n"):
            out.append(part)
            continue
        # Further split long paragraphs by line if needed
        lines = part.split("\n")
        translated_lines = []
        for line in lines:
            if not line.strip():
                translated_lines.append(line)
                continue
            translated_lines.append(translate_chunk(line, tl))
            time.sleep(0.45)
        out.append("\n".join(translated_lines))
    return "".join(out).strip() + "\n"


def derive_pt_pt(pt_br: str) -> str:
    out = pt_br
    for pattern, repl in PT_BR_TO_PT_PT:
        out = re.sub(pattern, repl, out)
    return out


def main() -> int:
    if not EN_PATH.exists():
        raise SystemExit(f"Missing {EN_PATH}")
    en = EN_PATH.read_text(encoding="utf-8")
    if len(en) > 4000:
        print(f"WARNING: en-US description is {len(en)} chars (App Store limit 4000)", flush=True)

    force = "--force" in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    locales = [loc for loc in LOCALES if not only or loc in only]

    # Ensure English variants first
    for loc in locales:
        if loc in ENGLISH_LOCALES:
            path = DESC_DIR / f"{loc}.txt"
            path.write_text(en if en.endswith("\n") else en + "\n", encoding="utf-8")
            print(f"[{loc}] copied en-US ({len(en)} chars)", flush=True)

    # pt-BR before pt-PT for derivation fallback
    ordered = sorted(
        [loc for loc in locales if loc not in ENGLISH_LOCALES],
        key=lambda loc: (0 if loc == "pt-BR" else 1 if loc == "pt-PT" else 2, loc),
    )

    failures = []
    for loc in ordered:
        path = DESC_DIR / f"{loc}.txt"
        if path.exists() and not force:
            existing = path.read_text(encoding="utf-8").strip()
            if existing and existing != en.strip():
                print(f"[{loc}] skip existing ({len(existing)} chars)", flush=True)
                continue
        tl = LOCALES[loc]
        print(f"[{loc}] translating → {tl}…", flush=True)
        try:
            if loc == "pt-PT" and (DESC_DIR / "pt-BR.txt").exists():
                text = derive_pt_pt((DESC_DIR / "pt-BR.txt").read_text(encoding="utf-8"))
            else:
                text = translate_document(en, tl)
            if len(text) > 4000:
                print(f"  WARNING {len(text)} chars (limit 4000)", flush=True)
            path.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
            print(f"[{loc}] wrote {len(text)} chars", flush=True)
        except Exception as exc:  # noqa: BLE001
            print(f"[{loc}] FAIL: {exc}", flush=True)
            failures.append(loc)
            time.sleep(15)
            continue
        time.sleep(1.2)

    if failures:
        print(f"Failed locales ({len(failures)}): {', '.join(failures)}", flush=True)
        return 1
    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
