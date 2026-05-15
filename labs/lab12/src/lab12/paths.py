"""Filesystem locations for the lab12 project."""

from __future__ import annotations

from pathlib import Path

_PACKAGE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = _PACKAGE_DIR.parent.parent
SITE_DIR = PROJECT_ROOT / "site"