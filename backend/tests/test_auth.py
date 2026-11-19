import pytest
from app.auth import hash_password, verify_password, create_access_token
from jose import jwt
from app.config import settings

def test_password_hashing():
    pw = "SecretPass123"
    hashed = hash_password(pw)
    assert hashed != pw
    assert verify_password(pw, hashed) is True
    assert verify_password("WrongPass", hashed) is False

def test_jwt_token_generation():
    token = create_access_token({"sub": "test@university.edu", "user_id": 42})
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == "test@university.edu"
    assert payload["user_id"] == 42
