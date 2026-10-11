"""Build the HappyPaws dashboard data from the MySQL dump.

The canonical database is MySQL (sql/happypaws.sql). To keep the dashboard
reproducible without a MySQL server, this script loads the schema and seed data
into an in-memory SQLite database, runs SQLite ports of the Task 8 queries
(sql/queries_sqlite.sql) and writes docs/data.js for docs/index.html.

Usage:
    python3 analysis/build_dashboard.py              # as-of date 2026-06-09
    python3 analysis/build_dashboard.py --as-of 2026-10-12
"""

import argparse
import json
import re
import sqlite3
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MYSQL_DUMP = ROOT / "sql" / "happypaws.sql"
SQLITE_QUERIES = ROOT / "sql" / "queries_sqlite.sql"
OUTPUT = ROOT / "docs" / "data.js"

# The data was populated in June 2026; CURDATE() in the original queries is
# pinned to this date so the dashboard matches the submitted report.
DEFAULT_AS_OF = "2026-06-09"


def mysql_to_sqlite(dump: str) -> str:
    """Translate the schema + seed part of the MySQL dump into SQLite SQL."""
    body = dump.split("-- TASK 8")[0]
    body = re.sub(r"^(DROP DATABASE|CREATE DATABASE|USE)\b.*$", "", body, flags=re.M)
    # INT ... AUTO_INCREMENT + named PK constraint -> SQLite rowid alias.
    body = re.sub(r"\bINT\s+NOT NULL\s+AUTO_INCREMENT", "INTEGER PRIMARY KEY AUTOINCREMENT", body)
    body = re.sub(r",\s*CONSTRAINT\s+PK_\w+\s+PRIMARY KEY\s*\(\w+\)", "", body)
    body = re.sub(r"ENUM\([^)]*\)", "TEXT", body)
    body = body.replace("\\'", "''")
    return body


def load_queries(path: Path) -> dict:
    """Split the SQLite query file into {name: sql} on '-- name: <key>' markers."""
    queries, name, lines = {}, None, []
    for line in path.read_text().splitlines():
        marker = re.match(r"--\s*name:\s*(\w+)", line)
        if marker:
            if name:
                queries[name] = "\n".join(lines).strip()
            name, lines = marker.group(1), []
        elif name:
            lines.append(line)
    if name:
        queries[name] = "\n".join(lines).strip()
    return queries


def run(conn: sqlite3.Connection, sql: str, as_of: str) -> list:
    cur = conn.execute(sql, {"as_of": as_of})
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--as-of", default=DEFAULT_AS_OF, help="date used instead of CURDATE()")
    args = parser.parse_args()
    date.fromisoformat(args.as_of)  # fail early on a bad date

    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(mysql_to_sqlite(MYSQL_DUMP.read_text()))

    tables = [r[0] for r in conn.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")]
    row_counts = {t: conn.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0] for t in tables}

    results = {name: run(conn, sql, args.as_of) for name, sql in load_queries(SQLITE_QUERIES).items()}

    payload = {
        "asOf": args.as_of,
        "tables": len(tables),
        "rows": sum(row_counts.values()),
        "rowCounts": row_counts,
        **results,
    }
    OUTPUT.write_text("window.HAPPYPAWS = " + json.dumps(payload, indent=1, default=str) + ";\n")
    print(f"{len(tables)} tables, {payload['rows']} rows, {len(results)} queries -> {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
