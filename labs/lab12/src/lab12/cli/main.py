"""Console entry: rooms and racks menu loop."""

from __future__ import annotations

from lab12.cli import prompts, racks, rooms
from lab12.cli.seed import db_reset_and_seed
from lab12.migrations import upgrade_schema


class Main:
    def __init__(self) -> None:
        self.selected_room_id: int | None = None
        self.room_skip: int = 0
        self.room_total: int = 0
        self.rack_skip: int = 0
        self.rack_total: int = 0

    def show_main_menu(self) -> None:
        menu = """Добро пожаловать!
Основное меню (выберите цифру):
    1 — просмотр помещений;
    2 — применить миграции Alembic, пересоздать схему и заполнить данными;
    9 — выход."""
        print(menu)

    def after_main_menu(self, next_step: str) -> str:
        if next_step == "2":
            warning = (
                "\nВнимание: эта операция необратима для текущих данных.\n"
                "Будут удалены и пересозданы все таблицы склада\n"
                "Затем схема будет создана заново и заполнена данными."
            )
            if not prompts.confirm_destructive_action(warning):
                return "0"
            if db_reset_and_seed():
                print(
                    "Готово: миграции применены, схема пересоздана, данные загружены."
                )
            return "0"
        if next_step not in ("1", "9"):
            print("Выбрано неверное число! Повторите ввод!")
            return "0"
        return next_step

    def run_room_list(self) -> str:
        self.selected_room_id = None
        self.room_total, self.room_skip = rooms.show_rooms(self.room_skip)
        rooms.print_room_menu()
        step = prompts.read_line("=> ")
        if step == "6":
            self.rack_skip = 0
            return "2"
        if step in ("7", "8"):
            delta = -1 if step == "7" else 1
            self.room_skip = rooms.adjust_room_skip(
                self.room_skip, self.room_total, delta
            )
            return self.run_room_list()
        return rooms.process_room_menu(step)

    def after_show_racks(self, next_step: str) -> str:
        while True:
            if next_step == "6":
                racks.show_add_rack(self.selected_room_id)
                self.rack_skip = 0
                next_step, self.selected_room_id, self.rack_skip, self.rack_total = (
                    racks.show_racks_for_room(self.selected_room_id, self.rack_skip)
                )
                continue
            if next_step == "7":
                racks.show_delete_rack(self.selected_room_id)
                self.rack_skip = 0
                next_step, self.selected_room_id, self.rack_skip, self.rack_total = (
                    racks.show_racks_for_room(self.selected_room_id, self.rack_skip)
                )
                continue
            if next_step == "5":
                racks.show_edit_rack(self.selected_room_id)
                self.rack_skip = 0
                next_step, self.selected_room_id, self.rack_skip, self.rack_total = (
                    racks.show_racks_for_room(self.selected_room_id, self.rack_skip)
                )
                continue
            if next_step == "3":
                self.rack_skip = racks.adjust_rack_skip(
                    self.rack_skip, self.rack_total, -1
                )
                next_step, self.selected_room_id, self.rack_skip, self.rack_total = (
                    racks.show_racks_for_room(self.selected_room_id, self.rack_skip)
                )
                continue
            if next_step == "4":
                self.rack_skip = racks.adjust_rack_skip(
                    self.rack_skip, self.rack_total, 1
                )
                next_step, self.selected_room_id, self.rack_skip, self.rack_total = (
                    racks.show_racks_for_room(self.selected_room_id, self.rack_skip)
                )
                continue
            if next_step == "1":
                self.selected_room_id = None
                self.rack_skip = 0
                return "1"
            if next_step == "0":
                self.selected_room_id = None
                self.rack_skip = 0
                return "0"
            if next_step == "9":
                return "9"
            print("Выбрано неверное число! Повторите ввод!")
            next_step = prompts.read_line("=> ")

    def main_cycle(self) -> None:
        current_menu = "0"
        try:
            upgrade_schema()
        except Exception as exc:
            print(
                "Не удалось применить миграции Alembic. Проверьте config.yaml и доступ к PostgreSQL.\n"
                f"Подробности: {exc!s}"
            )
        while current_menu != "9":
            if current_menu == "0":
                self.show_main_menu()
                step = prompts.read_line("=> ")
                nxt = self.after_main_menu(step)
                if nxt == "1":
                    self.room_skip = 0
                current_menu = nxt
            elif current_menu == "1":
                current_menu = self.run_room_list()
            elif current_menu == "2":
                step, self.selected_room_id, self.rack_skip, self.rack_total = (
                    racks.show_racks_for_room(self.selected_room_id, self.rack_skip)
                )
                current_menu = self.after_show_racks(step)
        print("До свидания!")


def main() -> None:
    Main().main_cycle()


if __name__ == "__main__":
    main()
