import datetime
import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from app.models import User
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/cold-compress", tags=["Cold Compress"])

_compress_sessions: List[dict] = []


class CompressSessionCreate(BaseModel):
    duration_seconds: int = Field(300, description="Duration of cold compress session in seconds")
    completed: bool = True
    notes: str = ""


class CompressSessionOut(BaseModel):
    id: str
    user_id: str
    duration_seconds: int
    completed: bool
    notes: str
    timestamp: str


@router.post("", response_model=CompressSessionOut, status_code=status.HTTP_201_CREATED)
def record_compress_session(
    body: CompressSessionCreate,
    current_user: User = Depends(get_current_user)
):
    """Records a completed software cold compress session."""
    session = {
        "id": f"comp-{str(uuid.uuid4())[:8]}",
        "user_id": str(current_user.id),
        "duration_seconds": body.duration_seconds,
        "completed": body.completed,
        "notes": body.notes,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    }
    _compress_sessions.append(session)
    return session


@router.get("", response_model=List[CompressSessionOut])
def get_compress_history(
    current_user: User = Depends(get_current_user)
):
    """Returns history of cold compress therapy sessions."""
    user_id = str(current_user.id)
    user_sessions = [s for s in _compress_sessions if s["user_id"] == user_id]
    return user_sessions
