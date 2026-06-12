const crypto = require('crypto');
const WebSocket = require('ws');

const SECRET = process.env.PG18_DEV_JWT_SECRET || 'local_pg18_rls_jwt_secret_32_chars_minimum_only';
const APP_USER_ID = process.env.PG18_DEV_APP_USER_ID || 'user_karval_demo';
const WS_URL = process.env.WS_URL || 'ws://127.0.0.1:18084/ws';

function makeJwt(appUserId) {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ role: 'authenticated', app_user_id: appUserId, iat: now, exp: now + 3600 })).toString('base64url');
  const unsigned = `${header}.${payload}`;
  const sig = crypto.createHmac('sha256', SECRET).update(unsigned).digest('base64url');
  return `${unsigned}.${sig}`;
}

const token = makeJwt(APP_USER_ID);
const ws = new WebSocket(`${WS_URL}?token=${token}`);
const seen = [];
const timeout = setTimeout(() => {
  console.error('timeout waiting realtime event', JSON.stringify(seen));
  process.exit(2);
}, 15000);

ws.on('message', (raw) => {
  const msg = JSON.parse(raw.toString());
  seen.push(msg.type);
  console.log(JSON.stringify(msg));
  if (msg.type === 'event' && msg.event && msg.event.topic === 'proof.realtime') {
    clearTimeout(timeout);
    ws.close();
    process.exit(0);
  }
});
ws.on('error', (err) => { console.error(err); process.exit(1); });
