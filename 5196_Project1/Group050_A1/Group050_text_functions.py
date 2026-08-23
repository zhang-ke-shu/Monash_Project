# -*- coding: utf-8 -*-
"""Shared text functions for FIT5196 A1 Group050.

Integration scaffold only. Functions marked ``INTEGRATION PENDING`` must be
implemented by their assigned owners before the final submission and the full
public/private test run.

This module intentionally uses only the Python standard library and performs
no file I/O, network access, or row-specific lookups.
"""

import re


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
# extensions such as ``SKU-ABC123-extra`` instead of accepting a valid prefix.
_PRODUCT_SKU_RE = re.compile(
    r"(?<![\w-])(?ai:SKU-[A-Z0-9]+)(?![\w-])"
)
_PROMO_CODE_RE = re.compile(
    r"(?<![\w-])(?ai:B[1-5]SAVE-[0-9]{2})(?![\w-])"
)


def _extract_upper(value, pattern):
    """Return the first bounded match in upper case, or literal ``NaN``."""

    if not isinstance(value, str):
        return _LITERAL_NAN

    match = pattern.search(value)
    return match.group(0).upper() if match else _LITERAL_NAN


def clean_narrative_text(value):
    """Accept None or a string; return cleaned text or the string 'NaN'."""

    # INTEGRATION PENDING - owner: Lucy Zhao.
    raise NotImplementedError("Pending owner integration: Lucy Zhao")


def extract_order_reference(value):
    """Accept None or a string; return the upper-case reference or 'NaN'."""

    # INTEGRATION PENDING - owner: Jason.
    raise NotImplementedError("Pending owner integration: Jason")


def extract_product_sku(value):
    """Accept None or a string; return the upper-case SKU or 'NaN'."""

    return _extract_upper(value, _PRODUCT_SKU_RE)


def extract_promo_code(value):
    """Accept None or a string; return the upper-case code or 'NaN'."""

    return _extract_upper(value, _PROMO_CODE_RE)


def build_latin_analysis(value):
    """Accept cleaned multilingual text; return Latin analysis or 'NaN'."""

    # INTEGRATION PENDING - owner: Kris.
    raise NotImplementedError("Pending owner integration: Kris")


def contains_non_latin_script(value):
    """Accept cleaned multilingual text; return a Python bool."""

    # INTEGRATION PENDING - owner: Kris.
    raise NotImplementedError("Pending owner integration: Kris")
