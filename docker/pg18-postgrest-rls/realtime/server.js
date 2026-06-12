const http = require('http');
const crypto = require('crypto');
const { Client } = require('pg');
const WebSocket = require('ws');

const PORT = Number(process.env.REALTIME_PORT || 4000);
const DATABASE_URL = process.env.DATABASE_URL || 'postgres://realtime_bridge:local_pg18_realtime_bridge_only@pg18:5432/postgres';
const JWT_SECRET = process.env.PG18_DEV_JWT_SECRET || 'local_pg18_rls_jwt_secret_32_chars_minimum_only';
const CHANNEL = process.env.REALTIME_CHANNEL || 'app_events';

function b64urlDecode(input) {
  const pad = '='.repeat((4 - input.length % 4) % 4);
  return Buffer.from((input + pad).replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

function verifyJwt(token) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('invalid jwt format');
  const unsigned = `${parts[0]}.${parts[1]}`;
  const expected = crypto.createHmac('sha256', JWT_SECRET).update(unsigned).digest('base64url');
  if (!crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(parts[2]))) throw new Error('invalid jwt signature');
  const payload = JSON.parse(b64urlDecode(parts[1]).toString('utf8'));
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) throw new Error('jwt expired');
  if (payload.role !== 'authenticated') throw new Error('jwt role must be authenticated');
  if (!payload.app_user_id) throw new Error('jwt missing app_user_id');
  return payload;
}

const clients = new Map();

function send(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(payload));
}

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', clients: clients.size }));
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
    clients.set(ws, { app_user_id: claims.app_user_id, role: claims.role });
    send(ws, { type: 'ready', app_user_id: claims.app_user_id, transport: 'pg-listen-notify' });
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
    const pg = new Client({ connectionString: DATABASE_URL });
    try {
      await pg.connect();
      return pg;
    } catch (err) {
      lastErr = err;
      console.log(`waiting for postgres attempt=${attempt} error=${err.code || err.message}`);
      try { await pg.end(); } catch (_) {}
      await sleep(1000);
    }
  }
  throw lastErr;
}

async function main() {
  const pg = await connectWithRetry();
  await pg.query(`LISTEN ${CHANNEL}`);
  pg.on('notification', async (msg) => {
    let event;
    try { event = JSON.parse(msg.payload); } catch { return; }
    for (const [ws, claims] of clients.entries()) {
      if (event.app_user_id === claims.app_user_id) send(ws, { type: 'event', event });
    }
  });
  server.listen(PORT, '0.0.0.0', () => console.log(`PG18 realtime bridge listening on 0.0.0.0:${PORT}`));
}

main().catch((err) => {
  console.error('realtime bridge failed', err);
  process.exit(1);
});
