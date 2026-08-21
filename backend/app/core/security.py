import datetime
from typing import Dict, Any
import jwt
import bcrypt
from app.config import settings


def hash_password(plain: str) -> str:
    """Hash a plain text password securely using bcrypt."""
    pwd_bytes = plain.encode('utf-8')
    # Truncate to 72 bytes maximum as required by bcrypt specification
    if len(pwd_bytes) > 72:
        pwd_bytes = pwd_bytes[:72]
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    return hashed.decode('utf-8')


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a plain text password against its bcrypt hash."""
    try:
        pwd_bytes = plain.encode('utf-8')
        if len(pwd_bytes) > 72:
            pwd_bytes = pwd_bytes[:72]
        hashed_bytes = hashed.encode('utf-8')
        return bcrypt.checkpw(pwd_bytes, hashed_bytes)
    except Exception:
        return False


def create_access_token(user_id: str) -> str:
    """Create a signed JWT access token with user_id embedded in sub claim."""
    expires_delta = datetime.timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    expire = datetime.datetime.utcnow() + expires_delta
    payload = {
        "sub": str(user_id),
        "type": "access",
        "exp": expire,
        "iat": datetime.datetime.utcnow()
    }
    encoded_jwt = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def create_refresh_token(user_id: str) -> str:
    """Create a signed JWT refresh token with user_id embedded in sub claim."""
    expires_delta = datetime.timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    expire = datetime.datetime.utcnow() + expires_delta
    payload = {
        "sub": str(user_id),
        "type": "refresh",
        "exp": expire,
        "iat": datetime.datetime.utcnow()
    }
    encoded_jwt = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> Dict[str, Any]:
    """
    Decode and verify a JWT token.
    Raises ValueError on invalid signature, expiration, or malformed claims.
    """
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM]
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise ValueError("Token has expired")
    except jwt.InvalidTokenError as e:
        raise ValueError(f"Invalid token: {str(e)}")
