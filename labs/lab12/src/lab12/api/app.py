"""FastAPI application."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from lab12.api.routers import inventory, racks, rooms
from lab12.migrations import upgrade_schema
from lab12.paths import PROJECT_ROOT

SITE_DIR = PROJECT_ROOT / "site"


@asynccontextmanager
async def lifespan(_app: FastAPI):
    upgrade_schema()
    yield


app = FastAPI(
    title="Управление складом",
    lifespan=lifespan,
)
app.include_router(rooms.router)
app.include_router(racks.router)
app.include_router(inventory.router)


@app.get("/")
def index() -> FileResponse:
    return FileResponse(SITE_DIR / "index.html")


@app.get("/warehouse/rooms")
def warehouse_rooms() -> FileResponse:
    return FileResponse(SITE_DIR / "rooms.html")


@app.get("/warehouse/racks")
def warehouse_racks() -> FileResponse:
    return FileResponse(SITE_DIR / "racks.html")


app.mount("/static", StaticFiles(directory=str(SITE_DIR)), name="static")
