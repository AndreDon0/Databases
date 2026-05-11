"""Room routes."""

from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from lab12.api.converters import get_room_by_name, room_to_out
from lab12.database import get_db
from lab12.errors import db_error_message, http_status_for_db_error
from lab12.models import Room
from lab12.schemas import RoomCreate, RoomOut, RoomUpdate

router = APIRouter(prefix="/rooms", tags=["rooms"])

ROOM_SORT_FIELDS = frozenset(
    {"room_name", "capacity_volume", "temp_conditions", "humidity_conditions", "id_room"}
)


def _room_order_columns(
    sort: str,
    order: Literal["asc", "desc"],
) -> tuple:
    desc = order == "desc"
    key = sort if sort in ROOM_SORT_FIELDS else "id_room"
    col_map = {
        "room_name": Room.room_name,
        "capacity_volume": Room.capacity_volume,
        "temp_conditions": Room.temp_conditions,
        "humidity_conditions": Room.humidity_conditions,
        "id_room": Room.id_room,
    }
    primary = col_map[key]
    primary_expr = primary.desc() if desc else primary.asc()
    tie = Room.id_room.asc()
    return primary_expr, tie


@router.get("", response_model=list[RoomOut])
def list_rooms(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    sort: str = Query("id_room", description="Поле сортировки"),
    order: Literal["asc", "desc"] = Query("asc"),
    db: Session = Depends(get_db),
) -> list[RoomOut]:
    primary_expr, tie = _room_order_columns(sort, order)
    rooms = list(
        db.scalars(
            select(Room).order_by(primary_expr, tie).offset(skip).limit(limit)
        ).all()
    )
    start_index = skip + 1
    return [
        RoomOut(
            list_index=start_index + i,
            room_name=r.room_name,
            capacity_volume=r.capacity_volume,
            temp_conditions=r.temp_conditions,
            humidity_conditions=r.humidity_conditions,
        )
        for i, r in enumerate(rooms)
    ]


@router.post("", response_model=RoomOut, status_code=201)
def create_room(body: RoomCreate, db: Session = Depends(get_db)) -> RoomOut:
    room = Room(
        room_name=body.room_name,
        capacity_volume=body.capacity_volume,
        temp_conditions=body.temp_conditions,
        humidity_conditions=body.humidity_conditions,
    )
    db.add(room)
    try:
        db.flush()
    except Exception as exc:
        raise HTTPException(
            status_code=http_status_for_db_error(exc),
            detail=db_error_message(exc),
        ) from exc
    return room_to_out(db, room)


@router.patch("/{room_name}", response_model=RoomOut)
def update_room(
    room_name: str,
    body: RoomUpdate,
    db: Session = Depends(get_db),
) -> RoomOut:
    room = get_room_by_name(db, room_name)
    if body.room_name is not None:
        room.room_name = body.room_name
    if body.capacity_volume is not None:
        room.capacity_volume = body.capacity_volume
    if body.temp_conditions is not None:
        room.temp_conditions = body.temp_conditions
    if body.humidity_conditions is not None:
        room.humidity_conditions = body.humidity_conditions
    if not any(
        v is not None
        for v in (
            body.room_name,
            body.capacity_volume,
            body.temp_conditions,
            body.humidity_conditions,
        )
    ):
        raise HTTPException(status_code=400, detail="Нет полей для обновления.")
    try:
        db.flush()
    except Exception as exc:
        raise HTTPException(
            status_code=http_status_for_db_error(exc),
            detail=db_error_message(exc),
        ) from exc
    db.refresh(room)
    return room_to_out(db, room)


@router.delete("/{room_name}", status_code=204)
def delete_room(room_name: str, db: Session = Depends(get_db)) -> None:
    room = get_room_by_name(db, room_name)
    db.delete(room)
