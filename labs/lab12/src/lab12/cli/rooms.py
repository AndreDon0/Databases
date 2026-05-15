"""Console flows for rooms (помещения)."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from lab12.cli import prompts
from lab12.database import session_scope
from lab12.errors import db_error_message
from lab12.models import Room

PAGE_SIZE = 10


def load_rooms_ordered(session: Session) -> list[Room]:
    return list(session.scalars(select(Room).order_by(Room.id_room)).all())


def room_total_count(session: Session) -> int:
    return int(session.scalar(select(func.count()).select_from(Room)) or 0)


def load_rooms_page(session: Session, skip: int, limit: int) -> list[Room]:
    return list(
        session.scalars(
            select(Room).order_by(Room.id_room).offset(skip).limit(limit)
        ).all()
    )


def clamp_room_skip(skip: int, total: int) -> int:
    if total <= 0:
        return 0
    max_page = (total - 1) // PAGE_SIZE
    page = max(0, min(skip // PAGE_SIZE, max_page))
    return page * PAGE_SIZE


def show_rooms(room_skip: int) -> tuple[int, int]:
    """Print one page of rooms. Returns (total_count, effective_skip)."""
    print("\nСписок помещений!")
    print("№\tНазвание\tОбъём\tТемп.\tВлажн.%")
    try:
        with session_scope() as session:
            total = room_total_count(session)
            if total == 0:
                print("(нет записей)")
                return 0, 0
            skip = clamp_room_skip(room_skip, total)
            rooms = load_rooms_page(session, skip, PAGE_SIZE)
            start_num = skip + 1
            for i, r in enumerate(rooms):
                idx = start_num + i
                print(
                    f"{idx}\t{r.room_name}\t{r.capacity_volume}\t"
                    f"{r.temp_conditions}\t{r.humidity_conditions}"
                )
            end_num = skip + len(rooms)
            print(
                f"Показано {start_num}–{end_num} из {total} "
                f"(по {PAGE_SIZE} на страницу)."
            )
    except Exception as exc:
        print(db_error_message(exc))
        return 0, 0

    return total, skip


def print_room_menu() -> None:
    menu = """Дальнейшие операции:
    0 — возврат в главное меню;
    3 — добавить помещение;
    4 — удалить помещение;
    5 — изменить помещение;
    6 — просмотр стеллажей помещения;
    7 — предыдущая страница помещений;
    8 — следующая страница помещений;
    9 — выход."""
    print(menu)


def show_add_room() -> None:
    name = prompts.read_cancelable_nonempty(
        "Название помещения (0 — отмена): ",
        "Название не может быть пустым.",
    )
    if name is None:
        return
    if len(name) > 100:
        print("Название не длиннее 100 символов.")
        return
    cap = prompts.read_decimal_positive("Объём помещения (capacity_volume)")
    if cap is None:
        return
    temp = prompts.read_int_in_range(
        "Температурный режим (целое, 1–99)", 0, 100
    )
    if temp is None:
        return
    hum = prompts.read_int_in_range("Влажность (целое, 1–99)", 0, 100)
    if hum is None:
        return
    try:
        with session_scope() as session:
            session.add(
                Room(
                    room_name=name,
                    capacity_volume=cap,
                    temp_conditions=temp,
                    humidity_conditions=hum,
                )
            )
        print("Помещение добавлено.")
    except Exception as exc:
        print(db_error_message(exc))


def show_delete_room() -> None:
    try:
        with session_scope() as session:
            rooms = load_rooms_ordered(session)
            n = prompts.pick_row(len(rooms), "удаляемого помещения")
            if n is None:
                return
            room = rooms[n - 1]
            c = prompts.read_line(
                f"Удалить помещение «{room.room_name}» и все его стеллажи? (да/нет): "
            ).lower()
            if c not in ("да", "д", "yes", "y"):
                print("Отменено.")
                return
            session.delete(room)
        print("Помещение и связанные стеллажи удалены.")
    except Exception as exc:
        print(db_error_message(exc))


def show_edit_room() -> None:
    try:
        with session_scope() as session:
            rooms = load_rooms_ordered(session)
            n = prompts.pick_row(len(rooms), "редактируемого помещения")
            if n is None:
                return
            room = session.get(Room, rooms[n - 1].id_room)
            if room is None:
                print("Запись не найдена.")
                return
            print(
                f"Редактирование: {room.room_name} "
                f"(пустая строка — оставить как есть)"
            )
            new_name = prompts.read_line("Новое название (0 — отмена всего): ")
            if new_name == "0":
                return
            if new_name != "":
                if len(new_name) > 100:
                    print("Название не длиннее 100 символов.")
                    return
                room.room_name = new_name
            s_cap = prompts.read_line("Новый объём (положительное число) или Enter: ")
            if s_cap != "":
                try:
                    d = Decimal(s_cap.replace(",", "."))
                except InvalidOperation:
                    print("Некорректное число.")
                    return
                if d <= 0:
                    print("Объём должен быть > 0.")
                    return
                room.capacity_volume = d
            s_temp = prompts.read_line("Новая температура (1–99) или Enter: ")
            if s_temp != "":
                try:
                    t = int(s_temp)
                except ValueError:
                    print("Некорректное целое.")
                    return
                if t <= 0 or t >= 100:
                    print("Температура должна быть от 1 до 99.")
                    return
                room.temp_conditions = t
            s_hum = prompts.read_line("Новая влажность (1–99) или Enter: ")
            if s_hum != "":
                try:
                    h = int(s_hum)
                except ValueError:
                    print("Некорректное целое.")
                    return
                if h <= 0 or h >= 100:
                    print("Влажность должна быть от 1 до 99.")
                    return
                room.humidity_conditions = h
        print("Помещение обновлено.")
    except Exception as exc:
        print(db_error_message(exc))


def process_room_menu(next_step: str) -> str:
    if next_step == "3":
        show_add_room()
        return "1"
    if next_step == "4":
        show_delete_room()
        return "1"
    if next_step == "5":
        show_edit_room()
        return "1"
    if next_step == "0":
        return "0"
    if next_step == "9":
        return "9"
    if next_step == "7":
        return "room_prev"
    if next_step == "8":
        return "room_next"
    print("Выбрано неверное число! Повторите ввод!")
    return "1"


def adjust_room_skip(current_skip: int, total: int, delta_pages: int) -> int:
    if total <= 0:
        return 0
    max_skip = max(0, ((total - 1) // PAGE_SIZE) * PAGE_SIZE)
    new_skip = current_skip + delta_pages * PAGE_SIZE
    return max(0, min(new_skip, max_skip))
