#!/usr/bin/env python3
"""Regenerate App Store descriptions with disambiguated English + Cloud Translation.

Keeps en-US/AU/CA/GB as the marketing English source.
Translates from a clarified English variant to avoid binge/shows MT errors.
"""

from __future__ import annotations

import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Scripts"))

from cloud_translate import require_api_key, translate_batch  # noqa: E402
from translate_store_descriptions import (  # noqa: E402
    BRANDS,
    DESC_DIR,
    ENGLISH_LOCALES,
    EN_PATH,
    LOCALES,
    derive_pt_pt,
    protect,
    restore,
)

# Clarifications only for the MT source — en-US file stays unchanged.
CLARIFY = [
    (
        "Whether you’re a binge-watcher or a casual viewer",
        "Whether you watch many episodes in a row or just occasionally",
    ),
    (
        "Whether you're a binge-watcher or a casual viewer",
        "Whether you watch many episodes in a row or just occasionally",
    ),
    (
        "Up Next: Stay Ahead of Your Shows",
        "Up Next: Stay Ahead of Your TV Series",
    ),
]


def clarify(en: str) -> str:
    out = en
    for a, b in CLARIFY:
        out = out.replace(a, b)
    return out


def translate_chunk(text: str, tl: str) -> str:
    protected, tokens = protect(text)
    raw = translate_batch([protected], tl)[0]
    return restore(raw, tokens).replace("  ", " ").strip()


def translate_document(en: str, tl: str) -> str:
    parts = re.split(r"(\n\n+)", en)
    out = []
    for part in parts:
        if not part.strip() or part.startswith("\n"):
            out.append(part)
            continue
        lines = part.split("\n")
        translated_lines = []
        for line in lines:
            if not line.strip():
                translated_lines.append(line)
                continue
            translated_lines.append(translate_chunk(line, tl))
            time.sleep(0.25)
        out.append("\n".join(translated_lines))
    return "".join(out).strip() + "\n"


def post_fix(text: str, loc: str) -> str:
    """Surgical fixes for lingering MT glitches."""
    fixes = [
        # Chinese: theatrical "演出" → TV series wording near Up Next
        ("让你的演出始终领先一步", "让你在剧集进度上始终领先一步"),
        ("讓你的演出始終領先一步", "讓你在劇集進度上始終領先一步"),
        # Korean binge-eating residue if any slip through
        ("폭식을 즐기는 사람이든", "많은 에피소드를 이어서 보는 사람이든"),
        # Hindi/Gujarati/Marathi nonsense binge residues
        ("द्वि घातुमान - दर्शक", "लगातार एपिसोड देखने वाले दर्शक"),
        ("દ્વિસંગી જોનાર", "એક પછી એક એપિસોડ જોનાર"),
        ("द्विधा मनस्थिती पाहणारे", "एकमागून एक भाग पाहणारे"),
    ]
    out = text
    for a, b in fixes:
        out = out.replace(a, b)
    return out


def main() -> int:
    require_api_key()
    en = EN_PATH.read_text(encoding="utf-8")
    src = clarify(en)

    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    locales = [loc for loc in LOCALES if not only or loc in only]

    for loc in locales:
        if loc in ENGLISH_LOCALES:
            path = DESC_DIR / f"{loc}.txt"
            path.write_text(en if en.endswith("\n") else en + "\n", encoding="utf-8")
            print(f"[{loc}] copied en-US", flush=True)

    ordered = sorted(
        [loc for loc in locales if loc not in ENGLISH_LOCALES],
        key=lambda loc: (0 if loc == "pt-BR" else 1 if loc == "pt-PT" else 2, loc),
    )

    failures = []
    for loc in ordered:
        path = DESC_DIR / f"{loc}.txt"
        tl = LOCALES[loc]
        print(f"[{loc}] translating → {tl}…", flush=True)
        try:
            if loc == "pt-PT" and (DESC_DIR / "pt-BR.txt").exists():
                # Prefer fresh pt-BR then derive
                text = derive_pt_pt((DESC_DIR / "pt-BR.txt").read_text(encoding="utf-8"))
            else:
                text = translate_document(src, tl)
            text = post_fix(text, loc)
            if len(text) > 4000:
                print(f"  WARNING {len(text)} chars", flush=True)
            path.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
            print(f"[{loc}] wrote {len(text)} chars", flush=True)
        except Exception as exc:  # noqa: BLE001
            print(f"[{loc}] FAIL: {exc}", flush=True)
            failures.append(loc)
            time.sleep(10)
            continue
        time.sleep(0.4)

    if failures:
        print(f"Failed: {failures}", flush=True)
        return 1
    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
