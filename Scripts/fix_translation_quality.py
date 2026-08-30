#!/usr/bin/env python3
"""Fix known MT quality issues in Localizable.xcstrings.

- Curated TV-domain glossary (Seasons, Episodes, Notifications, …)
- Re-translate remaining English stubs via Cloud Translation (with context)
- Patch known wristwatch / weather-season mistranslations in longer strings
"""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Scripts"))

from check_localization import ALLOW_IDENTICAL, CATALOG_LOCALES, is_format_only  # noqa: E402
from cloud_translate import require_api_key, translate_batched  # noqa: E402

XCSTRINGS = ROOT / "Shared/Localization/Localizable.xcstrings"

# Proper TV / product terms — do not rely on raw MT for these.
# Values are full replacements for the English key/value.
GLOSSARY: dict[str, dict[str, str]] = {
    "Seasons": {
        "ar": "مواسم",
        "bn": "সিজন",
        "ca": "Temporades",
        "cs": "Sezóny",
        "da": "Sæsoner",
        "de": "Staffeln",
        "el": "Σεζόν",
        "es": "Temporadas",
        "es-MX": "Temporadas",
        "fi": "Kaudet",
        "fr": "Saisons",
        "gu": "સીઝન",
        "he": "עונות",
        "hi": "सीज़न",
        "hr": "Sezone",
        "hu": "Évadok",
        "id": "Musim",
        "it": "Stagioni",
        "ja": "シーズン",
        "kn": "ಸೀಸನ್‌ಗಳು",
        "ko": "시즌",
        "ml": "സീസണുകൾ",
        "mr": "सीझन्स",
        "ms": "Musim",
        "nb": "Sesonger",
        "nl": "Seizoenen",
        "or": "ସିଜନ୍",
        "pa": "ਸੀਜ਼ਨ",
        "pl": "Sezony",
        "pt-BR": "Temporadas",
        "pt-PT": "Temporadas",
        "ro": "Sezoane",
        "ru": "Сезоны",
        "sk": "Série",
        "sl": "Sezone",
        "sv": "Säsonger",
        "ta": "சீசன்கள்",
        "te": "సీజన్లు",
        "th": "ซีซัน",
        "tr": "Sezonlar",
        "uk": "Сезони",
        "ur": "سیزنز",
        "vi": "Mùa",
        "zh-Hans": "季",
        "zh-Hant": "季",
    },
    "Episodes": {
        "ar": "حلقات",
        "bn": "এপিসোড",
        "ca": "Episodis",
        "cs": "Epizody",
        "da": "Episoder",
        "de": "Episoden",
        "el": "Επεισόδια",
        "es": "Episodios",
        "es-MX": "Episodios",
        "fi": "Jaksot",
        "fr": "Épisodes",
        "gu": "એપિસોડ",
        "he": "פרקים",
        "hi": "एपिसोड",
        "hr": "Epizode",
        "hu": "Epizódok",
        "id": "Episode",
        "it": "Episodi",
        "ja": "エピソード",
        "kn": "ಎಪಿಸೋಡ್‌ಗಳು",
        "ko": "에피소드",
        "ml": "എപ്പിസോഡുകൾ",
        "mr": "एपिसोड",
        "ms": "Episod",
        "nb": "Episoder",
        "nl": "Afleveringen",
        "or": "ଏପିସୋଡ୍",
        "pa": "ਐਪੀਸੋਡ",
        "pl": "Odcinki",
        "pt-BR": "Episódios",
        "pt-PT": "Episódios",
        "ro": "Episoade",
        "ru": "Эпизоды",
        "sk": "Epizódy",
        "sl": "Epizode",
        "sv": "Avsnitt",
        "ta": "எபிசோடுகள்",
        "te": "ఎపిసోడ్‌లు",
        "th": "ตอน",
        "tr": "Bölümler",
        "uk": "Епізоди",
        "ur": "اقساط",
        "vi": "Tập",
        "zh-Hans": "集",
        "zh-Hant": "集",
    },
    "Notifications": {
        "ar": "الإشعارات",
        "bn": "বিজ্ঞপ্তি",
        "ca": "Notificacions",
        "cs": "Oznámení",
        "da": "Meddelelser",
        "de": "Mitteilungen",
        "el": "Ειδοποιήσεις",
        "es": "Notificaciones",
        "es-MX": "Notificaciones",
        "fi": "Ilmoitukset",
        "fr": "Notifications",
        "gu": "સૂચનાઓ",
        "he": "התראות",
        "hi": "सूचनाएँ",
        "hr": "Obavijesti",
        "hu": "Értesítések",
        "id": "Notifikasi",
        "it": "Notifiche",
        "ja": "通知",
        "kn": "ಅಧಿಸೂಚನೆಗಳು",
        "ko": "알림",
        "ml": "അറിയിപ്പുകൾ",
        "mr": "सूचना",
        "ms": "Pemberitahuan",
        "nb": "Varsler",
        "nl": "Meldingen",
        "or": "ବିଜ୍ଞପ୍ତି",
        "pa": "ਸੂਚਨਾਵਾਂ",
        "pl": "Powiadomienia",
        "pt-BR": "Notificações",
        "pt-PT": "Notificações",
        "ro": "Notificări",
        "ru": "Уведомления",
        "sk": "Upozornenia",
        "sl": "Obvestila",
        "sv": "Aviseringar",
        "ta": "அறிவிப்புகள்",
        "te": "నోటిఫికేషన్లు",
        "th": "การแจ้งเตือน",
        "tr": "Bildirimler",
        "uk": "Сповіщення",
        "ur": "اطلاعات",
        "vi": "Thông báo",
        "zh-Hans": "通知",
        "zh-Hant": "通知",
    },
    "Adventure": {
        "ar": "مغامرة",
        "bn": "অ্যাডভেঞ্চার",
        "ca": "Aventura",
        "cs": "Dobrodružný",
        "da": "Eventyr",
        "de": "Abenteuer",
        "el": "Περιπέτεια",
        "es": "Aventura",
        "es-MX": "Aventura",
        "fi": "Seikkailu",
        "fr": "Aventure",
        "gu": "સાહસ",
        "he": "הרפתקאות",
        "hi": "रोमांच",
        "hr": "Avantura",
        "hu": "Kaland",
        "id": "Petualangan",
        "it": "Avventura",
        "ja": "アドベンチャー",
        "kn": "ಸಾಹಸ",
        "ko": "어드벤처",
        "ml": "സാഹസം",
        "mr": "साहस",
        "ms": "Pengembaraan",
        "nb": "Eventyr",
        "nl": "Avontuur",
        "or": "ଦୁଃସାହସିକ",
        "pa": "ਸਾਹਸ",
        "pl": "Przygodowy",
        "pt-BR": "Aventura",
        "pt-PT": "Aventura",
        "ro": "Aventură",
        "ru": "Приключения",
        "sk": "Dobrodružný",
        "sl": "Pustolovščina",
        "sv": "Äventyr",
        "ta": "சாகசம்",
        "te": "సాహసం",
        "th": "ผจญภัย",
        "tr": "Macera",
        "uk": "Пригоди",
        "ur": "مہم جوئی",
        "vi": "Phiêu lưu",
        "zh-Hans": "冒险",
        "zh-Hant": "冒險",
    },
    "Watchlist": {
        "ar": "قائمة المشاهدة",
        "bn": "ওয়াচলিস্ট",
        "ca": "Llista",
        "cs": "Watchlist",
        "da": "Watchlist",
        "de": "Merkliste",
        "el": "Λίστα παρακολούθησης",
        "es": "Lista",
        "es-MX": "Lista",
        "fi": "Katselulista",
        "fr": "Ma liste",
        "gu": "વૉચલિસ્ટ",
        "he": "רשימת צפייה",
        "hi": "वॉचलिस्ट",
        "hr": "Popis",
        "hu": "Figyelőlista",
        "id": "Watchlist",
        "it": "Lista",
        "ja": "ウォッチリスト",
        "kn": "ವಾಚ್‌ಲಿಸ್ಟ್",
        "ko": "워치리스트",
        "ml": "വാച്ച്‌ലിസ്റ്റ്",
        "mr": "वॉचलिस्ट",
        "ms": "Watchlist",
        "nb": "Watchlist",
        "nl": "Watchlist",
        "or": "ୱାଚଲିଷ୍ଟ",
        "pa": "ਵਾਚਲਿਸਟ",
        "pl": "Lista do obejrzenia",
        "pt-BR": "Lista",
        "pt-PT": "Lista",
        "ro": "Watchlist",
        "ru": "Список",
        "sk": "Sledované",
        "sl": "Seznam za ogled",
        "sv": "Watchlist",
        "ta": "வாட்ச்லிஸ்ட்",
        "te": "వాచ్‌లిస్ట్",
        "th": "รายการดู",
        "tr": "İzleme Listesi",
        "uk": "Список",
        "ur": "واچ لسٹ",
        "vi": "Danh sách theo dõi",
        "zh-Hans": "观看清单",
        "zh-Hant": "觀看清單",
    },
    "Up Next": {
        "ar": "التالي",
        "bn": "এরপরে",
        "ca": "A continuació",
        "cs": "Další",
        "da": "Næste",
        "de": "Als Nächstes",
        "el": "Επόμενα",
        "es": "A continuación",
        "es-MX": "A continuación",
        "fi": "Seuraavaksi",
        "fr": "Suivant",
        "gu": "આગળ",
        "he": "הבא בתור",
        "hi": "अगला",
        "hr": "Sljedeće",
        "hu": "Következő",
        "id": "Berikutnya",
        "it": "A seguire",
        "ja": "次に見る",
        "kn": "ಮುಂದೆ",
        "ko": "다음 시청",
        "ml": "അടുത്തത്",
        "mr": "पुढे",
        "ms": "Seterusnya",
        "nb": "Neste",
        "nl": "Hierna",
        "or": "ପରବର୍ତ୍ତୀ",
        "pa": "ਅੱਗੇ",
        "pl": "Następne",
        "pt-BR": "A seguir",
        "pt-PT": "A Seguir",
        "ro": "Urmează",
        "ru": "Далее",
        "sk": "Ďalej",
        "sl": "Naprej",
        "sv": "Härnäst",
        "ta": "அடுத்து",
        "te": "తదుపరి",
        "th": "ถัดไป",
        "tr": "Sırada",
        "uk": "Далі",
        "ur": "اگلا",
        "vi": "Tiếp theo",
        "zh-Hans": "接下来观看",
        "zh-Hant": "接下來觀看",
    },
}

# Format-string templates: English token → per-locale word used inside formats.
FORMAT_WORDS: dict[str, dict[str, str]] = {
    "hours": {
        "bn": "ঘন্টা", "ca": "hores", "cs": "hodin", "da": "timer", "de": "Stunden",
        "el": "ώρες", "es": "horas", "es-MX": "horas", "fi": "tuntia", "fr": "heures",
        "gu": "કલાક", "he": "שעות", "hi": "घंटे", "hr": "sati", "hu": "óra",
        "id": "jam", "it": "ore", "ja": "時間", "kn": "ಗಂಟೆಗಳು", "ko": "시간",
        "ml": "മണിക്കൂർ", "mr": "तास", "ms": "jam", "nb": "timer", "nl": "uur",
        "or": "ଘଣ୍ଟା", "pa": "ਘੰਟੇ", "pl": "godz.", "pt-BR": "horas", "pt-PT": "horas",
        "ro": "ore", "ru": "ч", "sk": "hodín", "sl": "ur", "sv": "timmar",
        "ta": "மணிநேரம்", "te": "గంటలు", "th": "ชั่วโมง", "tr": "saat", "uk": "год",
        "ur": "گھنٹے", "vi": "giờ", "zh-Hans": "小时", "zh-Hant": "小時", "ar": "ساعات",
    },
    "watched": {
        "bn": "দেখা হয়েছে", "ca": "vist", "cs": "zhlédnuto", "da": "set", "de": "gesehen",
        "el": "προβλήθηκε", "es": "visto", "es-MX": "visto", "fi": "katsottu", "fr": "vu",
        "gu": "જોયેલું", "he": "נצפה", "hi": "देखा गया", "hr": "pogledano", "hu": "megnézve",
        "id": "ditonton", "it": "visto", "ja": "視聴済み", "kn": "ನೋಡಲಾಗಿದೆ", "ko": "시청함",
        "ml": "കണ്ടു", "mr": "पाहिले", "ms": "ditonton", "nb": "sett", "nl": "bekeken",
        "or": "ଦେଖାଯାଇଛି", "pa": "ਵੇਖਿਆ", "pl": "obejrzane", "pt-BR": "assistido", "pt-PT": "visto",
        "ro": "vizionat", "ru": "просмотрено", "sk": "pozreté", "sl": "ogledano", "sv": "sett",
        "ta": "பார்த்தது", "te": "చూశారు", "th": "ดูแล้ว", "tr": "izlendi", "uk": "переглянуто",
        "ur": "دیکھا گیا", "vi": "đã xem", "zh-Hans": "已观看", "zh-Hant": "已觀看", "ar": "تمت المشاهدة",
    },
    "items": {
        "bn": "আইটেম", "ca": "elements", "cs": "položek", "da": "elementer", "de": "Einträge",
        "el": "στοιχεία", "es": "elementos", "es-MX": "elementos", "fi": "kohdetta", "fr": "éléments",
        "gu": "આઇટમ", "he": "פריטים", "hi": "आइटम", "hr": "stavki", "hu": "elem",
        "id": "item", "it": "elementi", "ja": "件", "kn": "ಐಟಂಗಳು", "ko": "개",
        "ml": "ഇനങ്ങൾ", "mr": "आयटम", "ms": "item", "nb": "elementer", "nl": "items",
        "or": "ଆଇଟମ୍", "pa": "ਆਈਟਮਾਂ", "pl": "pozycji", "pt-BR": "itens", "pt-PT": "itens",
        "ro": "elemente", "ru": "элементов", "sk": "položiek", "sl": "elementov", "sv": "objekt",
        "ta": "உருப்படிகள்", "te": "అంశాలు", "th": "รายการ", "tr": "öğe", "uk": "елементів",
        "ur": "آئٹمز", "vi": "mục", "zh-Hans": "项", "zh-Hant": "項", "ar": "عناصر",
    },
    "hr": {
        "bn": "ঘণ্টা", "ca": "h", "cs": "h", "da": "t", "de": "Std.",
        "el": "ώ", "es": "h", "es-MX": "h", "fi": "t", "fr": "h",
        "gu": "કલાક", "he": "שע׳", "hi": "घं", "hr": "h", "hu": "ó",
        "id": "j", "it": "h", "ja": "時間", "kn": "ಗಂ", "ko": "시간",
        "ml": "മ", "mr": "ता", "ms": "j", "nb": "t", "nl": "u",
        "or": "ଘ", "pa": "ਘੰ", "pl": "godz.", "pt-BR": "h", "pt-PT": "h",
        "ro": "h", "ru": "ч", "sk": "h", "sl": "h", "sv": "tim",
        "ta": "மணி", "te": "గం", "th": "ชม.", "tr": "sa", "uk": "год",
        "ur": "گھن", "vi": "giờ", "zh-Hans": "小时", "zh-Hant": "小時", "ar": "س",
    },
    "min": {
        "bn": "মিনিট", "ca": "min", "cs": "min", "da": "min", "de": "Min.",
        "el": "λεπ", "es": "min", "es-MX": "min", "fi": "min", "fr": "min",
        "gu": "મિનિટ", "he": "דק׳", "hi": "मि", "hr": "min", "hu": "perc",
        "id": "mnt", "it": "min", "ja": "分", "kn": "ನಿಮಿ", "ko": "분",
        "ml": "മിനിറ്റ്", "mr": "मि", "ms": "min", "nb": "min", "nl": "min",
        "or": "ମି", "pa": "ਮਿੰ", "pl": "min", "pt-BR": "min", "pt-PT": "min",
        "ro": "min", "ru": "мин", "sk": "min", "sl": "min", "sv": "min",
        "ta": "நிமி", "te": "ని", "th": "นาที", "tr": "dk", "uk": "хв",
        "ur": "منٹ", "vi": "phút", "zh-Hans": "分钟", "zh-Hant": "分鐘", "ar": "د",
    },
}

# Brand / legal / proper names that may stay English.
EXTRA_ALLOW = {
    "SIMKL API Rules", "SIMKL Website", "TMDB API Terms", "TMDB Terms", "TMDB Website",
    "Belgium", "Croatia", "Denmark", "Finland", "Hungary", "Ireland", "Lithuania",
    "New Zealand", "Norway", "Poland", "Sweden", "Switzerland", "United Kingdom",
    "Lavender", "Mint", "Teal", "Pink", "Turquoise Blue", "Fireball",
    "Slovak", "Superhero", "iCloud Sync",
}

# English → contextual paraphrase sent to Cloud Translation (then placeholders restored).
CONTEXT_HINTS: dict[str, str] = {
    "Link": "Link (URL)",
    "Person": "Person (cast member)",
    "Edit": "Edit (verb)",
    "Example": "Example (sample)",
    "Card": "Card (UI card)",
    "Details": "Details (info)",
    "Filters": "Filters (list filters)",
    "Pins": "Pins (pinned items)",
    "Query": "Query (search query)",
    "Rating": "Rating (score)",
    "Release": "Release (publication)",
    "Series": "Series (TV series)",
    "Week": "Week (calendar)",
    "Information": "Information",
    "Presentation": "Presentation (display style)",
    "Trending": "Trending (popular titles)",
    "Adventure": "Adventure (film genre)",
}

PLACEHOLDER_RE = re.compile(
    r"(%(?:\d+\$)?[#0\- +]*(?:\d+)?(?:\.\d+)?(?:ll|l|h)?[@dDuUxXoOfeEgGcCsSpaAF]|%%|\$\{[^}]+\})"
)


def protect_placeholders(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(m: re.Match[str]) -> str:
        tokens.append(m.group(0))
        return f"⟦PH{len(tokens) - 1}⟧"

    return PLACEHOLDER_RE.sub(repl, text), tokens


def restore_placeholders(text: str, tokens: list[str]) -> str:
    out = text
    for i, tok in enumerate(tokens):
        for needle in (f"⟦PH{i}⟧", f"[PH{i}]", f"(PH{i})", f"PH{i}"):
            if needle in out:
                out = out.replace(needle, tok)
                break
    return out


def set_value(entry: dict, locale: str, value: str) -> None:
    locs = entry.setdefault("localizations", {})
    locs[locale] = {"stringUnit": {"state": "translated", "value": value}}


def apply_glossary(strings: dict) -> int:
    changed = 0
    for en_key, per_locale in GLOSSARY.items():
        # Find by English value or exact key
        targets = []
        if en_key in strings:
            targets.append(strings[en_key])
        for entry in strings.values():
            en = (entry.get("localizations") or {}).get("en", {}).get("stringUnit", {}).get("value")
            if en == en_key and entry not in targets:
                targets.append(entry)
        for entry in targets:
            for loc, val in per_locale.items():
                cur = (entry.get("localizations") or {}).get(loc, {}).get("stringUnit", {}).get("value")
                if cur != val:
                    set_value(entry, loc, val)
                    changed += 1
    return changed


def apply_format_templates(strings: dict) -> int:
    """Fix common format strings using glossary words."""
    changed = 0
    templates = {
        "%lld Seasons • %lld Episodes": lambda loc: (
            f"%lld {GLOSSARY['Seasons'][loc]} • %lld {GLOSSARY['Episodes'][loc]}"
        ),
        "%@ Seasons • %@ Episodes": lambda loc: (
            f"%@ {GLOSSARY['Seasons'][loc]} • %@ {GLOSSARY['Episodes'][loc]}"
        ),
        "%1$.1f hours": lambda loc: f"%1$.1f {FORMAT_WORDS['hours'][loc]}",
        "%.1f hours": lambda loc: f"%.1f {FORMAT_WORDS['hours'][loc]}",
        "%d%% watched": lambda loc: f"%d%% {FORMAT_WORDS['watched'][loc]}",
        "%lld items": lambda loc: f"%lld {FORMAT_WORDS['items'][loc]}",
        "%lld hr %lld min": lambda loc: (
            f"%lld {FORMAT_WORDS['hr'][loc]} %lld {FORMAT_WORDS['min'][loc]}"
        ),
        "Version %@ • %@": lambda loc: {
            "bn": "সংস্করণ %@ • %@", "gu": "સંસ્કરણ %@ • %@", "hi": "संस्करण %@ • %@",
            "kn": "ಆವೃತ್ತಿ %@ • %@", "ml": "പതിപ്പ് %@ • %@", "mr": "आवृत्ती %@ • %@",
            "or": "ସଂସ୍କରଣ %@ • %@", "pa": "ਵਰਜਨ %@ • %@", "sl": "Različica %@ • %@",
            "ta": "பதிப்பு %@ • %@", "te": "వెర్షన్ %@ • %@", "th": "เวอร์ชัน %@ • %@",
            "ur": "ورژن %@ • %@", "vi": "Phiên bản %@ • %@", "da": "Version %@ • %@",
            "ja": "バージョン %@ • %@", "ko": "버전 %@ • %@", "zh-Hans": "版本 %@ • %@",
            "zh-Hant": "版本 %@ • %@", "ar": "الإصدار %@ • %@", "de": "Version %@ • %@",
            "fr": "Version %@ • %@", "nl": "Versie %@ • %@", "nb": "Versjon %@ • %@",
            "sv": "Version %@ • %@", "pl": "Wersja %@ • %@", "ru": "Версия %@ • %@",
            "uk": "Версія %@ • %@", "tr": "Sürüm %@ • %@", "cs": "Verze %@ • %@",
            "hu": "Verzió %@ • %@", "ro": "Versiunea %@ • %@", "hr": "Verzija %@ • %@",
            "id": "Versi %@ • %@", "ms": "Versi %@ • %@", "fi": "Versio %@ • %@",
            "el": "Έκδοση %@ • %@", "he": "גרסה %@ • %@", "ca": "Versió %@ • %@",
            "sk": "Verzia %@ • %@", "pt-BR": "Versão %@ • %@", "pt-PT": "Versão %@ • %@",
            "es": "Versión %@ • %@", "es-MX": "Versión %@ • %@", "it": "Versione %@ • %@",
        }.get(loc, f"Version %@ • %@"),
        "Rated %1$lld of 5": lambda loc: {
            "bn": "৫-এর মধ্যে %1$lld রেট করা হয়েছে", "gu": "5 માંથી %1$lld રેટેડ",
            "hi": "5 में से %1$lld रेटेड", "kn": "5 ರಲ್ಲಿ %1$lld ರೇಟ್",
            "ml": "5-ൽ %1$lld റേറ്റ് ചെയ്തു", "mr": "5 पैकी %1$lld रेटेड",
            "or": "5 ରୁ %1$lld ରେଟ୍", "pa": "5 ਵਿੱਚੋਂ %1$lld ਰੇਟਡ",
            "sl": "Ocena %1$lld od 5", "ta": "5-இல் %1$lld மதிப்பீடு",
            "te": "5లో %1$lld రేట్", "th": "ให้คะแนน %1$lld จาก 5",
            "ur": "5 میں سے %1$lld درجہ بندی", "vi": "Đánh giá %1$lld trên 5",
            "nl": "Beoordeling %1$lld van 5", "da": "Bedømt %1$lld af 5",
            "nb": "Vurdert %1$lld av 5", "sv": "Betygsatt %1$lld av 5",
            "de": "Bewertet mit %1$lld von 5", "fr": "Noté %1$lld sur 5",
            "ja": "5段階中%1$lld", "ko": "5점 만점에 %1$lld",
            "zh-Hans": "评为 %1$lld / 5", "zh-Hant": "評為 %1$lld / 5",
            "ar": "التقييم %1$lld من 5",
        }.get(loc, f"Rated %1$lld of 5"),
        "Rating star %@ of 5.": lambda loc: {
            "bn": "৫-এর মধ্যে রেটিং তারকা %@।", "gu": "5 માંથી રેટિંગ સ્ટાર %@.",
            "hi": "5 में से रेटिंग स्टार %@।", "kn": "5 ರಲ್ಲಿ ರೇಟಿಂಗ್ ನಕ್ಷತ್ರ %@.",
            "ml": "5-ൽ റേറ്റിംഗ് നക്ഷത്രം %@.", "mr": "5 पैकी रेटिंग तारा %@.",
            "or": "5 ରୁ ରେଟିଂ ତାରା %@.", "pa": "5 ਵਿੱਚੋਂ ਰੇਟਿੰਗ ਤਾਰਾ %@.",
            "sl": "Ocena z zvezdico %@ od 5.", "ta": "5-இல் மதிப்பீட்டு நட்சத்திரம் %@.",
            "te": "5లో రేటింగ్ నక్షత్రం %@.", "th": "ดาวคะแนน %@ จาก 5",
            "ur": "5 میں سے ریٹنگ ستارہ %@۔", "vi": "Ngôi sao đánh giá %@ trên 5.",
            "nl": "Beoordelingsster %@ van 5.", "da": "Bedømmelsesstjerne %@ af 5.",
            "de": "Bewertungsstern %@ von 5.", "fr": "Étoile de note %@ sur 5.",
            "ja": "5段階中の評価星%@。", "ko": "5점 만점 중 별점 %@.",
            "zh-Hans": "5 星中的第 %@ 星。", "zh-Hant": "5 星中的第 %@ 星。",
            "ar": "نجمة التقييم %@ من 5.",
        }.get(loc, f"Rating star %@ of 5."),
        "Rating star %lld of 5.": lambda loc: {
            "bn": "৫-এর মধ্যে রেটিং তারকা %lld।", "gu": "5 માંથી રેટિંગ સ્ટાર %lld.",
            "hi": "5 में से रेटिंग स्टार %lld।", "kn": "5 ರಲ್ಲಿ ರೇಟಿಂಗ್ ನಕ್ಷತ್ರ %lld.",
            "ml": "5-ൽ റേറ്റിംഗ് നക്ഷത്രം %lld.", "mr": "5 पैकी रेटिंग तारा %lld.",
            "or": "5 ରୁ ରେଟିଂ ତାରା %lld.", "pa": "5 ਵਿੱਚੋਂ ਰੇਟਿੰਗ ਤਾਰਾ %lld.",
            "sl": "Ocena z zvezdico %lld od 5.", "ta": "5-இல் மதிப்பீட்டு நட்சத்திரம் %lld.",
            "te": "5లో రేటింగ్ నక్షత్రం %lld.", "th": "ดาวคะแนน %lld จาก 5",
            "ur": "5 میں سے ریٹنگ ستارہ %lld۔", "vi": "Ngôi sao đánh giá %lld trên 5.",
            "nl": "Beoordelingsster %lld van 5.", "da": "Bedømmelsesstjerne %lld af 5.",
            "de": "Bewertungsstern %lld von 5.", "fr": "Étoile de note %lld sur 5.",
            "ja": "5段階中の評価星%lld。", "ko": "5점 만점 중 별점 %lld.",
            "zh-Hans": "5 星中的第 %lld 星。", "zh-Hant": "5 星中的第 %lld 星。",
            "ar": "نجمة التقييم %lld من 5.",
        }.get(loc, f"Rating star %lld of 5."),
        "SIMKL request failed (%lld).": lambda loc: {
            "bn": "SIMKL অনুরোধ ব্যর্থ হয়েছে (%lld)।", "gu": "SIMKL વિનંતી નિષ્ફળ (%lld).",
            "hi": "SIMKL अनुरोध विफल (%lld)।", "kn": "SIMKL ವಿನಂತಿ ವಿಫಲವಾಗಿದೆ (%lld).",
            "ml": "SIMKL അഭ്യർത്ഥന പരാജയപ്പെട്ടു (%lld).", "mr": "SIMKL विनंती अयशस्वी (%lld).",
            "or": "SIMKL ଅନୁରୋଧ ବିଫଳ (%lld).", "pa": "SIMKL ਬੇਨਤੀ ਅਸਫਲ (%lld).",
            "sl": "Zahteva SIMKL ni uspela (%lld).", "ta": "SIMKL கோரிக்கை தோல்வி (%lld).",
            "te": "SIMKL అభ్యర్థన విఫలమైంది (%lld).", "th": "คำขอ SIMKL ล้มเหลว (%lld)",
            "ur": "SIMKL درخواست ناکام (%lld)۔", "vi": "Yêu cầu SIMKL thất bại (%lld).",
            "nl": "SIMKL-verzoek mislukt (%lld).", "da": "SIMKL-anmodning mislykkedes (%lld).",
            "de": "SIMKL-Anfrage fehlgeschlagen (%lld).", "fr": "Échec de la requête SIMKL (%lld).",
            "ja": "SIMKLリクエストに失敗しました（%lld）。", "ko": "SIMKL 요청 실패(%lld).",
            "zh-Hans": "SIMKL 请求失败（%lld）。", "zh-Hant": "SIMKL 請求失敗（%lld）。",
            "ar": "فشل طلب SIMKL (%lld).",
        }.get(loc, f"SIMKL request failed (%lld)."),
    }

    for en_template, builder in templates.items():
        for key, entry in strings.items():
            en = (entry.get("localizations") or {}).get("en", {}).get("stringUnit", {}).get("value")
            if en != en_template and key != en_template:
                continue
            for loc in CATALOG_LOCALES:
                if loc == "en":
                    continue
                try:
                    new_val = builder(loc)
                except KeyError:
                    continue
                cur = (entry.get("localizations") or {}).get(loc, {}).get("stringUnit", {}).get("value")
                if cur != new_val:
                    set_value(entry, loc, new_val)
                    changed += 1
    return changed


def patch_wristwatch_mistranslations(strings: dict) -> int:
    """Fix 'watches' mistranslated as timepieces in SIMKL sync copy."""
    changed = 0
    needle_en = "When enabled, watches, ratings, archive, and removals in Cronica"
    replacements = {
        "gu": (
            "જ્યારે સક્ષમ હોય, ત્યારે Cronicaમાં જોવાની નોંધો, રેટિંગ્સ, આર્કાઇવ અને કાઢી નાખવાની "
            "ક્રિયાઓ કતારબદ્ધ થઈને SIMKL પર મોકલાય છે. મૂળભૂત રીતે બંધ."
        ),
        "mr": (
            "सक्षम केल्यावर, Cronica मधील पाहिलेले आयटम, रेटिंग, संग्रहण आणि काढून टाकणे रांगेत "
            "टाकून SIMKL वर पाठवले जातात. डीफॉल्टनुसार बंद."
        ),
        "hi": (
            "सक्षम होने पर Cronica में देखे गए आइटम, रेटिंग, आर्काइव और हटाना कतार में लगकर "
            "SIMKL को भेजे जाते हैं। डिफ़ॉल्ट रूप से बंद।"
        ),
        "bn": (
            "সক্রিয় করা হলে, Cronica-এর দেখা আইটেম, রেটিং, আর্কাইভ এবং অপসারণ কিউতে যুক্ত হয়ে "
            "SIMKL-এ পাঠানো হয়। ডিফল্টরূপে এটি বন্ধ থাকে।"
        ),
    }
    for entry in strings.values():
        en = (entry.get("localizations") or {}).get("en", {}).get("stringUnit", {}).get("value") or ""
        if not en.startswith(needle_en):
            continue
        for loc, val in replacements.items():
            cur = (entry.get("localizations") or {}).get(loc, {}).get("stringUnit", {}).get("value")
            if cur != val:
                set_value(entry, loc, val)
                changed += 1
    return changed


def retranslate_stubs(strings: dict) -> int:
    """Cloud-translate remaining English stubs (excluding allowlists)."""
    require_api_key()
    allow = set(ALLOW_IDENTICAL) | EXTRA_ALLOW | set(GLOSSARY.keys())
    # Group (locale → list of (entry, en_text))
    by_locale: dict[str, list[tuple[dict, str]]] = {}
    for entry in strings.values():
        locs = entry.get("localizations") or {}
        en = locs.get("en", {}).get("stringUnit", {}).get("value")
        if en is None:
            continue
        if en in allow or is_format_only(en):
            continue
        # Skip intent-style phrases already covered by AppShortcuts if still English everywhere
        for loc in CATALOG_LOCALES:
            if loc == "en":
                continue
            val = locs.get(loc, {}).get("stringUnit", {}).get("value")
            if val == en:
                by_locale.setdefault(loc, []).append((entry, en))

    changed = 0
    for loc, items in sorted(by_locale.items()):
        # Dedupe texts but keep all entries
        texts = []
        meta = []
        for entry, en in items:
            hint = CONTEXT_HINTS.get(en, en)
            # Prefer TV/app context for ambiguous shorts
            if en in CONTEXT_HINTS:
                protected, tokens = protect_placeholders(hint)
            else:
                protected, tokens = protect_placeholders(en)
            texts.append(protected)
            meta.append((entry, en, tokens))
        print(f"  retranslate {loc}: {len(texts)} stubs…", flush=True)
        out = translate_batched(texts, loc, batch_size=30, pause_s=0.2)
        for (entry, en, tokens), raw in zip(meta, out):
            val = restore_placeholders(raw, tokens).strip()
            # If we sent a hint with parenthetical, strip trailing context notes MT may keep
            if en in CONTEXT_HINTS and "(" in val and val.endswith(")"):
                # keep as-is if still useful; only strip English hint remnants
                pass
            # For hinted strings, prefer translating the bare word if result looks like English hint
            if val == en or not val:
                continue
            # Strip common MT leftover like " (URL)" if original was Link
            if en in CONTEXT_HINTS:
                val2 = re.sub(r"\s*\([^)]*\)\s*$", "", val).strip()
                if val2:
                    val = val2
            set_value(entry, loc, val)
            changed += 1
        time.sleep(0.3)
    return changed


def main() -> int:
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    strings = data["strings"]

    print("Applying glossary…", flush=True)
    g = apply_glossary(strings)
    print(f"  glossary writes: {g}", flush=True)

    print("Applying format templates…", flush=True)
    f = apply_format_templates(strings)
    print(f"  format writes: {f}", flush=True)

    print("Patching wristwatch mistranslations…", flush=True)
    w = patch_wristwatch_mistranslations(strings)
    print(f"  wristwatch patches: {w}", flush=True)

    print("Retranslating remaining English stubs…", flush=True)
    r = retranslate_stubs(strings)
    print(f"  stub retranslations: {r}", flush=True)

    XCSTRINGS.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote {XCSTRINGS.relative_to(ROOT)}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
