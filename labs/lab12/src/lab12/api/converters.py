"""DB rows to API models; lookups by natural keys."""

from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from lab12.models import Rack, Room
from lab12.schemas import RackOut, RoomOut


def get_room_by_name(session: Session, room_name: str) -> Room:
    room = session.scalar(select(Room).where(Room.room_name == room_name))
    if room is None:
        raise HTTPException(status_code=404, detail="Помещение не найдено.")
    return room


def get_rack_in_room(session: Session, room: Room, rack_number: str) -> Rack:
    rk = session.scalar(
        select(Rack).where(Rack.id_room == room.id_room, Rack.rack_number == rack_number)
    )
    if rk is None:
        raise HTTPException(status_code=404, detail="Стеллаж не найден в этом помещении.")
    return rk


def room_list_index(db: Session, room: Room) -> int:
    n_before = db.scalar(
        select(func.count()).select_from(Room).where(Room.id_room < room.id_room)
    )
    return int(n_before or 0) + 1


def rack_list_index(db: Session, room: Room, rack: Rack) -> int:
    n_before = db.scalar(
        select(func.count())
        .select_from(Rack)
        .where(Rack.id_room == room.id_room, Rack.id_rack < rack.id_rack)
    )
    return int(n_before or 0) + 1


def room_to_out(db: Session, room: Room) -> RoomOut:
    return RoomOut(
        list_index=room_list_index(db, room),
        room_name=room.room_name,
        capacity_volume=room.capacity_volume,
        temp_conditions=room.temp_conditions,
        humidity_conditions=room.humidity_conditions,
    )


def rack_to_out(db: Session, room: Room, rack: Rack) -> RackOut:
    return RackOut(
        list_index=rack_list_index(db, room, rack),
        rack_number=rack.rack_number,
        storage_slots=rack.storage_slots,
        max_load=rack.max_load,
        height=rack.height,
        width=rack.width,
        length=rack.length,
    )
