"""
Pydantic Schemas for Ocular Computer Vision and Image Quality Assessment.
"""
from typing import Optional
from pydantic import BaseModel, Field


class OcularAnalysisOut(BaseModel):
    success: bool
    is_acceptable: bool
    image_quality: float
    redness_score: Optional[float] = None
    inflammation_score: Optional[float] = None
    swelling_score: Optional[float] = None
    tear_feature: Optional[float] = None
    confidence: Optional[float] = 0.85
    feedback: str
    error: Optional[str] = None
    frames_analyzed: Optional[int] = None
