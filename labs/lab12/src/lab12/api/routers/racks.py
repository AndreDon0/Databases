"""Rack routes nested under a room."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from lab12.api.converters import get_rack_in_room, get_room_by_name, rack_to_out
from lab12.database import get_db
from lab12.errors import db_error_message, http_status_for_db_error
from lab12.models import Rack
from lab12.schemas import RackCreate, RackOut, RackUpdate

router = APIRouter(prefix="/rooms/{room_name}/racks", tags=["racks"])


@router.get("", response_model=list[RackOut])
def list_racks(
    room_name: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
) -> list[RackOut]:
    room = get_room_by_name(db, room_name)
    racks = list(
        db.scalars(
            select(Rack)
            .where(Rack.id_room == room.id_room)
            .order_by(Rack.id_rack)
            .offset(skip)
            .limit(limit)
        ).all()
    )
    start_index = skip + 1
    return [
        RackOut(
            list_index=start_index + i,
            rack_number=rk.rack_number,
            storage_slots=rk.storage_slots,
            max_load=rk.max_load,
            height=rk.height,
            width=rk.width,
            length=rk.length,
        )
        for i, rk in enumerate(racks)
    ]


@router.post("", response_model=RackOut, status_code=201)
def create_rack(
    room_name: str,
    body: RackCreate,
    db: Session = Depends(get_db),
) -> RackOut:
    room = get_room_by_name(db, room_name)
    rack = Rack(
        rack_number=body.rack_number,
        storage_slots=body.storage_slots,
        max_load=body.max_load,
        height=body.height,
        width=body.width,
        length=body.length,
        id_room=room.id_room,
    )
    db.add(rack)
    try:
        db.flush()
    except Exception as exc:
        raise HTTPException(
            status_code=http_status_for_db_error(exc),
            detail=db_error_message(exc),
        ) from exc
    return rack_to_out(db, room, rack)


@router.patch("/{rack_number}", response_model=RackOut)
def update_rack(
    room_name: str,
    rack_number: str,
    body: RackUpdate,
    db: Session = Depends(get_db),
) -> RackOut:
    room = get_room_by_name(db, room_name)
    rack = get_rack_in_room(db, room, rack_number)
    if body.rack_number is not None:
        rack.rack_number = body.rack_number
    if body.storage_slots is not None:
        rack.storage_slots = body.storage_slots
    if body.max_load is not None:
        rack.max_load = body.max_load
    if body.height is not None:
        rack.height = body.height
    if body.width is not None:
        rack.width = body.width
    if body.length is not None:
        rack.length = body.length
    if not any(
        v is not None
        for v in (
            body.rack_number,
            body.storage_slots,
            body.max_load,
            body.height,
            body.width,
            body.length,
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
    db.refresh(rack)
    return rack_to_out(db, room, rack)


@router.delete("/{rack_number}", status_code=204)
def delete_rack(
    room_name: str,
    rack_number: str,
    db: Session = Depends(get_db),
) -> None:
    room = get_room_by_name(db, room_name)
    rack = get_rack_in_room(db, room, rack_number)
    db.delete(rack)
