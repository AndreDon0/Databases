"""Apply Alembic migrations to head."""

from __future__ import annotations

import logging

from alembic import command
from alembic.config import Config

from lab12.paths import PROJECT_ROOT

_ALEMBIC_LOGGER_NAMES = ("alembic", "alembic.runtime", "alembic.runtime.migration")


def alembic_config() -> Config:
    ini = PROJECT_ROOT / "alembic.ini"
    return Config(str(ini))


def _quiet_alembic_logging() -> None:
    for name in _ALEMBIC_LOGGER_NAMES:
        logging.getLogger(name).setLevel(logging.WARNING)


def upgrade_schema() -> None:
    _quiet_alembic_logging()
    command.upgrade(alembic_config(), "head")
    _quiet_alembic_logging()
