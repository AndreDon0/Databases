"""Console flows for racks (стеллажи) within a selected room."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from lab12.cli import prompts
from lab12.cli.rooms import load_rooms_ordered
from lab12.database import session_scope
from lab12.errors import db_error_message
from lab12.models import Rack, Room

PAGE_SIZE = 10


def rack_total_in_room(session: Session, id_room: int) -> int:
    return int(
        session.scalar(
            select(func.count()).select_from(Rack).where(Rack.id_room == id_room)
        )
        or 0
    )


def load_racks_page(session: Session, id_room: int, skip: int, limit: int) -> list[Rack]:
    return list(
        session.scalars(
            select(Rack)
            .where(Rack.id_room == id_room)
            .order_by(Rack.id_rack)
            .offset(skip)
            .limit(limit)
        ).all()
    )


def load_racks_ordered(session: Session, id_room: int) -> list[Rack]:
    return list(
        session.scalars(
            select(Rack)
            .where(Rack.id_room == id_room)
            .order_by(Rack.id_rack)
        ).all()
    )


def clamp_rack_skip(skip: int, total: int) -> int:
    if total <= 0:
        return 0
    max_page = (total - 1) // PAGE_SIZE
    page = max(0, min(skip // PAGE_SIZE, max_page))
    return page * PAGE_SIZE


def adjust_rack_skip(current_skip: int, total: int, delta_pages: int) -> int:
    if total <= 0:
        return 0
    max_skip = max(0, ((total - 1) // PAGE_SIZE) * PAGE_SIZE)
    new_skip = current_skip + delta_pages * PAGE_SIZE
    return max(0, min(new_skip, max_skip))


def show_racks_for_room(
    selected_room_id: int | None,
    rack_skip: int,
) -> tuple[str, int | None, int, int]:
    """Returns (next_step, selected_room_id, rack_skip_used, rack_total)."""
    try:
        with session_scope() as session:
            rid = selected_room_id
            if rid is None:
                rooms = load_rooms_ordered(session)
                n = prompts.pick_row(len(rooms), "помещения со стеллажами")
                if n is None:
                    return "1", None, 0, 0
                rid = rooms[n - 1].id_room

            room = session.get(Room, rid)
            if room is None:
                print("Помещение не найдено.")
                return "1", None, 0, 0
            print(
                f"Помещение: {room.room_name} (объём {room.capacity_volume}, "
                f"темп. {room.temp_conditions}, влажн. {room.humidity_conditions}%)"
            )
            total = rack_total_in_room(session, room.id_room)
            skip = clamp_rack_skip(rack_skip, total)
            racks = load_racks_page(session, room.id_room, skip, PAGE_SIZE)
            print("\nСтеллажи (№ в списке — не идентификатор БД):")
            print("№\tНомер\tСлоты\tМакс.кг\tВыс.\tШир.\tДлина")
            start_num = skip + 1
            for i, rk in enumerate(racks):
                idx = start_num + i
                print(
                    f"{idx}\t{rk.rack_number}\t{rk.storage_slots}\t{rk.max_load}\t"
                    f"{rk.height}\t{rk.width}\t{rk.length}"
                )
            end_num = skip + len(racks)
            if total:
                print(
                    f"Показано {start_num}–{end_num} из {total} "
                    f"(по {PAGE_SIZE} на страницу)."
                )
            else:
                print("(нет стеллажей в этом помещении)")
    except Exception as exc:
        print(db_error_message(exc))
        return "1", None, 0, 0

    menu = """Дальнейшие операции:
    0 — главное меню;
    1 — назад к списку помещений;
    3 — предыдущая страница стеллажей;
    4 — следующая страница стеллажей;
    5 — изменить стеллаж;
    6 — добавить стеллаж в это помещение;
    7 — удалить стеллаж;
    9 — выход."""
    print(menu)
    return prompts.read_line("=> "), rid, skip, total


def show_add_rack(selected_room_id: int | None) -> None:
    if selected_room_id is None:
        print("Сначала выберите помещение.")
        return
    rack_no = prompts.read_cancelable_nonempty(
        "Номер стеллажа (уникален в пределах помещения, 0 — отмена): ",
        "Номер не может быть пустым.",
    )
    if rack_no is None:
        return
    if len(rack_no) > 20:
        print("Номер стеллажа не длиннее 20 символов.")
        return
    slots = prompts.read_int_positive("Число мест (storage_slots)")
    if slots is None:
        return
    load = prompts.read_decimal_positive("Максимальная нагрузка, кг (max_load)")
    if load is None:
        return
    h = prompts.read_decimal_positive("Высота (м)")
    if h is None:
        return
    w = prompts.read_decimal_positive("Ширина (м)")
    if w is None:
        return
    ln = prompts.read_decimal_positive("Длина (м)")
    if ln is None:
        return
    try:
        with session_scope() as session:
            room = session.get(Room, selected_room_id)
            if room is None:
                print("Помещение не найдено.")
                return
            session.add(
                Rack(
                    rack_number=rack_no,
                    storage_slots=slots,
                    max_load=load,
                    height=h,
                    width=w,
                    length=ln,
                    id_room=room.id_room,
                )
            )
        print("Стеллаж добавлен.")
    except Exception as exc:
        print(db_error_message(exc))


def show_delete_rack(selected_room_id: int | None) -> None:
    if selected_room_id is None:
        return
    try:
        with session_scope() as session:
            room = session.get(Room, selected_room_id)
            if room is None:
                print("Помещение не найдено.")
                return
            racks = load_racks_ordered(session, room.id_room)
            n = prompts.pick_row(len(racks), "удаляемого стеллажа")
            if n is None:
                return
            rk = racks[n - 1]
            c = prompts.read_line(
                f"Удалить стеллаж «{rk.rack_number}»? (да/нет): "
            ).lower()
            if c not in ("да", "д", "yes", "y"):
                print("Отменено.")
                return
            session.delete(rk)
        print("Стеллаж удалён.")
    except Exception as exc:
        print(db_error_message(exc))


def show_edit_rack(selected_room_id: int | None) -> None:
    if selected_room_id is None:
        return
    try:
        with session_scope() as session:
            room = session.get(Room, selected_room_id)
            if room is None:
                print("Помещение не найдено.")
                return
            racks = load_racks_ordered(session, room.id_room)
            n = prompts.pick_row(len(racks), "редактируемого стеллажа")
            if n is None:
                return
            rk = session.get(Rack, racks[n - 1].id_rack)
            if rk is None:
                print("Запись не найдена.")
                return
            print(
                f"Редактирование стеллажа «{rk.rack_number}» "
                f"(пустая строка — оставить как есть; 0 — отмена всего)"
            )
            new_no = prompts.read_line("Новый номер стеллажа в помещении: ")
            if new_no == "0":
                return
            if new_no != "":
                if len(new_no) > 20:
                    print("Номер стеллажа не длиннее 20 символов.")
                    return
                rk.rack_number = new_no
            s_slots = prompts.read_line("Число мест (целое > 0) или Enter: ")
            if s_slots != "":
                try:
                    slots = int(s_slots)
                except ValueError:
                    print("Некорректное целое.")
                    return
                if slots <= 0:
                    print("Число мест должно быть положительным.")
                    return
                rk.storage_slots = slots
            s_load = prompts.read_line("Макс. нагрузка (кг) или Enter: ")
            if s_load != "":
                try:
                    load = Decimal(s_load.replace(",", "."))
                except InvalidOperation:
                    print("Некорректное число.")
                    return
                if load <= 0:
                    print("Нагрузка должна быть > 0.")
                    return
                rk.max_load = load
            for label, attr in (
                ("Высота (м)", "height"),
                ("Ширина (м)", "width"),
                ("Длина (м)", "length"),
            ):
                s = prompts.read_line(f"{label} или Enter: ")
                if s != "":
                    try:
                        d = Decimal(s.replace(",", "."))
                    except InvalidOperation:
                        print("Некорректное число.")
                        return
                    if d <= 0:
                        print("Значение должно быть > 0.")
                        return
                    setattr(rk, attr, d)
        print("Стеллаж обновлён.")
    except Exception as exc:
        print(db_error_message(exc))
