"""Global inventory listing (all racks across rooms)."""

from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from lab12.database import get_db
from lab12.models import Rack, Room
from lab12.schemas import RackWithRoomOut

router = APIRouter(tags=["inventory"])

RACK_SORT_FIELDS = frozenset(
    {"room_name", "rack_number", "storage_slots", "max_load", "height", "width", "length", "id_rack"}
)


def _rack_order_columns(
    sort: str,
    order: Literal["asc", "desc"],
) -> tuple:
    desc = order == "desc"
    key = sort if sort in RACK_SORT_FIELDS else "id_rack"
    col_map = {
        "room_name": Room.room_name,
        "rack_number": Rack.rack_number,
        "storage_slots": Rack.storage_slots,
        "max_load": Rack.max_load,
        "height": Rack.height,
        "width": Rack.width,
        "length": Rack.length,
        "id_rack": Rack.id_rack,
    }
    primary = col_map[key]
    primary_expr = primary.desc() if desc else primary.asc()
    tie = Rack.id_rack.asc()
    return primary_expr, tie


@router.get("/racks", response_model=list[RackWithRoomOut])
def list_all_racks(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500),
    sort: str = Query("id_rack", description="Поле сортировки"),
    order: Literal["asc", "desc"] = Query("asc"),
    room_name: str | None = Query(
        None,
        description="Фильтр по названию помещения (точное совпадение)",
    ),
    db: Session = Depends(get_db),
) -> list[RackWithRoomOut]:
    primary_expr, tie = _rack_order_columns(sort, order)
    stmt: Select = select(Rack, Room.room_name).join(
        Room, Rack.id_room == Room.id_room
    )
    if room_name is not None and room_name != "":
        stmt = stmt.where(Room.room_name == room_name)
    stmt = stmt.order_by(primary_expr, tie).offset(skip).limit(limit)
    rows = list(db.execute(stmt).all())
    start_index = skip + 1
    return [
        RackWithRoomOut(
            list_index=start_index + i,
            room_name=rn,
            rack_number=rk.rack_number,
            storage_slots=rk.storage_slots,
            max_load=rk.max_load,
            height=rk.height,
            width=rk.width,
            length=rk.length,
        )
        for i, (rk, rn) in enumerate(rows)
    ]
