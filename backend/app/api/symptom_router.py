import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, SymptomLog
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/symptoms", tags=["Symptoms"])


class SymptomLogCreate(BaseModel):
    symptoms: List[str] = Field(default_factory=list, description="List of symptoms e.g. itching, redness, watering, irritation")
    severity: str = Field("MODERATE", description="LOW, MODERATE, HIGH")
    severity_score: int = Field(5, ge=1, le=10, description="Severity on 1-10 scale")
    recent_symptoms_increased: bool = False
    notes: Optional[str] = None


class SymptomLogOut(BaseModel):
    id: int
    patient_id: str
    symptoms: List[str]
    severity: str
    severity_score: int
    recent_symptoms_increased: bool
    timestamp: datetime.datetime

    class Config:
        from_attributes = True


@router.post("", response_model=SymptomLogOut, status_code=status.HTTP_201_CREATED)
def log_symptoms(
    body: SymptomLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logs patient symptoms to database for authenticated user.
    """
    new_log = SymptomLog(
        patient_id=str(current_user.id),
        symptoms=body.symptoms,
        severity=body.severity.upper(),
        severity_score=body.severity_score,
        recent_symptoms_increased=body.recent_symptoms_increased,
        timestamp=datetime.datetime.utcnow()
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log


@router.get("", response_model=List[SymptomLogOut])
def get_symptom_logs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves historical symptom logs for authenticated user.
    """
    logs = (
        db.query(SymptomLog)
        .filter(SymptomLog.patient_id == str(current_user.id))
        .order_by(SymptomLog.timestamp.desc())
        .all()
    )
    return logs
