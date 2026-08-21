from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, PatientProfile
from app.schemas.patient import PatientProfileCreate, PatientProfileUpdate, PatientProfileOut
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/patients", tags=["Patients"])


@router.post("", response_model=PatientProfileOut)
def create_or_update_patient_profile(
    body: PatientProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Creates or updates the PatientProfile for the authenticated user.
    Never accepts user_id from request body — always derives from JWT.
    """
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == current_user.id).first()
    if not profile:
        profile = PatientProfile(user_id=current_user.id)
        db.add(profile)

    if body.display_name is not None:
        profile.display_name = body.display_name
    if body.location_name is not None:
        profile.location_name = body.location_name
    if body.location_lat is not None:
        profile.location_lat = body.location_lat
    if body.location_lon is not None:
        profile.location_lon = body.location_lon

    db.commit()
    db.refresh(profile)
    return profile


@router.get("/me", response_model=PatientProfileOut)
def get_my_patient_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns the PatientProfile belonging strictly to the authenticated user.
    """
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == current_user.id).first()
    if not profile:
        profile = PatientProfile(
            user_id=current_user.id,
            display_name=current_user.email.split("@")[0]
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


@router.patch("/me", response_model=PatientProfileOut)
def update_my_patient_profile(
    body: PatientProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Partially updates fields on the authenticated user's own profile.
    """
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == current_user.id).first()
    if not profile:
        profile = PatientProfile(user_id=current_user.id)
        db.add(profile)

    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(profile)
    return profile
