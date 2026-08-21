import datetime
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/reminders", tags=["Reminders"])

# In-memory store for user reminders (can be expanded to SQL model if needed)
_reminders_db: List[dict] = [
    {
        "id": "rem-1",
        "user_id": "system",
        "title": "Morning Eye Drops",
        "type": "EYE_DROPS",
        "time": "08:00 AM",
        "frequency": "Daily",
        "is_enabled": True
    },
    {
        "id": "rem-2",
        "user_id": "system",
        "title": "Cold Compress Relief",
        "type": "COLD_COMPRESS",
        "time": "02:00 PM",
        "frequency": "Daily",
        "is_enabled": True
    }
]


class ReminderCreate(BaseModel):
    title: str = Field(..., description="Reminder title e.g. Night Drops")
    type: str = Field("EYE_DROPS", description="EYE_DROPS, COLD_COMPRESS, CUSTOM")
    time: str = Field("08:00 AM", description="Formatted time string")
    frequency: str = Field("Daily", description="Daily, Weekdays, Custom")
    is_enabled: bool = True


class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    type: Optional[str] = None
    time: Optional[str] = None
    frequency: Optional[str] = None
    is_enabled: Optional[bool] = None


class ReminderOut(BaseModel):
    id: str
    user_id: str
    title: str
    type: str
    time: str
    frequency: str
    is_enabled: bool


@router.get("", response_model=List[ReminderOut])
def get_reminders(
    current_user: User = Depends(get_current_user)
):
    """Returns all care reminders for authenticated user."""
    user_id = str(current_user.id)
    user_rems = [r for r in _reminders_db if r["user_id"] in (user_id, "system")]
    return user_rems


@router.post("", response_model=ReminderOut, status_code=status.HTTP_201_CREATED)
def create_reminder(
    body: ReminderCreate,
    current_user: User = Depends(get_current_user)
):
    """Creates a new care reminder."""
    new_rem = {
        "id": f"rem-{str(uuid.uuid4())[:8]}",
        "user_id": str(current_user.id),
        "title": body.title,
        "type": body.type,
        "time": body.time,
        "frequency": body.frequency,
        "is_enabled": body.is_enabled
    }
    _reminders_db.append(new_rem)
    return new_rem


@router.patch("/{reminder_id}", response_model=ReminderOut)
def update_reminder(
    reminder_id: str,
    body: ReminderUpdate,
    current_user: User = Depends(get_current_user)
):
    """Updates a care reminder."""
    user_id = str(current_user.id)
    for rem in _reminders_db:
        if rem["id"] == reminder_id and (rem["user_id"] == user_id or rem["user_id"] == "system"):
            if body.title is not None:
                rem["title"] = body.title
            if body.type is not None:
                rem["type"] = body.type
            if body.time is not None:
                rem["time"] = body.time
            if body.frequency is not None:
                rem["frequency"] = body.frequency
            if body.is_enabled is not None:
                rem["is_enabled"] = body.is_enabled
            return rem
    raise HTTPException(status_code=404, detail="Reminder not found")


@router.delete("/{reminder_id}", status_code=status.HTTP_200_OK)
def delete_reminder(
    reminder_id: str,
    current_user: User = Depends(get_current_user)
):
    """Deletes a care reminder."""
    global _reminders_db
    _reminders_db = [r for r in _reminders_db if not (r["id"] == reminder_id and r["user_id"] in (str(current_user.id), "system"))]
    return {"message": "Reminder deleted successfully"}
