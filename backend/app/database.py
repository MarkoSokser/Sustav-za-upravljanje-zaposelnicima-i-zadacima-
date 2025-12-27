"""
Database Connection Module
Povezivanje s PostgreSQL bazom podataka
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from typing import Generator
from .config import get_settings


settings = get_settings()


def get_connection():
    """Kreira novu konekciju na bazu podataka"""
    return psycopg2.connect(
        host=settings.database_host,
        port=settings.database_port,
        database=settings.database_name,
        user=settings.database_user,
        password=settings.database_password,
        cursor_factory=RealDictCursor
    )


@contextmanager
def get_db() -> Generator:
    """
    Context manager za database konekciju
    Automatski commit-a ili rollback-a transakciju
    """
    conn = get_connection()
    try:
        # Postavi search_path na employee_management shemu
        with conn.cursor() as cur:
            cur.execute("SET search_path TO employee_management")
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def get_db_dependency():
    """
    FastAPI Dependency za database konekciju
    Koristi se u route-ovima
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SET search_path TO employee_management")
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
