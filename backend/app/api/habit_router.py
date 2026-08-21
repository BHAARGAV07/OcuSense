import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, HabitLog
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/habits", tags=["Habits"])


class HabitLogCreate(BaseModel):
    habits: List[str] = Field(default_factory=list, description="List of habits e.g. outdoor_activity, eye_rubbing, food")
    notes: Optional[str] = None


class HabitLogOut(BaseModel):
    id: int
    patient_id: str
    habits: List[str]
    timestamp: datetime.datetime

    class Config:
        from_attributes = True


@router.post("", response_model=HabitLogOut, status_code=status.HTTP_201_CREATED)
def log_habits(
    body: HabitLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logs patient habits to database for authenticated user.
    """
    new_log = HabitLog(
        patient_id=str(current_user.id),
        habits=body.habits,
        timestamp=datetime.datetime.utcnow()
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log


@router.get("", response_model=List[HabitLogOut])
def get_habit_logs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves habit logs for authenticated user.
    """
    logs = (
        db.query(HabitLog)
        .filter(HabitLog.patient_id == str(current_user.id))
        .order_by(HabitLog.timestamp.desc())
        .all()
    )
    return logs
