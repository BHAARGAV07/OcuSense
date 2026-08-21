"""
Ocular Video and Image Analysis Endpoints for OcuSense.
"""
import uuid
import datetime
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, EyeAnalysisRecord
from app.core.deps import get_current_user
from app.schemas.ocular import OcularAnalysisOut
from app.services.ocular_analysis_service import OcularAnalysisService

router = APIRouter(prefix="/api/ocular", tags=["Ocular CV"])


@router.post("/analyze-video", response_model=OcularAnalysisOut)
async def analyze_eye_video(
    video: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Processes patient-captured eye video (10-20 seconds).
    Validates frame quality (sharpness, lighting, contrast), extracts objective redness,
    and stores analysis telemetry without saving sensitive raw video.
    """
    # Security: File type validation
    allowed_types = ["video/mp4", "video/quicktime", "video/x-matroska", "application/octet-stream"]
    if video.content_type not in allowed_types and not (video.filename and (video.filename.endswith(".mp4") or video.filename.endswith(".mov"))):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported video format. Please upload MP4 or MOV video."
        )

    # Read video content safely in memory
    content = await video.read()
    if len(content) > 50 * 1024 * 1024:  # 50 MB limit
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Video size exceeds 50 MB limit."
        )

    result = OcularAnalysisService.analyze_video_bytes(content, filename=video.filename or "video.mp4")

    # If acceptable, store analysis record in DB
    if result.get("is_acceptable", False):
        try:
            record = EyeAnalysisRecord(
                id=str(uuid.uuid4()),
                user_id=str(current_user.id),
                image_quality=result.get("image_quality", 0.9),
                redness_score=result.get("redness_score", 0.3),
                inflammation_score=result.get("inflammation_score"),
                swelling_score=result.get("swelling_score"),
                tear_feature=result.get("tear_feature"),
                confidence=result.get("confidence", 0.85),
                feedback=result.get("feedback", "High quality capture."),
                created_at=datetime.datetime.now(datetime.timezone.utc)
            )
            db.add(record)
            db.commit()
        except Exception:
            db.rollback()

    return result


@router.post("/analyze-image", response_model=OcularAnalysisOut)
async def analyze_eye_image(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Processes a single still eye photo.
    """
    content = await image.read()
    if len(content) > 15 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image size exceeds 15 MB limit."
        )

    result = OcularAnalysisService.analyze_image_bytes(content)

    if result.get("is_acceptable", False):
        try:
            record = EyeAnalysisRecord(
                id=str(uuid.uuid4()),
                user_id=str(current_user.id),
                image_quality=result.get("image_quality", 0.9),
                redness_score=result.get("redness_score", 0.3),
                inflammation_score=result.get("inflammation_score"),
                confidence=result.get("confidence", 0.85),
                feedback=result.get("feedback", "Image analyzed successfully."),
                created_at=datetime.datetime.now(datetime.timezone.utc)
            )
            db.add(record)
            db.commit()
        except Exception:
            db.rollback()

    return result
