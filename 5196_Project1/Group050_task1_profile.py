"""FIT5196 A1 Task 1 source parsing and profiling for Group050.

Run from the extracted Group050_A1 package directory:

    python Group050_task1_profile.py

Or run from another directory and point to the package:

    python Group050_task1_profile.py --package-dir "C:/path/to/Group050_A1"

The script reads the JSON and XML with structured parsers and writes profiling
evidence to ``task1_profile_outputs``.  It does not create the six Task 2
standardised tables and it does not modify the raw source files.

The generated mapping is a DRAFT.  Check every path, transformation rule and
notebook evidence reference against the supplied mapping template before use.
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any, Iterable


GROUP_ID = "Group050"

TABLE_META = {
    "orders": ("one row per order", "order_id"),
    "order_items": ("one row per order item", "order_item_id"),
    "customers": ("one row per customer", "customer_id"),
    "deliveries": ("one row per completed order delivery", "delivery_id"),
    "products": ("one row per product", "product_id"),
    "product_reviews": ("one row per canonical product review", "review_id"),
}

JSON_BASE_PATHS = {
    "customers": "$.customerProfiles[]",
    "orders": "$.orders[].header",
    "order_items": "$.orders[].shoppingCart[]",
    "deliveries": "$.orders[].delivery",
    "products": "",
    "product_reviews": "$.productReviews[]",
}

XML_BASE_PATHS = {
    "customers": "",
    "orders": "/OperationsExport/Orders/Order/Header",
    "order_items": "/OperationsExport/Orders/Order/Shopping_Cart/Item",
    "deliveries": "/OperationsExport/Orders/Order/Delivery",
    "products": "/OperationsExport/ProductCatalogue/Product",
    "product_reviews": "/OperationsExport/ProductReviews/Review",
}

SOURCE_KEY_FIELDS = {
    "orders": {"JSON": "orderID", "XML": "Order_ID"},
    "order_items": {"JSON": "orderItemID", "XML": "Order_Item_ID"},
    "customers": {"JSON": "customerID", "XML": "Customer_ID"},
    "deliveries": {"JSON": "deliveryID", "XML": "Delivery_ID"},
    "products": {"JSON": "productID", "XML": "Product_ID"},
    "product_reviews": {"JSON": "reviewID", "XML": "Review_ID"},
}

SPECIAL_SOURCE_FIELDS = {
    ("customers", "prior_12m_orders"): {
        "JSON": "prior12MOrders",
        "XML": "Prior_12M_Orders",
    },
    ("orders", "customer_note_clean"): {
        "JSON": "customerNote",
        "XML": "Customer_Note",
    },
    ("orders", "promo_code"): {
        "JSON": "customerNote",
        "XML": "Customer_Note",
    },
    ("products", "product_description_clean"): {
        "JSON": "productDescription",
        "XML": "Product_Description",
    },
    ("product_reviews", "review_body_clean"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
    ("product_reviews", "review_body_latin_analysis"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
    ("product_reviews", "contains_non_latin_script"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
    ("product_reviews", "review_length_chars"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
    ("product_reviews", "review_word_count"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
    ("product_reviews", "extracted_order_reference"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
    ("product_reviews", "extracted_product_sku"): {
        "JSON": "reviewText",
        "XML": "Review_Text",
    },
}

DERIVED_FIELDS = {
    ("orders", "customer_note_clean"),
    ("orders", "promo_code"),
    ("orders", "order_price"),
    ("orders", "tax_amount"),
    ("orders", "order_total"),
    ("order_items", "line_revenue"),
    ("products", "product_description_clean"),
    ("product_reviews", "review_body_clean"),
    ("product_reviews", "review_body_latin_analysis"),
    ("product_reviews", "contains_non_latin_script"),
    ("product_reviews", "review_length_chars"),
    ("product_reviews", "review_word_count"),
    ("product_reviews", "extracted_order_reference"),
    ("product_reviews", "extracted_product_sku"),
}

RELATIONSHIPS = [
    ("orders", "customer_id", "customers", "customer_id"),
    ("order_items", "order_id", "orders", "order_id"),
    ("order_items", "product_id", "products", "product_id"),
    ("deliveries", "order_id", "orders", "order_id"),
    ("product_reviews", "order_id", "orders", "order_id"),
    ("product_reviews", "order_item_id", "order_items", "order_item_id"),
    ("product_reviews", "product_id", "products", "product_id"),
    ("product_reviews", "customer_id", "customers", "customer_id"),
]


@dataclass(frozen=True)
class SourcePaths:
    package_dir: Path
    json_path: Path
    xml_path: Path
    dictionary_path: Path
    output_dir: Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Parse and profile Group050 JSON/XML sources for A1 Task 1."
    )
    parser.add_argument(
        "--package-dir",
        type=Path,
        default=Path.cwd(),
        help="Extracted Group050_A1 directory (default: current directory).",
    )
    parser.add_argument("--json-path", type=Path, help="Optional explicit JSON path.")
    parser.add_argument("--xml-path", type=Path, help="Optional explicit XML path.")
    parser.add_argument(
        "--dictionary-path", type=Path, help="Optional public_data_dictionary.csv path."
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Output directory (default: PACKAGE/task1_profile_outputs).",
    )
    parser.add_argument(
        "--sample-limit",
        type=int,
        default=5,
        help="Maximum representative values per field (default: 5).",
    )
    return parser.parse_args()


def resolve_paths(args: argparse.Namespace) -> SourcePaths:
    package_dir = args.package_dir.expanduser().resolve()
    raw_dir = package_dir / "raw_input"

    json_path = (
        args.json_path.expanduser().resolve()
        if args.json_path
        else raw_dir / f"{GROUP_ID}_commerce.json"
    )
    xml_path = (
        args.xml_path.expanduser().resolve()
        if args.xml_path
        else raw_dir / f"{GROUP_ID}_operations.xml"
    )
    dictionary_path = (
        args.dictionary_path.expanduser().resolve()
        if args.dictionary_path
        else package_dir / "public_data_dictionary.csv"
    )
    output_dir = (
        args.output_dir.expanduser().resolve()
        if args.output_dir
        else package_dir / "task1_profile_outputs"
    )

    required = [json_path, xml_path, dictionary_path]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError(
            "Required input file(s) not found:\n- " + "\n- ".join(missing)
        )

    if output_dir in {package_dir, raw_dir}:
        raise ValueError("Choose a dedicated output directory outside raw_input.")

    output_dir.mkdir(parents=True, exist_ok=True)
    return SourcePaths(package_dir, json_path, xml_path, dictionary_path, output_dir)


def local_name(tag: str) -> str:
    """Remove an optional XML namespace from a tag."""
    return tag.rsplit("}", 1)[-1]


def element_to_record(element: ET.Element) -> dict[str, Any]:
    """Convert a flat entity element into a dictionary without regex parsing."""
    record: dict[str, Any] = {}
    repeated: defaultdict[str, list[Any]] = defaultdict(list)
    for child in element:
        key = local_name(child.tag)
        if list(child):
            value: Any = element_to_record(child)
        else:
            value = child.text
        repeated[key].append(value)

    for key, values in repeated.items():
        record[key] = values[0] if len(values) == 1 else values
    return record


def load_sources(paths: SourcePaths) -> tuple[dict[str, Any], ET.Element]:
    with paths.json_path.open("r", encoding="utf-8") as stream:
        json_data = json.load(stream)
    if not isinstance(json_data, dict):
        raise TypeError("Expected the JSON root to be an object/dictionary.")

    xml_root = ET.parse(paths.xml_path).getroot()
    return json_data, xml_root


def extract_json_entities(data: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    customers = [dict(row) for row in data.get("customerProfiles", [])]
    product_reviews = [dict(row) for row in data.get("productReviews", [])]

    orders: list[dict[str, Any]] = []
    order_items: list[dict[str, Any]] = []
    deliveries: list[dict[str, Any]] = []
    for source_order in data.get("orders", []):
        orders.append(dict(source_order.get("header") or {}))
        deliveries.append(dict(source_order.get("delivery") or {}))
        order_items.extend(dict(item) for item in source_order.get("shoppingCart", []))

    return {
        "orders": orders,
        "order_items": order_items,
        "customers": customers,
        "deliveries": deliveries,
        "products": [],
        "product_reviews": product_reviews,
    }


def extract_xml_entities(root: ET.Element) -> dict[str, list[dict[str, Any]]]:
    orders: list[dict[str, Any]] = []
    order_items: list[dict[str, Any]] = []
    deliveries: list[dict[str, Any]] = []

    for order_element in root.findall("./Orders/Order"):
        header = order_element.find("./Header")
        delivery = order_element.find("./Delivery")
        if header is not None:
            orders.append(element_to_record(header))
        if delivery is not None:
            deliveries.append(element_to_record(delivery))
        order_items.extend(
            element_to_record(item)
            for item in order_element.findall("./Shopping_Cart/Item")
        )

    products = [
        element_to_record(element)
        for element in root.findall("./ProductCatalogue/Product")
    ]
    product_reviews = [
        element_to_record(element)
        for element in root.findall("./ProductReviews/Review")
    ]

    return {
        "orders": orders,
        "order_items": order_items,
        "customers": [],
        "deliveries": deliveries,
        "products": products,
        "product_reviews": product_reviews,
    }


def read_dictionary(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    rows.sort(key=lambda row: (row["output_table"], int(row["position"])))
    return rows


def to_snake(name: str) -> str:
    name = name.replace("-", "_").replace(" ", "_")
    name = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name)
    return re.sub(r"_+", "_", name).strip("_").lower()


def source_field_for_target(
    table: str,
    target_field: str,
    source: str,
    entity_records: dict[str, dict[str, list[dict[str, Any]]]],
) -> str | None:
    special = SPECIAL_SOURCE_FIELDS.get((table, target_field), {}).get(source)
    if special:
        return special

    records = entity_records[source][table]
    raw_fields = {field for record in records for field in record}
    candidates = sorted(field for field in raw_fields if to_snake(field) == target_field)
    return candidates[0] if candidates else None


def source_path(table: str, source: str, raw_field: str | None) -> str:
    if not raw_field:
        return "N/A"
    base = JSON_BASE_PATHS[table] if source == "JSON" else XML_BASE_PATHS[table]
    separator = "." if source == "JSON" else "/"
    return f"{base}{separator}{raw_field}"


def is_missing(value: Any) -> bool:
    return value is None or (isinstance(value, str) and value.strip() == "")


def serialise_value(value: Any) -> str:
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, sort_keys=True)
    return str(value)


def shorten(value: Any, limit: int = 140) -> str:
    text = serialise_value(value).replace("\r", " ").replace("\n", " ")
    return text if len(text) <= limit else text[: limit - 3] + "..."


def stable_unique(values: Iterable[Any]) -> list[Any]:
    result: list[Any] = []
    seen: set[str] = set()
    for value in values:
        marker = serialise_value(value)
        if marker not in seen:
            seen.add(marker)
            result.append(value)
    return result


def observed_patterns(values: list[Any]) -> str:
    non_missing = [value for value in values if not is_missing(value)]
    text_values = [str(value).strip() for value in non_missing]
    patterns: list[str] = []

    if any(isinstance(value, bool) for value in non_missing):
        patterns.append("Python boolean")
    if any(isinstance(value, int) and not isinstance(value, bool) for value in non_missing):
        patterns.append("integer")
    if any(isinstance(value, float) for value in non_missing):
        patterns.append("decimal number")
    if any(re.fullmatch(r"\d{4}-\d{2}-\d{2}", value) for value in text_values):
        patterns.append("YYYY-MM-DD")
    if any(
        re.fullmatch(r"\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}", value)
        for value in text_values
    ):
        patterns.append("timestamp")
    if any(re.search(r"(?:\$|AUD|USD|EUR|GBP)", value, re.I) for value in text_values):
        patterns.append("currency-labelled string")
    if any("%" in value for value in text_values):
        patterns.append("percentage string")
    if any(value.casefold() in {"true", "false", "yes", "no", "y", "n"} for value in text_values):
        patterns.append("boolean-like string")
    if any(value.startswith("0") and value.isdigit() and len(value) > 1 for value in text_values):
        patterns.append("leading-zero digit string")
    if any(is_missing(value) for value in values):
        patterns.append("missing/blank observed")
    return "; ".join(patterns) or "string/other"


def build_entity_summary(
    entities: dict[str, dict[str, list[dict[str, Any]]]],
) -> list[dict[str, Any]]:
    rows = []
    for table, (grain, primary_key) in TABLE_META.items():
        rows.append(
            {
                "output_table": table,
                "grain": grain,
                "primary_key": primary_key,
                "json_source_collection": JSON_BASE_PATHS[table] or "not supplied",
                "json_rows_observed": len(entities["JSON"][table]),
                "xml_source_collection": XML_BASE_PATHS[table] or "not supplied",
                "xml_rows_observed": len(entities["XML"][table]),
            }
        )
    return rows


def build_field_profile(
    entities: dict[str, dict[str, list[dict[str, Any]]]], sample_limit: int
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for source in ("JSON", "XML"):
        for table in TABLE_META:
            records = entities[source][table]
            raw_fields = sorted({field for record in records for field in record})
            for field in raw_fields:
                values = [record.get(field) for record in records]
                non_missing = [value for value in values if not is_missing(value)]
                unique_values = stable_unique(non_missing)
                rows.append(
                    {
                        "source_format": source,
                        "source_collection": table,
                        "source_path": source_path(table, source, field),
                        "source_field": field,
                        "record_count": len(records),
                        "non_missing_count": len(non_missing),
                        "missing_count": len(values) - len(non_missing),
                        "unique_non_missing_count": len(unique_values),
                        "python_types": "|".join(
                            sorted({type(value).__name__ for value in non_missing})
                        ),
                        "observed_patterns": observed_patterns(values),
                        "representative_values": json.dumps(
                            [shorten(value) for value in unique_values[:sample_limit]],
                            ensure_ascii=False,
                        ),
                        "notebook_evidence": (
                            f"EVID-T1-{source}-{table}-{to_snake(field)}".upper()
                        ),
                    }
                )
    return rows


def normalise_identifier(value: Any) -> str | None:
    if is_missing(value):
        return None
    return str(value).strip()


def build_key_profile(
    entities: dict[str, dict[str, list[dict[str, Any]]]]
) -> list[dict[str, Any]]:
    rows = []
    for source in ("JSON", "XML"):
        for table, (_, primary_key) in TABLE_META.items():
            records = entities[source][table]
            key_field = SOURCE_KEY_FIELDS[table][source]
            values = [normalise_identifier(record.get(key_field)) for record in records]
            present = [value for value in values if value is not None]
            counts = Counter(present)
            duplicate_keys = {key: count for key, count in counts.items() if count > 1}
            rows.append(
                {
                    "source_format": source,
                    "source_collection": table,
                    "target_primary_key": primary_key,
                    "source_key_field": key_field,
                    "source_key_path": source_path(table, source, key_field),
                    "record_count": len(records),
                    "missing_key_count": len(values) - len(present),
                    "unique_key_count": len(counts),
                    "duplicate_key_count": len(duplicate_keys),
                    "rows_with_duplicate_key": sum(duplicate_keys.values()),
                    "duplicate_key_examples": json.dumps(
                        list(sorted(duplicate_keys))[:10], ensure_ascii=False
                    ),
                    "notebook_evidence": f"EVID-T1-KEY-{source}-{table}".upper(),
                }
            )
    return rows


def parse_number_text(text: str) -> str | None:
    candidate = text.strip()
    candidate = re.sub(r"^(?:AUD|USD|EUR|GBP)\s*", "", candidate, flags=re.I)
    candidate = candidate.replace("$", "").replace(",", "")
    candidate = candidate[:-1] if candidate.endswith("%") else candidate
    if not re.fullmatch(r"[-+]?\d+(?:\.\d+)?", candidate):
        return None
    try:
        number = Decimal(candidate).normalize()
    except InvalidOperation:
        return None
    return format(number, "f")


def parse_date_text(text: str) -> str | None:
    candidate = text.strip()
    formats = (
        "%Y-%m-%d",
        "%Y/%m/%d",
        "%d/%m/%Y",
        "%d-%m-%Y",
        "%Y-%m-%d %H:%M:%S",
        "%Y/%m/%d %H:%M:%S",
        "%d/%m/%Y %H:%M:%S",
    )
    for date_format in formats:
        try:
            parsed = datetime.strptime(candidate, date_format)
        except ValueError:
            continue
        return (
            parsed.strftime("%Y-%m-%d %H:%M:%S")
            if "%H" in date_format
            else parsed.strftime("%Y-%m-%d")
        )
    return None


def normalise_for_profile_comparison(value: Any, data_type: str) -> str | None:
    """Basic Task 1 comparison only; Task 2 must apply complete field rules."""
    if is_missing(value):
        return None
    if isinstance(value, bool):
        return "True" if value else "False"

    text = html.unescape(str(value)).strip()
    lower = text.casefold()
    if data_type == "boolean" or lower in {"true", "false", "yes", "no"}:
        if lower in {"true", "yes", "y", "1"}:
            return "True"
        if lower in {"false", "no", "n", "0"}:
            return "False"
    if data_type in {"number"}:
        parsed_number = parse_number_text(text)
        if parsed_number is not None:
            return parsed_number
    if data_type in {"date", "datetime"}:
        parsed_date = parse_date_text(text)
        if parsed_date is not None:
            return parsed_date
    return re.sub(r"\s+", " ", text)


def values_by_key(
    records: list[dict[str, Any]], key_field: str, value_field: str, data_type: str
) -> dict[str, set[str]]:
    result: defaultdict[str, set[str]] = defaultdict(set)
    for record in records:
        key = normalise_identifier(record.get(key_field))
        value = normalise_for_profile_comparison(record.get(value_field), data_type)
        if key is not None and value is not None:
            result[key].add(value)
    return dict(result)


def build_overlap_profiles(
    entities: dict[str, dict[str, list[dict[str, Any]]]],
    dictionary_rows: list[dict[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    summary_rows: list[dict[str, Any]] = []
    field_rows: list[dict[str, Any]] = []
    conflict_samples: list[dict[str, Any]] = []

    dictionary_by_table: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for row in dictionary_rows:
        dictionary_by_table[row["output_table"]].append(row)

    for table in TABLE_META:
        json_records = entities["JSON"][table]
        xml_records = entities["XML"][table]
        json_key_field = SOURCE_KEY_FIELDS[table]["JSON"]
        xml_key_field = SOURCE_KEY_FIELDS[table]["XML"]
        json_keys = {
            value
            for value in (
                normalise_identifier(record.get(json_key_field))
                for record in json_records
            )
            if value is not None
        }
        xml_keys = {
            value
            for value in (
                normalise_identifier(record.get(xml_key_field))
                for record in xml_records
            )
            if value is not None
        }
        overlap_keys = json_keys & xml_keys
        summary_rows.append(
            {
                "output_table": table,
                "json_distinct_keys": len(json_keys),
                "xml_distinct_keys": len(xml_keys),
                "cross_source_overlap_keys": len(overlap_keys),
                "json_only_keys": len(json_keys - xml_keys),
                "xml_only_keys": len(xml_keys - json_keys),
                "notebook_evidence": f"EVID-T1-OVERLAP-{table}".upper(),
            }
        )

        if not overlap_keys:
            continue

        for dictionary_row in dictionary_by_table[table]:
            target_field = dictionary_row["field_name"]
            if (table, target_field) in DERIVED_FIELDS:
                continue
            json_field = source_field_for_target(table, target_field, "JSON", entities)
            xml_field = source_field_for_target(table, target_field, "XML", entities)
            if not json_field or not xml_field:
                continue

            json_values = values_by_key(
                json_records, json_key_field, json_field, dictionary_row["data_type"]
            )
            xml_values = values_by_key(
                xml_records, xml_key_field, xml_field, dictionary_row["data_type"]
            )
            comparable = 0
            matches = 0
            conflicts = 0
            missing_one_side = 0
            for key in sorted(overlap_keys):
                left = json_values.get(key, set())
                right = xml_values.get(key, set())
                if not left or not right:
                    missing_one_side += 1
                else:
                    comparable += 1
                    if left == right:
                        matches += 1
                    else:
                        conflicts += 1
                        if len(conflict_samples) < 100:
                            conflict_samples.append(
                                {
                                    "output_table": table,
                                    "target_field": target_field,
                                    "business_key": key,
                                    "json_normalised_values": json.dumps(
                                        sorted(left), ensure_ascii=False
                                    ),
                                    "xml_normalised_values": json.dumps(
                                        sorted(right), ensure_ascii=False
                                    ),
                                    "interpretation": (
                                        "Profiling candidate only: apply the complete published "
                                        "field normalisation before treating this as a genuine conflict."
                                    ),
                                }
                            )
            field_rows.append(
                {
                    "output_table": table,
                    "target_field": target_field,
                    "json_source_field": json_field,
                    "xml_source_field": xml_field,
                    "overlap_keys": len(overlap_keys),
                    "comparable_non_missing_keys": comparable,
                    "matching_keys_after_basic_normalisation": matches,
                    "candidate_conflict_keys": conflicts,
                    "missing_on_one_side_keys": missing_one_side,
                    "notebook_evidence": (
                        f"EVID-T1-FIELD-COMPARE-{table}-{target_field}".upper()
                    ),
                }
            )

    return summary_rows, field_rows, conflict_samples


def values_for_target(
    table: str,
    target_field: str,
    source: str,
    entities: dict[str, dict[str, list[dict[str, Any]]]],
) -> list[Any]:
    raw_field = source_field_for_target(table, target_field, source, entities)
    if not raw_field:
        return []
    return [record.get(raw_field) for record in entities[source][table]]


def build_relationship_profile(
    entities: dict[str, dict[str, list[dict[str, Any]]]]
) -> list[dict[str, Any]]:
    rows = []
    for child_table, child_field, parent_table, parent_field in RELATIONSHIPS:
        child_values: list[str] = []
        parent_values: list[str] = []
        for source in ("JSON", "XML"):
            child_values.extend(
                value
                for value in (
                    normalise_identifier(value)
                    for value in values_for_target(
                        child_table, child_field, source, entities
                    )
                )
                if value is not None
            )
            parent_values.extend(
                value
                for value in (
                    normalise_identifier(value)
                    for value in values_for_target(
                        parent_table, parent_field, source, entities
                    )
                )
                if value is not None
            )

        child_set = set(child_values)
        parent_set = set(parent_values)
        missing_parent_values = sorted(child_set - parent_set)
        rows.append(
            {
                "child_table": child_table,
                "child_field": child_field,
                "parent_table": parent_table,
                "parent_field": parent_field,
                "distinct_child_values": len(child_set),
                "distinct_parent_values": len(parent_set),
                "child_values_missing_from_parent_union": len(missing_parent_values),
                "missing_parent_examples": json.dumps(
                    missing_parent_values[:10], ensure_ascii=False
                ),
                "interpretation": (
                    "Candidate relationship profile across the union of both sources; "
                    "repeat after Task 2 canonical reconciliation."
                ),
                "notebook_evidence": (
                    f"EVID-T1-REL-{child_table}-{child_field}-{parent_table}".upper()
                ),
            }
        )
    return rows


def generic_transformation(data_type: str, nullable: str) -> str:
    if data_type == "date":
        return "Parse accepted source date representation and format as YYYY-MM-DD."
    if data_type == "datetime":
        return "Parse accepted source timestamp and format as YYYY-MM-DD HH:MM:SS."
    if data_type == "boolean":
        return "Map the published source boolean representation to Python True or False."
    if data_type == "number":
        return (
            "Remove applicable currency labels/thousands separators or percentage markers, "
            "then convert to numeric using the target comparison rule."
        )
    if nullable == "True":
        return (
            "Preserve identifier/category case, trim applicable whitespace, and use the "
            "literal string NaN for a prescribed missing string result."
        )
    return "Preserve identifier/category case and leading zeros; trim only where required."


def specific_transformation(table: str, field: str, fallback: str) -> str:
    rules = {
        ("order_items", "line_revenue"): (
            "Calculate quantity * unit_price and round to two decimal places."
        ),
        ("orders", "order_price"): (
            "Sum the rounded order-item line_revenue values for the order and round to two decimals."
        ),
        ("orders", "tax_amount"): (
            "Calculate included GST as order_price / 11 before coupon discount; round to two decimals."
        ),
        ("orders", "order_total"): (
            "Apply coupon_discount to order_price, add delivery_charges, then round to two decimals; "
            "do not add tax_amount again."
        ),
        ("orders", "customer_note_clean"): (
            "Apply the published narrative cleaning order after structured parsing; return literal NaN "
            "when no human-readable text remains."
        ),
        ("orders", "promo_code"): (
            "Extract a bounded B1SAVE- to B5SAVE- code followed by exactly two digits from the raw note; "
            "return upper-case code or literal NaN."
        ),
        ("products", "product_description_clean"): (
            "Apply the published narrative cleaning order after structured parsing."
        ),
        ("product_reviews", "review_body_clean"): (
            "Extract references first, then apply entity decoding, NFC, tag/marker/URL/emoji/wrapper "
            "removal, whitespace collapse and lower-casing while preserving multilingual letters."
        ),
        ("product_reviews", "review_body_latin_analysis"): (
            "Derive from review_body_clean; retain Latin-script letters including diacritics and "
            "applicable digits/punctuation; return literal NaN if no Latin letter remains."
        ),
        ("product_reviews", "contains_non_latin_script"): (
            "Return whether review_body_clean contains any letter outside the Latin script."
        ),
        ("product_reviews", "review_length_chars"): (
            "Count Python characters in review_body_clean, preserving published literal-NaN behaviour."
        ),
        ("product_reviews", "review_word_count"): (
            "Count whitespace-separated tokens in review_body_clean, preserving published literal-NaN behaviour."
        ),
        ("product_reviews", "extracted_order_reference"): (
            "Extract bounded HORD/CORD followed by exactly six digits from raw review text; upper-case or NaN."
        ),
        ("product_reviews", "extracted_product_sku"): (
            "Extract bounded SKU- followed by one or more ASCII letters/digits from raw review text; "
            "upper-case or NaN."
        ),
    }
    return rules.get((table, field), fallback)


def derived_paths(table: str, field: str, source: str) -> str | None:
    if (table, field) == ("order_items", "line_revenue"):
        fields = ("quantity", "unitPrice") if source == "JSON" else ("Quantity", "Unit_Price")
        return " | ".join(source_path(table, source, raw) for raw in fields)
    if (table, field) == ("orders", "order_price"):
        base = JSON_BASE_PATHS["order_items"] if source == "JSON" else XML_BASE_PATHS["order_items"]
        sep = "." if source == "JSON" else "/"
        raw_fields = ("quantity", "unitPrice") if source == "JSON" else ("Quantity", "Unit_Price")
        return " | ".join(f"{base}{sep}{raw}" for raw in raw_fields)
    if (table, field) == ("orders", "tax_amount"):
        return "derived from target orders.order_price"
    if (table, field) == ("orders", "order_total"):
        return (
            "derived from target orders.order_price | orders.coupon_discount | "
            "orders.delivery_charges"
        )
    return None


def build_mapping_draft(
    dictionary_rows: list[dict[str, str]],
    entities: dict[str, dict[str, list[dict[str, Any]]]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for dictionary_row in dictionary_rows:
        table = dictionary_row["output_table"]
        field = dictionary_row["field_name"]
        json_field = source_field_for_target(table, field, "JSON", entities)
        xml_field = source_field_for_target(table, field, "XML", entities)
        json_path = derived_paths(table, field, "JSON") or source_path(
            table, "JSON", json_field
        )
        xml_path = derived_paths(table, field, "XML") or source_path(
            table, "XML", xml_field
        )

        has_json = json_path != "N/A" and bool(entities["JSON"][table])
        has_xml = xml_path != "N/A" and bool(entities["XML"][table])
        if (table, field) in DERIVED_FIELDS:
            source_format = "derived"
        elif has_json and has_xml:
            source_format = "both"
        elif has_json:
            source_format = "JSON"
        elif has_xml:
            source_format = "XML"
        else:
            source_format = "UNRESOLVED"

        fallback = generic_transformation(
            dictionary_row["data_type"], dictionary_row["nullable"]
        )
        transformation = specific_transformation(table, field, fallback)
        if has_json and has_xml:
            overlap_rule = (
                "Normalise comparable values first; match on the table primary key; retain one "
                "canonical row per key; record different non-missing values in validation instead "
                "of silently preferring JSON or XML."
            )
        else:
            overlap_rule = (
                "Check within-source duplicates using the table primary key and field evidence; "
                "retain one reproducible canonical value and record genuine conflicts."
            )
        if source_format == "derived":
            overlap_rule += " Derive only after the required canonical input fields are reconciled."

        rows.append(
            {
                "output_table": table,
                "target_field": field,
                "source_format": source_format,
                "json_source_path": json_path if has_json else "N/A",
                "xml_source_path": xml_path if has_xml else "N/A",
                "transformation_or_derivation": transformation,
                "overlap_or_conflict_rule": overlap_rule,
                "notebook_evidence": f"EVID-T1-MAP-{table}-{field}".upper(),
                "draft_review_status": "REVIEW REQUIRED",
            }
        )
    return rows


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        return
    with path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def build_report(
    paths: SourcePaths,
    entity_summary: list[dict[str, Any]],
    key_profile: list[dict[str, Any]],
    overlap_summary: list[dict[str, Any]],
    relationship_profile: list[dict[str, Any]],
    mapping_draft: list[dict[str, Any]],
) -> str:
    lines = [
        f"# {GROUP_ID} Task 1 profiling report",
        "",
        "This report contains observed source evidence, not certified canonical counts.",
        "The mapping file is a draft and must be reviewed against the official template.",
        "",
        "## EVID-T1-SOURCE-FILES",
        "",
        f"- JSON: `{paths.json_path.name}` (parsed with `json.load`)",
        f"- XML: `{paths.xml_path.name}` (parsed with `xml.etree.ElementTree`)",
        f"- Dictionary: `{paths.dictionary_path.name}`",
        "",
        "## EVID-T1-ENTITY-GRAINS",
        "",
        "| Table | Intended grain | Primary key | JSON rows | XML rows |",
        "|---|---|---|---:|---:|",
    ]
    for row in entity_summary:
        lines.append(
            f"| {row['output_table']} | {row['grain']} | {row['primary_key']} | "
            f"{row['json_rows_observed']} | {row['xml_rows_observed']} |"
        )

    lines.extend(
        [
            "",
            "## EVID-T1-KEY-SUMMARY",
            "",
            "| Source | Table | Rows | Missing keys | Unique keys | Duplicate keys |",
            "|---|---|---:|---:|---:|---:|",
        ]
    )
    for row in key_profile:
        lines.append(
            f"| {row['source_format']} | {row['source_collection']} | "
            f"{row['record_count']} | {row['missing_key_count']} | "
            f"{row['unique_key_count']} | {row['duplicate_key_count']} |"
        )

    lines.extend(
        [
            "",
            "## EVID-T1-CROSS-SOURCE-OVERLAP",
            "",
            "| Table | JSON keys | XML keys | Overlap | JSON only | XML only |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for row in overlap_summary:
        lines.append(
            f"| {row['output_table']} | {row['json_distinct_keys']} | "
            f"{row['xml_distinct_keys']} | {row['cross_source_overlap_keys']} | "
            f"{row['json_only_keys']} | {row['xml_only_keys']} |"
        )

    lines.extend(
        [
            "",
            "## EVID-T1-CANDIDATE-RELATIONSHIPS",
            "",
            "| Child | Parent | Distinct child values | Missing from parent union |",
            "|---|---|---:|---:|",
        ]
    )
    for row in relationship_profile:
        lines.append(
            f"| {row['child_table']}.{row['child_field']} | "
            f"{row['parent_table']}.{row['parent_field']} | "
            f"{row['distinct_child_values']} | "
            f"{row['child_values_missing_from_parent_union']} |"
        )

    unresolved = [row for row in mapping_draft if row["source_format"] == "UNRESOLVED"]
    lines.extend(
        [
            "",
            "## EVID-T1-ASSUMPTIONS-TO-REVIEW",
            "",
            "1. Treat the public dictionary grain and primary keys as the target contract.",
            "2. Preserve identifier leading zeros and case during profiling and transformation.",
            "3. Flatten each shopping-cart item to one order-item row without flattening all entities together.",
            "4. Reconcile normalised values by stable primary key and log different non-missing values.",
            "5. Do not treat the observed source row counts in this report as hard-coded canonical answers.",
            "6. Re-run all key, relationship and conflict checks after Task 2 canonical reconciliation.",
            "",
            "## Mapping draft status",
            "",
            f"- Dictionary target rows: {len(mapping_draft)}",
            f"- Automatically unresolved rows: {len(unresolved)}",
            "- Every row remains marked `REVIEW REQUIRED` until a student verifies it.",
            "",
            "## Generated evidence files",
            "",
            "- `task1_entity_summary.csv`",
            "- `task1_field_profile.csv`",
            "- `task1_key_profile.csv`",
            "- `task1_overlap_summary.csv`",
            "- `task1_overlap_field_summary.csv`",
            "- `task1_conflict_candidates.csv` (only written when candidates exist)",
            "- `task1_relationship_profile.csv`",
            "- `task1_source_to_target_mapping_draft.csv`",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    if args.sample_limit < 1:
        raise ValueError("--sample-limit must be at least 1.")

    paths = resolve_paths(args)
    print(f"[1/8] Parsing JSON: {paths.json_path}")
    print(f"[2/8] Parsing XML:  {paths.xml_path}")
    json_data, xml_root = load_sources(paths)

    print("[3/8] Extracting source-level entity records")
    entities = {
        "JSON": extract_json_entities(json_data),
        "XML": extract_xml_entities(xml_root),
    }
    dictionary_rows = read_dictionary(paths.dictionary_path)

    print("[4/8] Profiling grains, fields, formats and candidate keys")
    entity_summary = build_entity_summary(entities)
    field_profile = build_field_profile(entities, args.sample_limit)
    key_profile = build_key_profile(entities)

    print("[5/8] Profiling within-source duplication and cross-source overlap")
    overlap_summary, overlap_fields, conflict_samples = build_overlap_profiles(
        entities, dictionary_rows
    )

    print("[6/8] Profiling candidate foreign-key relationships")
    relationship_profile = build_relationship_profile(entities)

    print("[7/8] Building a review-required source-to-target mapping draft")
    mapping_draft = build_mapping_draft(dictionary_rows, entities)

    print(f"[8/8] Writing evidence to: {paths.output_dir}")
    write_csv(paths.output_dir / "task1_entity_summary.csv", entity_summary)
    write_csv(paths.output_dir / "task1_field_profile.csv", field_profile)
    write_csv(paths.output_dir / "task1_key_profile.csv", key_profile)
    write_csv(paths.output_dir / "task1_overlap_summary.csv", overlap_summary)
    write_csv(paths.output_dir / "task1_overlap_field_summary.csv", overlap_fields)
    if conflict_samples:
        write_csv(
            paths.output_dir / "task1_conflict_candidates.csv", conflict_samples
        )
    write_csv(paths.output_dir / "task1_relationship_profile.csv", relationship_profile)
    write_csv(
        paths.output_dir / "task1_source_to_target_mapping_draft.csv", mapping_draft
    )

    report = build_report(
        paths,
        entity_summary,
        key_profile,
        overlap_summary,
        relationship_profile,
        mapping_draft,
    )
    (paths.output_dir / "task1_profile_report.md").write_text(
        report, encoding="utf-8"
    )

    unresolved = sum(row["source_format"] == "UNRESOLVED" for row in mapping_draft)
    print("\nTask 1 profiling completed.")
    print(f"Dictionary target rows mapped: {len(mapping_draft)}")
    print(f"Automatically unresolved mapping rows: {unresolved}")
    print("Next: review every mapping row and transfer verified evidence into the notebook.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, ValueError, TypeError, ET.ParseError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
