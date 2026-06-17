#!/usr/bin/env python3
"""Import the ASI full-profile monuments workbook into tourism_places.

Required environment variables:
  SUPABASE_URL
  SUPABASE_ANON_KEY
  SUPABASE_ADMIN_EMAIL
  SUPABASE_ADMIN_PASSWORD

Usage:
  python3 scripts/import_tourism_places_from_full_profile.py \
    "/path/to/India_3698_Monuments_Full_Profile.xlsx"
"""

from __future__ import annotations

import json
import math
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

import pandas as pd


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"Missing environment variable: {name}")
    return value


SUPABASE_URL = required_env("SUPABASE_URL").rstrip("/")
SUPABASE_ANON_KEY = required_env("SUPABASE_ANON_KEY")
SUPABASE_ADMIN_EMAIL = required_env("SUPABASE_ADMIN_EMAIL")
SUPABASE_ADMIN_PASSWORD = required_env("SUPABASE_ADMIN_PASSWORD")


def request_json(path: str, body: object | None = None, *, method: str = "POST",
                 token: str | None = None, prefer: str | None = None) -> object | None:
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if prefer:
        headers["Prefer"] = prefer
    data = json.dumps(body).encode("utf-8") if body is not None else None
    request = urllib.request.Request(
        f"{SUPABASE_URL}{path}",
        data=data,
        method=method,
        headers=headers,
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        payload = response.read().decode("utf-8")
        return json.loads(payload) if payload else None


def clean(value: object) -> str | None:
    if value is None or pd.isna(value):
        return None
    text = str(value).strip()
    return text or None


def num(value: object, default: float | None = None) -> float | None:
    if value is None or pd.isna(value):
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def integer(value: object, default: int | None = None) -> int | None:
    numeric = num(value)
    return int(numeric) if numeric is not None else default


def boolean(value: object) -> bool:
    if value is None or pd.isna(value):
        return False
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() in {"true", "1", "yes", "y"}


def mapped_category(value: object) -> str:
    category = clean(value) or "Historical"
    if category.lower() == "religious":
        return "Spiritual"
    if category.lower() == "archaeological":
        return "Archaeological"
    return category


def split_months(value: object) -> list[str]:
    text = clean(value)
    if not text:
        return []
    return [item.strip() for item in re.split(r"[;,]", text) if item.strip()]


def numbered_tips(row: pd.Series, prefix: str) -> list[str]:
    items: list[str] = []
    for index in range(1, 5):
        value = clean(row.get(f"{prefix}_{index}"))
        if value and value not in items:
            items.append(value)
    return items


def address(row: pd.Series) -> str:
    parts = [
        clean(row.get("Locality")),
        clean(row.get("District")),
        clean(row.get("State_UT")),
    ]
    return ", ".join(part for part in parts if part)


def build_rows(workbook_path: Path) -> list[dict[str, object]]:
    frame = pd.read_excel(
        workbook_path,
        sheet_name="Monuments_Full_Profile",
        engine="openpyxl",
    )
    namespace = uuid.uuid5(uuid.NAMESPACE_URL, "unisafex-tourism-full-profile-v1")
    rows: list[dict[str, object]] = []

    for _, row in frame.iterrows():
        global_id = integer(row.get("Global_ID"))
        name = clean(row.get("Monument_Name"))
        state = clean(row.get("State_UT"))
        city = clean(row.get("Locality")) or clean(row.get("District")) or state
        latitude = num(row.get("Latitude"))
        longitude = num(row.get("Longitude"))
        if not (global_id and name and state and city and latitude is not None and longitude is not None):
            continue

        display_rank = integer(row.get("Display_Rank"))
        featured = boolean(row.get("Is_Featured")) or (
            display_rank is not None and display_rank <= 30
        )
        popular = boolean(row.get("Is_Popular")) or featured
        rating = num(row.get("Rating"), 4.2 if featured else 4.0) or 4.0
        images = [
            image
            for image in [clean(row.get("Image_URL_1")), clean(row.get("Image_URL_2"))]
            if image
        ]

        rows.append(
            {
                "place_id": str(uuid.uuid5(namespace, str(global_id))),
                "place_name": name,
                "description": clean(row.get("Description"))
                or f"{name} is a protected heritage destination in {address(row)}.",
                "state": state,
                "district": clean(row.get("District")),
                "city": city,
                "category": mapped_category(row.get("Category")),
                "subcategory": clean(row.get("Monument_Type")),
                "latitude": latitude,
                "longitude": longitude,
                "images": images,
                "entry_fee_indian": num(row.get("Entry_Fee_Indian_INR"), 0) or 0,
                "entry_fee_foreigner": num(row.get("Entry_Fee_Foreign_INR"), 0) or 0,
                "timings": clean(row.get("Timings")),
                "best_season": clean(row.get("Best_Season")),
                "best_months": split_months(row.get("Best_Months")),
                "safety_guidelines": numbered_tips(row, "Safety_Tip"),
                "tourist_tips": numbered_tips(row, "Travel_Tip"),
                "tier": 1 if featured else 2 if popular else 3,
                "featured": featured,
                "rating": round(max(0, min(5, rating)), 1),
                "is_popular": popular,
                "visit_duration_minutes": integer(row.get("Avg_Visit_Duration_Min"), 60),
                "address": address(row),
            }
        )
    return rows


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Pass the workbook path as the only argument.")
    workbook_path = Path(sys.argv[1]).expanduser()
    if not workbook_path.exists():
        raise SystemExit(f"Workbook not found: {workbook_path}")

    auth = request_json(
        "/auth/v1/token?grant_type=password",
        {
            "email": SUPABASE_ADMIN_EMAIL,
            "password": SUPABASE_ADMIN_PASSWORD,
        },
    )
    token = str(auth["access_token"])
    rows = build_rows(workbook_path)
    print(f"Prepared {len(rows)} tourism_places rows")

    request_json(
        "/rest/v1/heritage_monuments?id=not.is.null",
        method="DELETE",
        token=token,
        prefer="return=minimal",
    )

    for start in range(0, len(rows), 250):
        chunk = rows[start:start + 250]
        request_json(
            "/rest/v1/tourism_places?on_conflict=place_id",
            chunk,
            token=token,
            prefer="resolution=merge-duplicates,return=minimal",
        )
        print(f"Upserted {start + len(chunk)} / {len(rows)}")
        time.sleep(0.1)


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8")
        raise SystemExit(f"Supabase request failed: {error.code} {detail}") from error
