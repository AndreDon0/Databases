"""DB reset and sample data via create.sql and insert.sql."""

from __future__ import annotations

from pathlib import Path

from lab12.database import engine
from lab12.errors import db_error_message
from lab12.migrations import upgrade_schema

_CLI_DIR = Path(__file__).resolve().parent
CREATE_SQL = _CLI_DIR / "create.sql"
INSERT_SQL = _CLI_DIR / "insert.sql"


def _execute_sql_file(path: Path) -> None:
    sql = path.read_text(encoding="utf-8")
    raw = engine.raw_connection()
    try:
        raw.autocommit = True
        with raw.cursor() as cur:
            cur.execute(sql)
    finally:
        raw.close()


def db_reset_and_seed() -> bool:
    try:
        upgrade_schema()
    except Exception as exc:
        print(
            "Не удалось применить миграции Alembic. "
            "Проверьте config.yaml и каталог alembic/.\n"
            f"Подробности: {exc!s}"
        )
        return False
    try:
        _execute_sql_file(CREATE_SQL)
        _execute_sql_file(INSERT_SQL)
    except Exception as exc:
        print(db_error_message(exc))
        return False
    return True
