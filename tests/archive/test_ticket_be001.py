import pytest
from app.core import security
from datetime import timedelta

def test_tokens():
    print("🔐 Testing Token Logic (BE-001)...")
    
    # 1. Create Access Token
    access_token = security.create_access_token({"sub": "test@test.com"})
    payload = security.decode_access_token(access_token)
    assert payload["sub"] == "test@test.com"
    assert payload["type"] == "access"
    print("✅ Access Token valid")

    # 2. Create Refresh Token
    refresh_token = security.create_refresh_token({"sub": "test@test.com"})
    payload_refresh = security.decode_access_token(refresh_token)
    assert payload_refresh["sub"] == "test@test.com"
    assert payload_refresh["type"] == "refresh"
    print("✅ Refresh Token valid")

    # 3. Expiration Check
    short_token = security.create_access_token({"sub": "exp"}, expires_delta=timedelta(seconds=-1))
    payload_exp = security.decode_access_token(short_token)
    assert payload_exp == {}
    print("✅ Expiration check passed")

if __name__ == "__main__":
    test_tokens()
