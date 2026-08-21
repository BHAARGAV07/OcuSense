import datetime
from typing import Dict, Any
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, HabitLog
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/eye-rubbing", tags=["Eye Rubbing"])


@router.post("/events", status_code=status.HTTP_201_CREATED)
def log_eye_rubbing_event(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Logs an eye rubbing event for authenticated user and returns updated event count for today.
    """
    patient_id = str(current_user.id)
    now = datetime.datetime.utcnow()
    
    new_log = HabitLog(
        patient_id=patient_id,
        habits=["eye_rubbing"],
        timestamp=now
    )
    db.add(new_log)
    db.commit()

    # Calculate count for today
    today_start = datetime.datetime(now.year, now.month, now.day)
    count = (
        db.query(HabitLog)
        .filter(
            HabitLog.patient_id == patient_id,
            HabitLog.timestamp >= today_start
        )
        .count()
    )

    return {
        "status": "success",
        "message": "Eye rubbing event logged successfully",
        "today_count": count,
        "timestamp": now.isoformat()
    }


@router.get("/events")
def get_eye_rubbing_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Retrieves today's eye rubbing count and total count.
    """
    patient_id = str(current_user.id)
    now = datetime.datetime.utcnow()
    today_start = datetime.datetime(now.year, now.month, now.day)

    today_count = (
        db.query(HabitLog)
        .filter(
            HabitLog.patient_id == patient_id,
            HabitLog.timestamp >= today_start
        )
        .count()
    )
    total_count = (
        db.query(HabitLog)
        .filter(HabitLog.patient_id == patient_id)
        .count()
    )

    return {
        "today_count": today_count,
        "total_count": total_count,
        "last_event": now.isoformat() if today_count > 0 else None
    }
