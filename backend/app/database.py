from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings
import logging

logger = logging.getLogger(__name__)

db_url = settings.DATABASE_URL

# Attempt to connect to configured DATABASE_URL (Supabase PostgreSQL)
# Fallback to local SQLite if remote PostgreSQL is unreachable/offline
engine = None
if "sqlite" in db_url:
    engine = create_engine(db_url, connect_args={"check_same_thread": False})
else:
    try:
        test_engine = create_engine(db_url, pool_pre_ping=True, connect_args={"connect_timeout": 3})
        with test_engine.connect() as conn:
            pass
        engine = test_engine
        logger.info("Successfully connected to Supabase PostgreSQL database.")
    except Exception as e:
        logger.warning(f"Could not connect to remote PostgreSQL ({e}). Using local SQLite database fallback.")
        engine = create_engine("sqlite:///./ocusense_dev.db", connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
