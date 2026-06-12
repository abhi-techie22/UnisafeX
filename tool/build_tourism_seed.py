from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = Path(
    "/Users/ak/Documents/Projects/UNISAFEX/Tourist Data "
)
MONUMENTS_FILE = SOURCE_DIR / "India_3698_Monuments_Database.xlsx"
MASTER_FILE = SOURCE_DIR / "India_Tourism_PowerBI_Master.xlsx"
OUTPUT = (
    ROOT
    / "supabase"
    / "migrations"
    / "20260612010000_import_india_tourism_data.sql"
)


def sql_value(value):
    if pd.isna(value):
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(int(value)) if float(value).is_integer() else str(value)
    return "'" + str(value).replace("'", "''") + "'"


def rows_sql(frame, columns):
    return ",\n".join(
        "(" + ", ".join(sql_value(row[column]) for column in columns) + ")"
        for _, row in frame.iterrows()
    )


monuments = pd.read_excel(MONUMENTS_FILE, sheet_name="Monuments_Master")
visitors = pd.read_excel(
    MONUMENTS_FILE, sheet_name="Ticketed_Monuments_Visitors"
).dropna(subset=["Monument_Name"])
states = pd.read_excel(MASTER_FILE, sheet_name="State_UT_Tourism")
states = states.dropna(subset=["State/UT"])
states = states[states["State/UT"].astype(str).str.lower() != "total"]

monument_columns = [
    "Sl_No",
    "Monument_Name",
    "Locality",
    "District",
    "State_UT",
    "Region",
    "ASI_Circle",
    "Monument_Type",
    "Protection_Status",
    "Visitor_Category",
]
visitor_columns = [
    "Monument_Name",
    "State_UT",
    "Rank_Domestic",
    "Domestic_Visitors_FY2024_25",
    "Domestic_Share_%",
    "Rank_Foreign",
    "Foreign_Visitors_FY2024_25",
    "Foreign_Share_%",
    "Total_Visitors",
    "Visitor_Type_Category",
]
state_columns = [
    "State/UT",
    "Region",
    "Domestic_Visits_2023_Mn",
    "Foreign_Visits_2023_Mn",
    "Domestic_Visits_2024_Mn",
    "Foreign_Visits_2024_Mn",
    "DTV_GrowthRate_2024_vs_2023_%",
    "FTV_GrowthRate_2024_vs_2023_%",
    "DTV_Share_2024_%",
    "FTV_Share_2024_%",
    "Total_Visits_2024_Mn",
]

sql = f"""-- Generated from the two tourism workbooks supplied for UniSafeX.
-- The source files are not bundled in the Flutter application.

insert into public.heritage_monuments (
  source_id, monument_name, locality, district, state_ut, region,
  asi_circle, monument_type, protection_status, visitor_category
) values
{rows_sql(monuments, monument_columns)}
on conflict (source_id) do update set
  monument_name = excluded.monument_name,
  locality = excluded.locality,
  district = excluded.district,
  state_ut = excluded.state_ut,
  region = excluded.region,
  asi_circle = excluded.asi_circle,
  monument_type = excluded.monument_type,
  protection_status = excluded.protection_status,
  visitor_category = excluded.visitor_category;

insert into public.monument_visitor_stats (
  monument_name, state_ut, domestic_rank, domestic_visitors, domestic_share,
  foreign_rank, foreign_visitors, foreign_share, total_visitors,
  visitor_type_category
) values
{rows_sql(visitors, visitor_columns)}
on conflict (monument_name, state_ut, fiscal_year) do update set
  domestic_rank = excluded.domestic_rank,
  domestic_visitors = excluded.domestic_visitors,
  domestic_share = excluded.domestic_share,
  foreign_rank = excluded.foreign_rank,
  foreign_visitors = excluded.foreign_visitors,
  foreign_share = excluded.foreign_share,
  total_visitors = excluded.total_visitors,
  visitor_type_category = excluded.visitor_type_category;

insert into public.state_tourism_stats (
  state_ut, region, domestic_visits_2023_mn, foreign_visits_2023_mn,
  domestic_visits_2024_mn, foreign_visits_2024_mn, domestic_growth_2024,
  foreign_growth_2024, domestic_share_2024, foreign_share_2024,
  total_visits_2024_mn
) values
{rows_sql(states, state_columns)}
on conflict (state_ut) do update set
  region = excluded.region,
  domestic_visits_2023_mn = excluded.domestic_visits_2023_mn,
  foreign_visits_2023_mn = excluded.foreign_visits_2023_mn,
  domestic_visits_2024_mn = excluded.domestic_visits_2024_mn,
  foreign_visits_2024_mn = excluded.foreign_visits_2024_mn,
  domestic_growth_2024 = excluded.domestic_growth_2024,
  foreign_growth_2024 = excluded.foreign_growth_2024,
  domestic_share_2024 = excluded.domestic_share_2024,
  foreign_share_2024 = excluded.foreign_share_2024,
  total_visits_2024_mn = excluded.total_visits_2024_mn;
"""

OUTPUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUTPUT} ({len(monuments)} monuments)")
