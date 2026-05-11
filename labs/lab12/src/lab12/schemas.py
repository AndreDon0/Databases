"""Pydantic schemas for the HTTP API (natural keys only in URLs)."""

from __future__ import annotations

from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class RoomCreate(BaseModel):
    room_name: str = Field(..., min_length=1, max_length=100)
    capacity_volume: Decimal = Field(..., gt=0)
    temp_conditions: int = Field(..., ge=1, le=99)
    humidity_conditions: int = Field(..., ge=1, le=99)


class RoomUpdate(BaseModel):
    room_name: str | None = Field(None, min_length=1, max_length=100)
    capacity_volume: Decimal | None = Field(None, gt=0)
    temp_conditions: int | None = Field(None, ge=1, le=99)
    humidity_conditions: int | None = Field(None, ge=1, le=99)


class RoomOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    list_index: int = Field(..., description="Позиция в текущем списке (страница и сортировка).")
    room_name: str
    capacity_volume: Decimal
    temp_conditions: int
    humidity_conditions: int


class RackCreate(BaseModel):
    rack_number: str = Field(..., min_length=1, max_length=20)
    storage_slots: int = Field(..., gt=0)
    max_load: Decimal = Field(..., gt=0)
    height: Decimal = Field(..., gt=0)
    width: Decimal = Field(..., gt=0)
    length: Decimal = Field(..., gt=0)


class RackUpdate(BaseModel):
    rack_number: str | None = Field(None, min_length=1, max_length=20)
    storage_slots: int | None = Field(None, gt=0)
    max_load: Decimal | None = Field(None, gt=0)
    height: Decimal | None = Field(None, gt=0)
    width: Decimal | None = Field(None, gt=0)
    length: Decimal | None = Field(None, gt=0)


class RackOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    list_index: int = Field(..., description="Позиция в текущем списке (страница и сортировка).")
    rack_number: str
    storage_slots: int
    max_load: Decimal
    height: Decimal
    width: Decimal
    length: Decimal


class RackWithRoomOut(BaseModel):
    """Стеллаж в общем списке склада с указанием помещения."""

    model_config = ConfigDict(from_attributes=True)

    list_index: int = Field(..., description="Позиция в текущем списке (страница и сортировка).")
    room_name: str
    rack_number: str
    storage_slots: int
    max_load: Decimal
    height: Decimal
    width: Decimal
    length: Decimal
