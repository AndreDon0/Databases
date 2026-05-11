"""Engine and session factory for SQLAlchemy 2.0."""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from lab12.models import Base
from lab12.project_config import ProjectConfig

_config = ProjectConfig()
engine = create_engine(
    _config.sqlalchemy_url,
    echo=False,
    pool_pre_ping=True,
)
SessionLocal = sessionmaker(engine, class_=Session, autoflush=False, autocommit=False)


@contextmanager
def session_scope():
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def get_db() -> Iterator[Session]:
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def get_engine():
    return engine


def get_metadata():
    return Base.metadata
