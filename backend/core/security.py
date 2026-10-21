"""Password hashing and signed session tokens.

Deliberately dependency-free (stdlib only) so the mini-project backend stays
lightweight: PBKDF2-HMAC-SHA256 for passwords and an HMAC-signed token for
sessions. Swap in python-jose/argon2 later without changing the call sites.
"""

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from typing import Dict, Optional

from .config import settings

PBKDF2_ITERATIONS = 200_000
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 14  # 14 days


def _b64encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def _b64decode(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return f"pbkdf2_sha256${PBKDF2_ITERATIONS}${_b64encode(salt)}${_b64encode(digest)}"


def verify_password(password: str, stored: Optional[str]) -> bool:
    if not stored or "$" not in stored:
        return False
    try:
        algorithm, iterations, salt_b64, digest_b64 = stored.split("$", 3)
        if algorithm != "pbkdf2_sha256":
            return False
        salt = _b64decode(salt_b64)
        expected = _b64decode(digest_b64)
        actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, int(iterations))
        return hmac.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def _sign(payload_b64: str) -> str:
    key = settings.AUTH_SECRET_KEY.encode("utf-8")
    return _b64encode(hmac.new(key, payload_b64.encode("ascii"), hashlib.sha256).digest())


def create_token(payload: Dict[str, object], ttl_seconds: int = TOKEN_TTL_SECONDS) -> str:
    body = dict(payload)
    body["exp"] = int(time.time()) + ttl_seconds
    payload_b64 = _b64encode(json.dumps(body, separators=(",", ":")).encode("utf-8"))
    return f"{payload_b64}.{_sign(payload_b64)}"


def decode_token(token: str) -> Optional[Dict[str, object]]:
    """Returns the payload if the signature is valid and unexpired, else None."""
    if not token or "." not in token:
        return None
    payload_b64, signature = token.rsplit(".", 1)
    if not hmac.compare_digest(signature, _sign(payload_b64)):
        return None
    try:
        payload = json.loads(_b64decode(payload_b64))
    except (ValueError, TypeError):
        return None
    if not isinstance(payload, dict):
        return None
    exp = payload.get("exp")
    if not isinstance(exp, (int, float)) or exp < time.time():
        return None
    return payload
