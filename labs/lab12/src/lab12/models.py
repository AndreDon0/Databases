"""SQLAlchemy 2.0 models: помещения (room) и стеллажи (rack)"""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy import (
    CheckConstraint,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Room(Base):
    __tablename__ = "room"
    __table_args__ = (
        UniqueConstraint("room_name", name="room_room_name_key"),
        CheckConstraint("capacity_volume > 0", name="ck_room_capacity_volume_positive"),
        CheckConstraint(
            "temp_conditions > 0 AND temp_conditions < 100",
            name="ck_room_temp_conditions_valid",
        ),
        CheckConstraint(
            "humidity_conditions > 0 AND humidity_conditions < 100",
            name="ck_room_humidity_conditions_valid",
        ),
        {"schema": "public"},
    )

    id_room: Mapped[int] = mapped_column(
        SmallInteger, primary_key=True, autoincrement=True
    )
    room_name: Mapped[str] = mapped_column(String(100))
    capacity_volume: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    temp_conditions: Mapped[int] = mapped_column(SmallInteger)
    humidity_conditions: Mapped[int] = mapped_column(SmallInteger)

    racks: Mapped[list[Rack]] = relationship(
        "Rack", back_populates="room", passive_deletes=True
    )


class Rack(Base):
    __tablename__ = "rack"
    __table_args__ = (
        UniqueConstraint("rack_number", "id_room", name="rack_rack_number_id_room_key"),
        CheckConstraint("storage_slots > 0", name="ck_rack_storage_slots_positive"),
        CheckConstraint("max_load > 0", name="ck_rack_max_load_positive"),
        CheckConstraint(
            "height > 0 AND width > 0 AND length > 0",
            name="ck_rack_dimensions_positive",
        ),
        {"schema": "public"},
    )

    id_rack: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    rack_number: Mapped[str] = mapped_column(String(20))
    storage_slots: Mapped[int] = mapped_column(Integer)
    max_load: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    height: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    width: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    length: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    id_room: Mapped[int] = mapped_column(
        SmallInteger,
        ForeignKey("public.room.id_room", ondelete="CASCADE"),
        nullable=False,
    )

    room: Mapped[Room] = relationship("Room", back_populates="racks")
