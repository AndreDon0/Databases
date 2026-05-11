"""DB reset and sample seed data."""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy import delete
from sqlalchemy.orm import Session

from lab12.database import session_scope
from lab12.errors import db_error_message
from lab12.migrations import upgrade_schema
from lab12.models import Rack, Room


def seed(session: Session) -> None:
    r1 = Room(
        room_name="Склад А",
        capacity_volume=Decimal("120.50"),
        temp_conditions=18,
        humidity_conditions=45,
    )
    r2 = Room(
        room_name="Склад Б",
        capacity_volume=Decimal("200.00"),
        temp_conditions=20,
        humidity_conditions=50,
    )
    r3 = Room(
        room_name="Холодный зал",
        capacity_volume=Decimal("80.25"),
        temp_conditions=4,
        humidity_conditions=60,
    )
    session.add_all([r1, r2, r3])
    session.flush()
    session.add_all(
        [
            Rack(
                rack_number="R-A-01",
                storage_slots=10,
                max_load=Decimal("500.00"),
                height=Decimal("2.000"),
                width=Decimal("1.000"),
                length=Decimal("0.800"),
                id_room=r1.id_room,
            ),
            Rack(
                rack_number="R-B-01",
                storage_slots=8,
                max_load=Decimal("300.00"),
                height=Decimal("1.800"),
                width=Decimal("0.900"),
                length=Decimal("0.700"),
                id_room=r2.id_room,
            ),
            Rack(
                rack_number="R-C-01",
                storage_slots=12,
                max_load=Decimal("750.00"),
                height=Decimal("2.200"),
                width=Decimal("1.100"),
                length=Decimal("1.000"),
                id_room=r3.id_room,
            ),
        ]
    )


def db_reset_and_seed() -> None:
    upgrade_schema()
    try:
        with session_scope() as session:
            session.execute(delete(Rack))
            session.execute(delete(Room))
            seed(session)
    except Exception as exc:
        print(db_error_message(exc))
