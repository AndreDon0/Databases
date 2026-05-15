"""User-facing messages for database errors (no raw PostgreSQL text)."""

from __future__ import annotations

import psycopg2.errors
from sqlalchemy.exc import DataError, IntegrityError

_CHECK_MESSAGES: dict[str, str] = {
    "ck_room_capacity_volume_positive": "объём помещения (capacity_volume) должен быть > 0",
    "ck_room_temp_conditions_valid": "температура помещения — целое от 1 до 99",
    "ck_room_humidity_conditions_valid": "влажность помещения — целое от 1 до 99",
    "ck_rack_storage_slots_positive": "число мест (storage_slots) должно быть > 0",
    "ck_rack_max_load_positive": "максимальная нагрузка (max_load) должна быть > 0",
    "ck_rack_dimensions_positive": "высота, ширина и длина стеллажа должны быть > 0",
}

_ROOM_BOUNDARIES = """Помещение (room):
  • название — до 100 символов;
  • объём — число > 0, не более 8 цифр до запятой и 2 после (тип NUMERIC(10,2), макс. 99 999 999,99);
  • температура и влажность — целые от 1 до 99."""

_RACK_BOUNDARIES = """Стеллаж (rack):
  • номер в помещении — до 20 символов;
  • число мест — целое > 0, не больше 2 147 483 647;
  • макс. нагрузка — число > 0, NUMERIC(10,2), макс. 99 999 999,99;
  • высота, ширина, длина — числа > 0, NUMERIC(10,3), макс. 9 999 999,999."""


def _constraint_name(exc: Exception) -> str | None:
    orig = getattr(exc, "orig", None)
    if orig is None:
        return None
    msg = str(orig)
    if "violates check constraint" in msg:
        return msg.split('"')[1] if '"' in msg else None
    diag = getattr(orig, "diag", None)
    if diag is not None and getattr(diag, "constraint_name", None):
        return diag.constraint_name
    return None


def _append_boundaries(message: str, *sections: str) -> str:
    parts = [message, "", "Допустимые границы:"]
    for section in sections:
        parts.append(section)
    return "\n".join(parts)


def db_error_message(exc: Exception) -> str:
    orig = getattr(exc, "orig", None)

    if isinstance(exc, IntegrityError) and orig is not None:
        if isinstance(orig, psycopg2.errors.UniqueViolation):
            return (
                "Такая запись уже есть: нарушено ограничение уникальности "
                "(название помещения или номер стеллажа в этом помещении)."
            )
        if isinstance(orig, psycopg2.errors.ForeignKeyViolation):
            return "Нарушена связь с другой таблицей (внутренняя ошибка данных)."
        if isinstance(orig, psycopg2.errors.NotNullViolation):
            return _append_boundaries(
                "Не задано обязательное поле.",
                _ROOM_BOUNDARIES,
                _RACK_BOUNDARIES,
            )
        if isinstance(orig, psycopg2.errors.CheckViolation):
            name = _constraint_name(exc)
            detail = _CHECK_MESSAGES.get(name) if name else None
            if detail:
                msg = f"Нарушено ограничение: {detail}."
            else:
                msg = (
                    "Значение не удовлетворяет правилам таблицы "
                    "(положительные объёмы, габариты, нагрузка; "
                    "температура и влажность от 1 до 99)."
                )
            return _append_boundaries(msg, _ROOM_BOUNDARIES, _RACK_BOUNDARIES)

    if isinstance(exc, DataError) and orig is not None:
        if isinstance(orig, psycopg2.errors.StringDataRightTruncation):
            return _append_boundaries(
                "Слишком длинная строка: превышена длина поля "
                "(название помещения — 100 символов, номер стеллажа — 20).",
                _ROOM_BOUNDARIES,
                _RACK_BOUNDARIES,
            )
        if isinstance(orig, psycopg2.errors.NumericValueOutOfRange):
            detail = str(orig).lower()
            if "integer" in detail:
                field = "число мест (storage_slots)"
                limit = "целое > 0, не больше 2 147 483 647"
            else:
                field = "десятичное поле (объём, нагрузка или габарит)"
                limit = (
                    "NUMERIC(10,2) для объёма/нагрузки — макс. 99 999 999,99; "
                    "NUMERIC(10,3) для габаритов — макс. 9 999 999,999"
                )
            return _append_boundaries(
                f"Число вне допустимого диапазона: {field}. {limit}.",
                _ROOM_BOUNDARIES,
                _RACK_BOUNDARIES,
            )

    return _append_boundaries(
        "Не удалось выполнить операцию в базе данных. "
        "Проверьте введённые значения.",
        _ROOM_BOUNDARIES,
        _RACK_BOUNDARIES,
    )


def http_status_for_db_error(exc: Exception) -> int:
    if isinstance(exc, IntegrityError) and exc.orig is not None:
        if isinstance(exc.orig, psycopg2.errors.UniqueViolation):
            return 409
    return 400
