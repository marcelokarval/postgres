const http = require('http');
const crypto = require('crypto');
const { Client } = require('pg');
const WebSocket = require('ws');

const PORT = Number(process.env.REALTIME_PORT || 4000);
const DATABASE_URL = process.env.DATABASE_URL || 'postgres://realtime_bridge:***@pg18:5432/postgres';
const JWT_SECRET = process.env.PG18_DEV_JWT_SECRET || 'local_pg18_rls_jwt_secret_32_chars_minimum_only';
const CHANNEL = process.env.REALTIME_CHANNEL || 'app_events';
const DEFAULT_TOPIC = process.env.REALTIME_DEFAULT_TOPIC || 'proof.realtime';
const REPLAY_LIMIT = Number(process.env.REALTIME_REPLAY_LIMIT || 100);

function b64urlDecode(input) {
  const pad = '='.repeat((4 - input.length % 4) % 4);
  return Buffer.from((input + pad).replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

function timingSafeEqualString(a, b) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && crypto.timingSafeEqual(left, right);
}

function verifyJwt(token) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('invalid jwt format');
  const unsigned = `${parts[0]}.${parts[1]}`;
  const expected = crypto.createHmac('sha256', JWT_SECRET).update(unsigned).digest('base64url');
  if (!timingSafeEqualString(expected, parts[2])) throw new Error('invalid jwt signature');
  const payload = JSON.parse(b64urlDecode(parts[1]).toString('utf8'));
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) throw new Error('jwt expired');
  if (payload.role !== 'authenticated') throw new Error('jwt role must be authenticated');
  if (!payload.app_user_id) throw new Error('jwt missing app_user_id');
  return payload;
}

const clients = new Map();
let pg;

function send(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(payload));
}

function normalizeSubscribe(input, appUserId) {
  const lastEventId = Number(input.last_event_id || input.lastEventId || 0);
  const limit = Number(input.limit || REPLAY_LIMIT);
  return {
    scope_type: input.scope_type || input.scopeType || 'user',
    scope_id: input.scope_id || input.scopeId || appUserId,
    topic: Object.prototype.hasOwnProperty.call(input, 'topic') ? input.topic : DEFAULT_TOPIC,
    last_event_id: Number.isFinite(lastEventId) && lastEventId >= 0 ? Math.floor(lastEventId) : 0,
    limit: Number.isFinite(limit) ? Math.min(Math.max(Math.floor(limit), 1), 500) : REPLAY_LIMIT,
  };
}

function subscriptionMatches(event, sub) {
  return event.scope_type === sub.scope_type
    && event.scope_id === sub.scope_id
    && (sub.topic === null || sub.topic === undefined || event.topic === sub.topic);
}

async function dbCanSubscribe(appUserId, sub) {
  const res = await pg.query(
    'select private.bridge_can_subscribe($1, $2, $3, $4) as allowed',
    [appUserId, sub.scope_type, sub.scope_id, sub.topic],
  );
  return res.rows[0] && res.rows[0].allowed === true;
}

async function dbReplay(appUserId, sub) {
  const res = await pg.query(
    'select private.bridge_replay_events($1, $2, $3, $4, $5, $6) as replay',
    [appUserId, sub.scope_type, sub.scope_id, sub.topic, sub.last_event_id, sub.limit],
  );
  return res.rows[0].replay;
}

async function dbAck(appUserId, eventId) {
  const res = await pg.query('select private.bridge_ack_event($1, $2) as ack', [appUserId, eventId]);
  return res.rows[0].ack;
}

async function handleSubscribe(ws, state, msg) {
  const sub = normalizeSubscribe(msg, state.app_user_id);
  const allowed = await dbCanSubscribe(state.app_user_id, sub);
  if (!allowed) {
    send(ws, {
      type: 'error',
      code: 'subscription_denied',
      scope_type: sub.scope_type,
      scope_id: sub.scope_id,
      topic: sub.topic,
    });
    ws.close(1008, 'subscription denied');
    return;
  }

  state.subscriptions = [sub];
  const replay = await dbReplay(state.app_user_id, sub);
  send(ws, {
    type: 'subscribed',
    scope_type: sub.scope_type,
    scope_id: sub.scope_id,
    topic: sub.topic,
    last_event_id: sub.last_event_id,
  });
  send(ws, {
    type: 'replay',
    scope_type: replay.scope_type,
    scope_id: replay.scope_id,
    topic: replay.topic,
    last_event_id: replay.last_event_id,
    events: replay.events || [],
  });
}

async function handleAck(ws, state, msg) {
  const eventId = Number(msg.event_id || msg.eventId);
  if (!Number.isFinite(eventId) || eventId <= 0) throw new Error('ack requires positive event_id');
  const ack = await dbAck(state.app_user_id, Math.floor(eventId));
  send(ws, { type: 'ack', ...ack });
}

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', clients: clients.size, fanout: 'postgres-listen-notify', durable_source: 'private.event_outbox' }));
    return;
  }
  res.writeHead(404, { 'content-type': 'text/plain' });
  res.end('not found');
});

const wss = new WebSocket.Server({ server, path: '/ws' });

wss.on('connection', (ws, req) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    const token = url.searchParams.get('token') || (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
    if (!token) throw new Error('missing token');
    const claims = verifyJwt(token);
    const state = { app_user_id: claims.app_user_id, role: claims.role, subscriptions: [] };
    clients.set(ws, state);
    send(ws, {
      type: 'ready',
      app_user_id: claims.app_user_id,
      transport: 'pg-listen-notify',
      durable_source: 'private.event_outbox',
      fanout_ready: ['redis', 'nats'],
    });

    ws.on('message', (raw) => {
      (async () => {
        let msg;
        try {
          msg = JSON.parse(raw.toString());
        } catch (_) {
          throw new Error('message must be json');
        }

        if (msg.type === 'subscribe') {
          await handleSubscribe(ws, state, msg);
        } else if (msg.type === 'ack') {
          await handleAck(ws, state, msg);
        } else if (msg.type === 'ping') {
          send(ws, { type: 'pong' });
        } else {
          throw new Error(`unsupported message type: ${msg.type || 'missing'}`);
        }
      })().catch((err) => {
        send(ws, { type: 'error', error: err.message });
      });
    });

    ws.on('close', () => clients.delete(ws));
  } catch (err) {
    send(ws, { type: 'error', error: err.message });
    ws.close(1008, err.message.slice(0, 120));
  }
});

function sleep(ms) { return new Promise((resolve) => setTimeout(resolve, ms)); }

async function connectWithRetry() {
  let lastErr;
  for (let attempt = 1; attempt <= 60; attempt += 1) {
    const candidate = new Client({ connectionString: DATABASE_URL });
    try {
      await candidate.connect();
      return candidate;
    } catch (err) {
      lastErr = err;
      console.log(`waiting for postgres attempt=${attempt} error=${err.code || err.message}`);
      try { await candidate.end(); } catch (_) {}
      await sleep(1000);
    }
  }
  throw lastErr;
}

async function main() {
  pg = await connectWithRetry();
  await pg.query(`LISTEN ${CHANNEL}`);
  pg.on('notification', async (msg) => {
    let event;
    try { event = JSON.parse(msg.payload); } catch { return; }
    for (const [ws, state] of clients.entries()) {
      if (!state.subscriptions.some((sub) => subscriptionMatches(event, sub))) continue;
      send(ws, { type: 'event', event });
    }
  });
  server.listen(PORT, '0.0.0.0', () => console.log(`PG18 realtime bridge listening on 0.0.0.0:${PORT}`));
}

main().catch((err) => {
  console.error('realtime bridge failed', err);
  process.exit(1);
});
