#!/usr/bin/env python3
"""Build assets/quran_tanzil_text.db from tool/quran.sql (Tanzil Uthmani text)."""

from __future__ import annotations

import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SQL_PATH = ROOT / "tool" / "quran.sql"
DB_PATH = ROOT / "assets" / "quran_tanzil_text.db"

ROW_PATTERN = re.compile(r"\(\d+,\s*(\d+),\s*(\d+),\s*'([^']*)'\)")


def parse_rows(sql_dump: str) -> list[tuple[int, int, str]]:
    rows: list[tuple[int, int, str]] = []
    for match in ROW_PATTERN.finditer(sql_dump):
        rows.append(
            (
                int(match.group(1)),
                int(match.group(2)),
                match.group(3),
            )
        )
    return rows


def build_db(rows: list[tuple[int, int, str]]) -> None:
    if DB_PATH.exists():
        DB_PATH.unlink()

    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute(
            """
            CREATE TABLE quran_text (
              sura INTEGER NOT NULL,
              aya  INTEGER NOT NULL,
              text TEXT NOT NULL,
              PRIMARY KEY (sura, aya)
            )
            """
        )
        conn.executemany(
            "INSERT INTO quran_text (sura, aya, text) VALUES (?, ?, ?)",
            rows,
        )
        conn.commit()
    finally:
        conn.close()


def main() -> int:
    if not SQL_PATH.is_file():
        print(f"Missing source file: {SQL_PATH}", file=sys.stderr)
        return 1

    sql_dump = SQL_PATH.read_text(encoding="utf-8")
    rows = parse_rows(sql_dump)
    if not rows:
        print(f"No ayah rows parsed from {SQL_PATH}", file=sys.stderr)
        return 1

    build_db(rows)
    print(f"Wrote {len(rows)} rows to {DB_PATH} ({DB_PATH.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
