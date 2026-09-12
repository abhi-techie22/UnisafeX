#!/usr/bin/env python3
"""Prepare UniSafeX monument workbook for large-scale image enrichment.

This script does not fabricate image URLs. It adds AI-ready image slots and a
generation queue so images can be generated/uploaded by a later automation step.
"""

from __future__ import annotations

import argparse
from copy import copy
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from openpyxl import load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.table import Table, TableStyleInfo


MAIN_SHEET = "Monuments_Full_Profile"
QUEUE_SHEET = "Image_Generation_Queue"
CONFIG_SHEET = "Image_Automation_Config"
README_SHEET = "README_Image_Automation"

IMAGE_TYPES = (
    "Exterior wide angle",
    "Architecture detail",
    "Entrance or gateway",
    "Close-up carving/material",
    "Landscape and surroundings",
    "Tourist visitor perspective",
)

NEGATIVE_PROMPT = (
    "no incorrect text, no fake signage, no distorted architecture, no crowds "
    "blocking monument, no watermark, no logo, no violence, no political content"
)


def clean(value: object) -> str:
    if value is None:
        return ""
    return str(value).strip()


def header_map(sheet) -> dict[str, int]:
    return {
        clean(cell.value): cell.column
        for cell in sheet[1]
        if clean(cell.value)
    }


def clone_header_style(source_cell, target_cell) -> None:
    if source_cell.has_style:
        target_cell.font = copy(source_cell.font)
        target_cell.fill = copy(source_cell.fill)
        target_cell.border = copy(source_cell.border)
        target_cell.alignment = copy(source_cell.alignment)
        target_cell.number_format = source_cell.number_format
        target_cell.protection = copy(source_cell.protection)


def ensure_columns(sheet, headers: Iterable[str]) -> dict[str, int]:
    headers_by_name = header_map(sheet)
    template = sheet.cell(row=1, column=max(1, sheet.max_column))
    for header in headers:
        if header in headers_by_name:
            continue
        next_column = sheet.max_column + 1
        cell = sheet.cell(row=1, column=next_column, value=header)
        clone_header_style(template, cell)
        headers_by_name[header] = next_column
    return headers_by_name


def prompt_for(row: dict[str, object], image_type: str) -> str:
    name = clean(row.get("Monument_Name"))
    description = clean(row.get("Description"))
    state = clean(row.get("State_UT"))
    district = clean(row.get("District"))
    locality = clean(row.get("Locality"))
    category = clean(row.get("Category"))
    monument_type = clean(row.get("Monument_Type"))
    location = ", ".join(part for part in (locality, district, state, "India") if part)
    context = description[:360] if description else f"A heritage monument in {location}."
    return (
        f"Create a premium travel-app image of {name}, {location}. "
        f"Image type: {image_type}. Category: {category or 'Heritage'}; "
        f"monument type: {monument_type or 'Monument'}. Context: {context} "
        "Style: realistic editorial tourism photography, warm natural light, "
        "respectful heritage representation, high detail, mobile app hero image, "
        "no readable text overlays. If exact appearance is unknown, generate a "
        "historically plausible India heritage visual and label as AI generated."
    )


def alt_text_for(row: dict[str, object], image_type: str) -> str:
    name = clean(row.get("Monument_Name")) or "Monument"
    locality = clean(row.get("Locality"))
    district = clean(row.get("District"))
    state = clean(row.get("State_UT"))
    place = ", ".join(part for part in (locality, district, state) if part)
    suffix = f" in {place}" if place else ""
    return f"{image_type} view of {name}{suffix}"


def safe_file_stem(global_id: object, name: object, image_type: str) -> str:
    raw = f"{clean(global_id) or 'unknown'}-{clean(name)[:48]}-{image_type}"
    safe = "".join(char.lower() if char.isalnum() else "-" for char in raw)
    while "--" in safe:
        safe = safe.replace("--", "-")
    return safe.strip("-")


def remove_sheet_if_exists(workbook, title: str) -> None:
    if title in workbook.sheetnames:
        del workbook[title]


def style_sheet(sheet, freeze: str = "A2") -> None:
    sheet.freeze_panes = freeze
    sheet.auto_filter.ref = sheet.dimensions
    header_fill = PatternFill("solid", fgColor="1F6B45")
    header_font = Font(color="FFFFFF", bold=True)
    for cell in sheet[1]:
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    for column_cells in sheet.columns:
        letter = get_column_letter(column_cells[0].column)
        max_length = max(len(clean(cell.value)) for cell in column_cells[:80])
        sheet.column_dimensions[letter].width = max(12, min(max_length + 2, 48))


def add_table(sheet, name: str) -> None:
    if sheet.max_row < 2 or sheet.max_column < 1:
        return
    ref = f"A1:{get_column_letter(sheet.max_column)}{sheet.max_row}"
    table = Table(displayName=name, ref=ref)
    table.tableStyleInfo = TableStyleInfo(
        name="TableStyleMedium4",
        showFirstColumn=False,
        showLastColumn=False,
        showRowStripes=True,
        showColumnStripes=False,
    )
    sheet.add_table(table)


def enrich_workbook(input_path: Path, output_path: Path, target_total_images: int) -> None:
    workbook = load_workbook(input_path)
    if MAIN_SHEET not in workbook.sheetnames:
        raise SystemExit(f"Workbook must contain a '{MAIN_SHEET}' sheet.")

    sheet = workbook[MAIN_SHEET]
    new_headers = [
        *[f"Image_URL_{index}" for index in range(3, target_total_images + 1)],
        *[f"Image_Alt_Text_{index}" for index in range(1, target_total_images + 1)],
        "Image_Types_Targeted",
        "Generated_Image_Count_Target",
        "Image_Generation_Status",
        "Google_Drive_Folder_Path",
        "AI_Image_Disclosure",
        "Last_Image_Enrichment_Run",
    ]
    headers = ensure_columns(sheet, new_headers)
    existing_headers = header_map(sheet)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    for row_index in range(2, sheet.max_row + 1):
        row_values = {
            name: sheet.cell(row=row_index, column=col).value
            for name, col in existing_headers.items()
        }
        global_id = row_values.get("Global_ID")
        name = row_values.get("Monument_Name")
        drive_folder = f"/Monuments Images/{clean(global_id) or row_index}/"

        for image_index in range(1, target_total_images + 1):
            alt_header = f"Image_Alt_Text_{image_index}"
            if alt_header in headers and not clean(sheet.cell(row=row_index, column=headers[alt_header]).value):
                image_type = IMAGE_TYPES[(image_index - 1) % len(IMAGE_TYPES)]
                sheet.cell(row=row_index, column=headers[alt_header], value=alt_text_for(row_values, image_type))

        for header, value in {
            "Image_Types_Targeted": ", ".join(IMAGE_TYPES),
            "Generated_Image_Count_Target": target_total_images,
            "Image_Generation_Status": "Pending AI generation",
            "Google_Drive_Folder_Path": drive_folder,
            "AI_Image_Disclosure": "AI-generated images must be labelled in app/admin until manually verified.",
            "Last_Image_Enrichment_Run": now,
        }.items():
            sheet.cell(row=row_index, column=headers[header], value=value)

    remove_sheet_if_exists(workbook, QUEUE_SHEET)
    queue = workbook.create_sheet(QUEUE_SHEET)
    queue_headers = [
        "Global_ID",
        "Monument_Name",
        "State_UT",
        "District",
        "Locality",
        "Category",
        "Image_Type",
        "Prompt",
        "Negative_Prompt",
        "Output_File_Name",
        "Drive_Folder_Path",
        "Status",
        "Result_Image_URL",
        "Alt_Text",
        "Source_Mode",
        "Disclosure",
    ]
    queue.append(queue_headers)

    for row_index in range(2, sheet.max_row + 1):
        row_values = {
            name: sheet.cell(row=row_index, column=col).value
            for name, col in existing_headers.items()
        }
        global_id = row_values.get("Global_ID")
        drive_folder = f"/Monuments Images/{clean(global_id) or row_index}/"
        for image_type in IMAGE_TYPES:
            queue.append(
                [
                    global_id,
                    row_values.get("Monument_Name"),
                    row_values.get("State_UT"),
                    row_values.get("District"),
                    row_values.get("Locality"),
                    row_values.get("Category"),
                    image_type,
                    prompt_for(row_values, image_type),
                    NEGATIVE_PROMPT,
                    f"{safe_file_stem(global_id, row_values.get('Monument_Name'), image_type)}.jpg",
                    drive_folder,
                    "Pending",
                    "",
                    alt_text_for(row_values, image_type),
                    "AI_GENERATE",
                    "AI-generated; verify before using as factual monument photo.",
                ]
            )

    remove_sheet_if_exists(workbook, CONFIG_SHEET)
    config = workbook.create_sheet(CONFIG_SHEET)
    config.append(["Config_Key", "Config_Value", "Notes"])
    config_rows = [
        ("target_total_images_per_monument", target_total_images, "Workbook keeps this many image URL slots."),
        ("new_images_to_generate_per_monument", len(IMAGE_TYPES), "Queue creates six new image requests per monument."),
        ("image_types", ", ".join(IMAGE_TYPES), "Use these types for variety in the tourism app."),
        ("source_mode", "BOTH", "Fetch real public images first; use AI only for missing slots."),
        ("drive_root_folder", "/Monuments Images/", "Apps Script should create child folders by Global_ID."),
        ("status_values", "Pending, Processing, Done, Failed, Needs Review", "Automation should update queue row status."),
        ("secret_storage", "Apps Script PropertiesService", "Do not store API keys inside this workbook."),
        ("app_disclosure", "Show AI-generated label until verified", "Avoid misleading tourists with unverified visuals."),
    ]
    for row in config_rows:
        config.append(row)

    remove_sheet_if_exists(workbook, README_SHEET)
    readme = workbook.create_sheet(README_SHEET)
    readme.append(["Step", "What to do"])
    instructions = [
        ("1", "Use Monuments_Full_Profile as the app import source. It now has Image_URL_1 through Image_URL_8."),
        ("2", "Run the Wikimedia fetch script first to fill real public images where available."),
        ("3", "Use Image_Generation_Queue for the remaining empty slots. One row equals one new image request."),
        ("4", "Apps Script reads Pending rows, calls your image API, saves the image to Google Drive, and writes Result_Image_URL."),
        ("5", "After generation, copy Result_Image_URL values into Image_URL_3 through Image_URL_8 for each Global_ID."),
        ("6", "Keep API keys in Apps Script PropertiesService or Supabase secrets, never inside this XLSX or Flutter code."),
        ("7", "Review images for accuracy before marking them production-ready."),
    ]
    for row in instructions:
        readme.append(row)

    for ws in (sheet, queue, config, readme):
        style_sheet(ws)
    add_table(queue, "ImageGenerationQueue")
    add_table(config, "ImageAutomationConfig")
    add_table(readme, "ImageAutomationReadme")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    workbook.save(output_path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Source .xlsx workbook")
    parser.add_argument("output", type=Path, help="Enriched .xlsx workbook to write")
    parser.add_argument("--target-total-images", type=int, default=8)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.target_total_images < 7:
        raise SystemExit("--target-total-images must be more than 6.")
    enrich_workbook(args.input.expanduser(), args.output.expanduser(), args.target_total_images)


if __name__ == "__main__":
    main()
