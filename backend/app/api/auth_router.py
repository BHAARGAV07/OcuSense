from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, PatientProfile
from app.schemas.auth import UserRegister, UserLogin, RefreshTokenRequest, TokenResponse, RegisterResponse
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register_user(body: UserRegister, db: Session = Depends(get_db)):
    """
    Registers a new user account and creates an associated patient profile.
    Rejects duplicate emails with 409 Conflict.
    """
    existing_user = db.query(User).filter(User.email == body.email.lower()).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )

    new_user = User(
        email=body.email.lower(),
        password_hash=hash_password(body.password)
    )
    db.add(new_user)
    db.flush()  # populate new_user.id

    # Create associated PatientProfile
    new_profile = PatientProfile(
        user_id=new_user.id,
        display_name=body.email.split("@")[0]
    )
    db.add(new_profile)
    db.commit()
    db.refresh(new_user)

    return RegisterResponse(user_id=str(new_user.id), message="Account created")


@router.post("/login", response_model=TokenResponse)
def login_user(body: UserLogin, db: Session = Depends(get_db)):
    """
    Authenticates user credentials and returns JWT access & refresh tokens.
    Returns generic 401 Unauthorized on invalid email or password.
    """
    user = db.query(User).filter(User.email == body.email.lower()).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(user_id=str(user.id))
    refresh_token = create_refresh_token(user_id=str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh_access_token(body: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Verifies refresh token and issues a new access token.
    """
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        user_id = payload.get("sub")
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
        
        new_access_token = create_access_token(user_id=str(user.id))
        return TokenResponse(
            access_token=new_access_token,
            refresh_token=body.refresh_token,
            token_type="bearer"
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))


@router.post("/logout")
def logout():
    """
    Client-side token disposal confirmation.
    Note: Stateful token revoking / blacklisting would require a Redis/DB blacklist table.
    """
    return {"message": "Logged out successfully"}
