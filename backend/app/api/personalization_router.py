"""
Personalization Onboarding and Profile Management Endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, PatientProfile
from app.schemas.personalization import PersonalizationProfileUpdate, PersonalizationProfileOut
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/personalization", tags=["Personalization"])


@router.get("", response_model=PersonalizationProfileOut)
def get_personalization_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves the complete personalization profile for the authenticated patient.
    """
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == str(current_user.id)).first()
    if not profile:
        profile = PatientProfile(
            user_id=str(current_user.id),
            display_name=current_user.email.split("@")[0],
            is_onboarded=False
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


@router.post("", response_model=PersonalizationProfileOut)
def save_personalization_onboarding(
    body: PersonalizationProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Saves initial personalization profile during onboarding and sets is_onboarded=True.
    """
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == str(current_user.id)).first()
    if not profile:
        profile = PatientProfile(user_id=str(current_user.id))
        db.add(profile)

    update_dict = body.model_dump(exclude_unset=True)
    for field, val in update_dict.items():
        if hasattr(profile, field):
            setattr(profile, field, val)

    # Mark user as having completed initial personalization onboarding
    profile.is_onboarded = True
    db.commit()
    db.refresh(profile)
    return profile


@router.patch("", response_model=PersonalizationProfileOut)
def update_personalization_settings(
    body: PersonalizationProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Allows patient to edit personalization settings later from Profile.
    """
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == str(current_user.id)).first()
    if not profile:
        profile = PatientProfile(user_id=str(current_user.id))
        db.add(profile)

    update_dict = body.model_dump(exclude_unset=True)
    for field, val in update_dict.items():
        if hasattr(profile, field):
            setattr(profile, field, val)

    db.commit()
    db.refresh(profile)
    return profile
