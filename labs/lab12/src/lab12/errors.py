"""User-facing messages for database errors (no raw PostgreSQL text)."""

from __future__ import annotations

import psycopg2.errors
from sqlalchemy.exc import IntegrityError


def db_error_message(exc: Exception) -> str:
    if isinstance(exc, IntegrityError) and exc.orig is not None:
        o = exc.orig
        if isinstance(o, psycopg2.errors.UniqueViolation):
            return (
                "Такая запись уже есть: нарушено ограничение уникальности "
                "(например, название помещения или номер стеллажа в этом помещении)."
            )
        if isinstance(o, psycopg2.errors.ForeignKeyViolation):
            return "Нарушена связь с другой таблицей (внутренняя ошибка данных)."
        if isinstance(o, psycopg2.errors.NotNullViolation):
            return "Не задано обязательное поле."
        if isinstance(o, psycopg2.errors.CheckViolation):
            return (
                "Значение не удовлетворяет правилам таблицы "
                "(объём > 0, температура и влажность от 1 до 99, "
                "положительные габариты и нагрузка и т.д.)."
            )
    return (
        "Не удалось выполнить операцию в базе данных. "
        "Проверьте введённые значения и ограничения."
    )


def http_status_for_db_error(exc: Exception) -> int:
    if isinstance(exc, IntegrityError) and exc.orig is not None:
        if isinstance(exc.orig, psycopg2.errors.UniqueViolation):
            return 409
    return 400
