# -*- coding: utf-8 -*-
"""Shared text functions for FIT5196 A1 Group050.

The six public functions implement the fixed Task 3 interface. This module
uses only the Python standard library and performs no file I/O, network access
or row-specific lookups.
"""

import html
import re
import unicodedata

__all__ = [
    "clean_narrative_text",
    "extract_order_reference",
    "extract_product_sku",
    "extract_promo_code",
    "build_latin_analysis",
    "contains_non_latin_script",
]


_LITERAL_NAN = "NaN"

# The code itself is ASCII-only, while the surrounding ``\w`` checks remain
# Unicode-aware. Including hyphens in both boundaries rejects malformed
# extensions instead of accepting a valid prefix from a longer token.
_ORDER_REFERENCE_RE = re.compile(
    r"(?<![\w-])(?ai:(?:HORD|CORD)[0-9]{6})(?![\w-])"
)
_PRODUCT_SKU_RE = re.compile(r"(?<![\w-])(?ai:SKU-[A-Z0-9]+)(?![\w-])")
_PROMO_CODE_RE = re.compile(r"(?<![\w-])(?ai:B[1-5]SAVE-[0-9]{2})(?![\w-])")

_EMOJI_RE = re.compile(
    r"[0-9#*]\ufe0f?\u20e3"
    r"|[\u00a9\u00ae\u203c\u2049\u2122\u2139\u3030\u303d\u3297\u3299]\ufe0f"
    r"|[\U0001F000-\U0001FAFF\u2300-\u23FF\u2600-\u27BF\u2B00-\u2BFF"
    r"\uFE00-\uFE0F\U000E0020-\U000E007F\u200D\u20E3]"
)


def _extract_upper(value, pattern):
    """Return the first bounded match in upper case, or literal ``NaN``."""

    if not isinstance(value, str):
        return _LITERAL_NAN

    match = pattern.search(value)
    return match.group(0).upper() if match else _LITERAL_NAN


def clean_narrative_text(value):
    """Accept None or a string; return cleaned text or the string 'NaN'."""

    if not isinstance(value, str):
        return _LITERAL_NAN
    if value == _LITERAL_NAN:
        return _LITERAL_NAN

    text = html.unescape(value)
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"<[^<>]*>", " ", text)
    text = re.sub(
        (
            r"\[(?:SYSTEM|CATALOGUE|VERIFIED_PURCHASE|"
            r"SOURCE:\s*[^\]]*|RATING:\s*[0-5]\s*/\s*5)\]"
        ),
        " ",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"(?<![\w-])(?:#verified-buyer|@store_support)(?![\w-])",
        " ",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"\b(?:https?://|www\.)\S+",
        " ",
        text,
        flags=re.IGNORECASE,
    )
    text = _EMOJI_RE.sub("", text)
    text = re.sub(
        (
            r"(?<![\w-])Reference:\s*"
            r"(?a:(?:HORD|CORD)[0-9]{6})(?![\w-])"
            r"(?:\s*[|,;/]\s*|\s+)"
            r"SKU:\s*(?a:SKU-[A-Z0-9]+)(?![\w-])"
        ),
        " ",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"(?<![\w-])PROMO:\s*(?a:B[1-5]SAVE-[0-9]{2})(?![\w-])",
        " ",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(r"\s+", " ", text).strip().lower()

    return text if text else _LITERAL_NAN


def extract_order_reference(value):
    """Accept None or a string; return the upper-case reference or 'NaN'."""

    return _extract_upper(value, _ORDER_REFERENCE_RE)


def extract_product_sku(value):
    """Accept None or a string; return the upper-case SKU or 'NaN'."""

    return _extract_upper(value, _PRODUCT_SKU_RE)


def extract_promo_code(value):
    """Accept None or a string; return the upper-case code or 'NaN'."""

    return _extract_upper(value, _PROMO_CODE_RE)


def build_latin_analysis(value):
    """Accept cleaned multilingual text; return Latin analysis or 'NaN'."""

    if not isinstance(value, str) or value == _LITERAL_NAN:
        return _LITERAL_NAN

    text = unicodedata.normalize("NFC", value)
    output_characters = []
    contains_latin_letter = False
    previous_character_was_latin = False

    for character in text:
        category = unicodedata.category(character)
        unicode_name = unicodedata.name(character, "")

        if category.startswith("L"):
            if "LATIN" in unicode_name:
                output_characters.append(character)
                contains_latin_letter = True
                previous_character_was_latin = True
            else:
                # Avoid joining Latin words that surrounded removed script.
                output_characters.append(" ")
                previous_character_was_latin = False
        elif category.startswith("M"):
            # Keep a combining mark only when it belongs to retained Latin.
            if previous_character_was_latin:
                output_characters.append(character)
        else:
            output_characters.append(character)
            previous_character_was_latin = False

    result = re.sub(r"\s+", " ", "".join(output_characters)).strip()
    return result if contains_latin_letter and result else _LITERAL_NAN


def contains_non_latin_script(value):
    """Accept cleaned multilingual text; return a Python bool."""

    if not isinstance(value, str) or value == _LITERAL_NAN:
        return False

    text = unicodedata.normalize("NFC", value)
    return any(
        unicodedata.category(character).startswith("L")
        and "LATIN" not in unicodedata.name(character, "")
        for character in text
    )
