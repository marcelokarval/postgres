#!/usr/bin/env python3
import base64
import hashlib
import hmac
import json
import os
import sys
import time


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


secret = os.environ.get('PG18_DEV_JWT_SECRET', 'local_pg18_rls_jwt_secret_32_chars_minimum_only').encode()
app_user_id = os.environ.get('PG18_DEV_APP_USER_ID', 'user_karval_demo')
role = os.environ.get('PG18_DEV_JWT_ROLE', 'authenticated')
now = int(time.time())
header = {'alg': 'HS256', 'typ': 'JWT'}
payload = {
    'role': role,
    'app_user_id': app_user_id,
    'iat': now,
    'exp': now + 3600,
}
unsigned = b64url(json.dumps(header, separators=(',', ':')).encode()) + '.' + b64url(json.dumps(payload, separators=(',', ':')).encode())
sig = hmac.new(secret, unsigned.encode(), hashlib.sha256).digest()
sys.stdout.write(unsigned + '.' + b64url(sig))
