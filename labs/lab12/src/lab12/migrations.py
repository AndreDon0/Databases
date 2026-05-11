"""Apply Alembic migrations to head."""

from __future__ import annotations

from alembic import command
from alembic.config import Config

from lab12.paths import PROJECT_ROOT


def alembic_config() -> Config:
    ini = PROJECT_ROOT / "alembic.ini"
    return Config(str(ini))


def upgrade_schema() -> None:
    command.upgrade(alembic_config(), "head")
