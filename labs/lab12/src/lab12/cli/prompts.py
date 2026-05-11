"""Terminal input helpers."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation


def read_line(prompt: str) -> str:
    return input(prompt).strip()


def read_cancelable_nonempty(
    prompt: str, empty_msg: str, cancel: str = "1"
) -> str | None:
    while True:
        s = read_line(prompt)
        if s == cancel:
            return None
        if len(s) == 0:
            print(empty_msg)
            continue
        return s


def read_decimal_positive(prompt: str, cancel: str = "1") -> Decimal | None:
    while True:
        s = read_line(f"{prompt} ({cancel} — отмена): ")
        if s == cancel:
            return None
        try:
            d = Decimal(s.replace(",", "."))
        except InvalidOperation:
            print("Введите положительное число (допускается десятичная точка).")
            continue
        if d <= 0:
            print("Значение должно быть больше нуля.")
            continue
        return d


def read_int_in_range(prompt: str, lo: int, hi: int, cancel: str = "1") -> int | None:
    while True:
        s = read_line(f"{prompt} ({cancel} — отмена): ")
        if s == cancel:
            return None
        try:
            n = int(s)
        except ValueError:
            print("Введите целое число.")
            continue
        if n <= lo or n >= hi:
            print(f"Число должно быть от {lo + 1} до {hi - 1} включительно.")
            continue
        return n


def read_int_positive(prompt: str, cancel: str = "1") -> int | None:
    while True:
        s = read_line(f"{prompt} ({cancel} — отмена): ")
        if s == cancel:
            return None
        try:
            n = int(s)
        except ValueError:
            print("Введите целое число.")
            continue
        if n <= 0:
            print("Значение должно быть положительным.")
            continue
        return n


def pick_row(total: int, what: str) -> int | None:
    if total == 0:
        print("Нет записей.")
        return None
    while True:
        s = read_line(
            f"Номер строки ({what}) в списке на экране (0 — отмена): "
        )
        if s == "0":
            return None
        try:
            n = int(s)
        except ValueError:
            print("Введите целое число.")
            continue
        if n < 1 or n > total:
            print("Номер вне диапазона списка.")
            continue
        return n
