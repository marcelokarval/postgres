const crypto = require('crypto');
const WebSocket = require('ws');

const SECRET = process.env.PG18_DEV_JWT_SECRET || 'local_pg18_rls_jwt_secret_32_chars_minimum_only';
const APP_USER_ID = process.env.PG18_DEV_APP_USER_ID || 'user_karval_demo';
const WS_URL = process.env.WS_URL || 'ws://127.0.0.1:18084/ws';
const LAST_EVENT_ID = Number(process.env.LAST_EVENT_ID || 0);
const TOPIC = process.env.REALTIME_TOPIC || 'proof.realtime';
const DENIED_SCOPE_ID = process.env.DENIED_SCOPE_ID || '';
const INVALID_TOKEN = process.env.INVALID_TOKEN === '1';

function makeJwt(appUserId, secret = SECRET) {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ role: 'authenticated', app_user_id: appUserId, iat: now, exp: now + 3600 })).toString('base64url');
  const unsigned = `${header}.${payload}`;
  const sig = crypto.createHmac('sha256', secret).update(unsigned).digest('base64url');
  return `${unsigned}.${sig}`;
}

function subscribe(ws, scopeId = APP_USER_ID) {
  ws.send(JSON.stringify({
    type: 'subscribe',
    scope_type: 'user',
    scope_id: scopeId,
    topic: TOPIC,
    last_event_id: LAST_EVENT_ID,
  }));
}

const token = INVALID_TOKEN ? `${makeJwt(APP_USER_ID)}x` : makeJwt(APP_USER_ID);
const ws = new WebSocket(`${WS_URL}?token=${encodeURIComponent(token)}`);
const seen = [];
let acked = false;

const timeout = setTimeout(() => {
  console.error('timeout waiting realtime event/replay', JSON.stringify(seen));
  process.exit(2);
}, 15000);

ws.on('open', () => {
  if (DENIED_SCOPE_ID) subscribe(ws, DENIED_SCOPE_ID);
});

ws.on('message', (raw) => {
  const msg = JSON.parse(raw.toString());
  seen.push(msg.type);
  console.log(JSON.stringify(msg));

  if (msg.type === 'ready' && !DENIED_SCOPE_ID) {
    subscribe(ws);
  }

  if (msg.type === 'replay' && msg.events && msg.events.length > 0 && !acked) {
    const event = msg.events[msg.events.length - 1];
    ws.send(JSON.stringify({ type: 'ack', event_id: event.id }));
  }

  if (msg.type === 'event' && msg.event && msg.event.topic === TOPIC && !acked) {
    ws.send(JSON.stringify({ type: 'ack', event_id: msg.event.id }));
  }

  if (msg.type === 'ack') {
    acked = true;
    clearTimeout(timeout);
    ws.close();
    process.exit(0);
  }

  if ((DENIED_SCOPE_ID || INVALID_TOKEN) && msg.type === 'error') {
    clearTimeout(timeout);
    ws.close();
    process.exit(0);
  }
});

ws.on('close', (code) => {
  if ((DENIED_SCOPE_ID || INVALID_TOKEN) && code === 1008) {
    clearTimeout(timeout);
    process.exit(0);
  }
});
ws.on('error', (err) => { console.error(err); process.exit(1); });
