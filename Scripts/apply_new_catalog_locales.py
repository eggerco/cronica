#!/usr/bin/env python3
"""Merge new-locale translations into Shared/Localization/Localizable.xcstrings.

Reads per-locale JSON maps (English source → translation) from:
  Scripts/translations/new_locales/<locale>.json

Also derives pt-PT from existing pt-BR with European Portuguese substitutions
when a key is missing from the pt-PT map.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS = ROOT / "Shared/Localization/Localizable.xcstrings"
TRANS_DIR = Path(__file__).resolve().parent / "translations" / "new_locales"

NEW_LOCALES = (
    "bn", "ca", "gu", "kn", "ml", "mr", "or", "pt-PT", "pa",
    "sl", "ta", "te", "th", "ur", "vi",
)

# Common BR → PT (Portugal) UI substitutions applied when deriving missing keys.
PT_BR_TO_PT_PT = (
    (r"\bvocê\b", "tu"),
    (r"\bVocê\b", "Tu"),
    (r"\bcelular\b", "telemóvel"),
    (r"\bCelular\b", "Telemóvel"),
    (r"\btela\b", "ecrã"),
    (r"\bTela\b", "Ecrã"),
    (r"\barquivo\b", "ficheiro"),
    (r"\bArquivo\b", "Ficheiro"),
    (r"\barquivos\b", "ficheiros"),
    (r"\bArquivos\b", "Ficheiros"),
    (r"\busuário\b", "utilizador"),
    (r"\bUsuário\b", "Utilizador"),
    (r"\busuários\b", "utilizadores"),
    (r"\bUsuários\b", "Utilizadores"),
    (r"\bdeletar\b", "eliminar"),
    (r"\bDeletar\b", "Eliminar"),
    (r"\bsalvar\b", "guardar"),
    (r"\bSalvar\b", "Guardar"),
    (r"\bSenha\b", "Palavra-passe"),
    (r"\bsenha\b", "palavra-passe"),
    (r"\baplicativo\b", "aplicação"),
    (r"\bAplicativo\b", "Aplicação"),
    (r"\bconectado\b", "ligado"),
    (r"\bConectado\b", "Ligado"),
    (r"\bconectar\b", "ligar"),
    (r"\bConectar\b", "Ligar"),
    (r"\bconexão\b", "ligação"),
    (r"\bConexão\b", "Ligação"),
)


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def derive_pt_pt(pt_br: str) -> str:
    out = pt_br
    for pattern, repl in PT_BR_TO_PT_PT:
        out = re.sub(pattern, repl, out)
    return out


def load_locale_map(locale: str) -> dict[str, str]:
    path = TRANS_DIR / f"{locale}.json"
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit(f"{path}: expected object map")
    return {str(k): str(v) for k, v in data.items()}


def english_of(key: str, entry: dict) -> str:
    locs = entry.get("localizations") or {}
    en = locs.get("en", {}).get("stringUnit", {}).get("value")
    return en if en is not None else key


def main() -> int:
    maps = {loc: load_locale_map(loc) for loc in NEW_LOCALES}
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    strings = data["strings"]

    counts = {loc: 0 for loc in NEW_LOCALES}
    missing: dict[str, list[str]] = {loc: [] for loc in NEW_LOCALES}

    for key, entry in strings.items():
        if entry.get("shouldTranslate") is False:
            continue
        locs = entry.setdefault("localizations", {})
        en = english_of(key, entry)

        for locale in NEW_LOCALES:
            value = maps[locale].get(en)
            if value is None and locale == "pt-PT":
                pt_br = locs.get("pt-BR", {}).get("stringUnit", {}).get("value")
                if pt_br is not None:
                    value = derive_pt_pt(pt_br)
            if value is None:
                missing[locale].append(en)
                continue
            locs[locale] = unit(value)
            counts[locale] += 1

    XCSTRINGS.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("Applied translations:")
    for locale in NEW_LOCALES:
        miss = len(missing[locale])
        print(f"  {locale:6} {counts[locale]:4} keys  (missing {miss})")

    report = TRANS_DIR / "_missing_report.json"
    report.write_text(
        json.dumps({k: v for k, v in missing.items() if v}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    total_missing = sum(len(v) for v in missing.values())
    if total_missing:
        print(f"\nMissing report: {report} ({total_missing} gaps)")
        return 1
    print("\nAll new locales fully applied.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
