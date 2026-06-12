#!/usr/bin/env python3
import base64
import hashlib
import hmac
import http.server
import json
import os
import time
import urllib.request

PGRST_URL = os.environ.get('PGRST_URL', 'http://127.0.0.1:13001').rstrip('/')
SECRET = os.environ.get('PG18_DEV_JWT_SECRET', 'local_pg18_rls_jwt_secret_32_chars_minimum_only').encode()
APP_USER_ID = os.environ.get('PG18_DEV_APP_USER_ID', 'user_karval_demo')
REALTIME_PUBLIC_URL = os.environ.get('REALTIME_PUBLIC_URL', 'ws://127.0.0.1:18084/ws')
DEFAULT_TOPIC = os.environ.get('REALTIME_DEFAULT_TOPIC', 'proof.realtime')


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def make_jwt(app_user_id: str = APP_USER_ID) -> str:
    now = int(time.time())
    header = {'alg': 'HS256', 'typ': 'JWT'}
    payload = {'role': 'authenticated', 'app_user_id': app_user_id, 'iat': now, 'exp': now + 3600}
    unsigned = b64url(json.dumps(header, separators=(',', ':')).encode()) + '.' + b64url(json.dumps(payload, separators=(',', ':')).encode())
    sig = hmac.new(SECRET, unsigned.encode(), hashlib.sha256).digest()
    return unsigned + '.' + b64url(sig)


def call_postgrest_rpc(name: str, payload: bytes = b'{}') -> bytes:
    req = urllib.request.Request(
        PGRST_URL + '/rpc/' + name,
        data=payload,
        method='POST',
        headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + make_jwt()},
    )
    with urllib.request.urlopen(req, timeout=10) as res:
        return res.read()


HTML = f'''<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>PG18 RLS + Realtime v2 Web Proof</title>
  <style>
    body{{font-family:Inter,system-ui,sans-serif;background:#09111f;color:#eef4ff;margin:0;padding:32px}}
    .card{{max-width:1120px;margin:auto;background:#111d35;border:1px solid #315083;border-radius:18px;padding:28px}}
    .badge{{display:inline-block;background:#216e4e;color:#dcffe9;border-radius:999px;padding:6px 10px;font-weight:800}}
    .grid{{display:grid;grid-template-columns:230px 1fr;gap:10px}}
    .k{{color:#95b7ff}}
    .v,pre,input{{font-family:ui-monospace,monospace;background:#071124;border-radius:10px;padding:10px;white-space:pre-wrap;color:#eef4ff;border:1px solid #263d66}}
    button{{background:#5b8cff;color:#fff;border:0;border-radius:10px;padding:10px 14px;font-weight:800;margin:4px 8px 4px 0}}
    input{{width:110px}}
  </style>
</head>
<body>
<main class="card">
  <span class="badge">PG18 POSTGREST JWT/RLS + REALTIME V2 PROOF</span>
  <h1>Database-centric RPC with JWT claims, RLS, replay/cursor, scopes/topics and ACK</h1>
  <p>Web client calls same-origin APIs. The WebSocket bridge validates JWT, asks PostgreSQL whether the subscription is allowed, replays from <code>last_event_id</code>, and records ACKs durably.</p>
  <button id="reload">Chamar current_profile</button>
  <button id="subscribe">Subscribe/replay</button>
  <button id="publish">Publicar evento realtime</button>
  <button id="ack">ACK último evento</button>
  <button id="denied">Provar subscription denied</button>
  <button id="invalid">Provar token inválido</button>
  <label>last_event_id <input id="lastid" value="0"></label>
  <div class="grid">
    <div class="k">HTTP Status</div><div class="v" id="status">loading</div>
    <div class="k">Realtime Status</div><div class="v" id="rtstatus">connecting</div>
    <div class="k">Scope</div><div class="v" id="scope">user/{APP_USER_ID} topic={DEFAULT_TOPIC}</div>
    <div class="k">Last event id</div><div class="v" id="lastevent">none</div>
    <div class="k">Last ACK</div><div class="v" id="lastack">none</div>
    <div class="k">User</div><div class="v" id="user">...</div>
    <div class="k">Plan</div><div class="v" id="plan">...</div>
    <div class="k">Role</div><div class="v" id="role">...</div>
    <div class="k">Postgres</div><div class="v" id="pg">...</div>
  </div>
  <h2>Profile / publish payload</h2>
  <pre id="payload">{{}}</pre>
  <h2>Realtime v2 messages</h2>
  <pre id="rtpayload">[]</pre>
</main>
<script>
const realtimeUrl = {json.dumps(REALTIME_PUBLIC_URL)};
const appUserId = {json.dumps(APP_USER_ID)};
const topic = {json.dumps(DEFAULT_TOPIC)};
let realtimeMessages = [];
let ws;
let lastEventId = Number(window.localStorage.getItem('pg18:last_event_id') || '0');
let lastAckableEventId = 0;
document.querySelector('#lastid').value = String(lastEventId);
function addRealtime(msg){{
  realtimeMessages.push(msg);
  document.querySelector('#rtpayload').textContent=JSON.stringify(realtimeMessages,null,2);
  if(msg.type==='ready') document.querySelector('#rtstatus').textContent='ready';
  if(msg.type==='subscribed') document.querySelector('#rtstatus').textContent='subscribed '+msg.scope_type+'/'+msg.scope_id+' topic='+msg.topic;
  if(msg.type==='replay') document.querySelector('#rtstatus').textContent='replay events: '+msg.events.length;
  if(msg.type==='event'){{
    document.querySelector('#rtstatus').textContent='event received: '+msg.event.topic;
    rememberEvent(msg.event.id);
  }}
  if(msg.type==='ack'){{
    document.querySelector('#lastack').textContent='event '+msg.event_id+' @ '+msg.acked_at;
  }}
  if(msg.type==='error') document.querySelector('#rtstatus').textContent='error '+(msg.code||msg.error||'unknown');
}}
function rememberEvent(id){{
  lastAckableEventId = Number(id);
  lastEventId = Number(id);
  window.localStorage.setItem('pg18:last_event_id', String(lastEventId));
  document.querySelector('#lastid').value = String(lastEventId);
  document.querySelector('#lastevent').textContent = String(lastEventId);
}}
async function token(){{
  const res=await fetch('/api/realtime-token');
  const data=await res.json();
  return data.token;
}}
function sendSubscribe(){{
  if(!ws || ws.readyState!==WebSocket.OPEN) return;
  const requestedLastId = Number(document.querySelector('#lastid').value || '0');
  ws.send(JSON.stringify({{type:'subscribe',scope_type:'user',scope_id:appUserId,topic,last_event_id:requestedLastId}}));
}}
async function connectRealtime(){{
  const t=await token();
  ws=new WebSocket(realtimeUrl+'?token='+encodeURIComponent(t));
  ws.onopen=()=>{{document.querySelector('#rtstatus').textContent='open'; sendSubscribe();}};
  ws.onmessage=(ev)=>{{
    const msg=JSON.parse(ev.data);
    addRealtime(msg);
    if(msg.type==='replay' && msg.events.length) rememberEvent(msg.events[msg.events.length-1].id);
  }};
  ws.onerror=()=>document.querySelector('#rtstatus').textContent='error';
  ws.onclose=(ev)=>document.querySelector('#rtstatus').textContent='closed '+ev.code;
}}
async function run(){{
  const s=document.querySelector('#status');
  s.textContent='fetching';
  const res=await fetch('/api/current-profile',{{method:'POST'}});
  const data=await res.json();
  s.textContent=res.status+' '+(res.ok?'OK':'ERROR');
  document.querySelector('#user').textContent=data.app_user_id||'';
  document.querySelector('#plan').textContent=data.plan||'';
  document.querySelector('#role').textContent=data.role||'';
  document.querySelector('#pg').textContent=data.postgres_version||'';
  document.querySelector('#payload').textContent=JSON.stringify(data,null,2);
}}
async function publish(){{
  const res=await fetch('/api/publish-realtime',{{method:'POST'}});
  const data=await res.json();
  document.querySelector('#status').textContent='publish '+res.status+' '+(res.ok?'OK':'ERROR');
  document.querySelector('#payload').textContent=JSON.stringify(data,null,2);
  if(data.id) rememberEvent(data.id);
}}
function ackLast(){{
  const id = lastAckableEventId || Number(document.querySelector('#lastid').value || '0');
  if(!ws || ws.readyState!==WebSocket.OPEN || !id){{
    document.querySelector('#lastack').textContent='no open websocket or event id';
    return;
  }}
  ws.send(JSON.stringify({{type:'ack',event_id:id}}));
}}
async function proveDenied(){{
  const t=await token();
  const deniedWs=new WebSocket(realtimeUrl+'?token='+encodeURIComponent(t));
  deniedWs.onopen=()=>deniedWs.send(JSON.stringify({{type:'subscribe',scope_type:'user',scope_id:'user_other_demo',topic,last_event_id:0}}));
  deniedWs.onmessage=(ev)=>addRealtime(Object.assign({{proof:'denied-subscription'}}, JSON.parse(ev.data)));
  deniedWs.onclose=(ev)=>addRealtime({{type:'closed',proof:'denied-subscription',code:ev.code,reason:ev.reason}});
}}
async function proveInvalidToken(){{
  const res=await fetch('/api/realtime-invalid-token');
  const data=await res.json();
  const badWs=new WebSocket(realtimeUrl+'?token='+encodeURIComponent(data.token));
  badWs.onmessage=(ev)=>addRealtime(Object.assign({{proof:'invalid-token'}}, JSON.parse(ev.data)));
  badWs.onclose=(ev)=>addRealtime({{type:'closed',proof:'invalid-token',code:ev.code,reason:ev.reason}});
}}
document.querySelector('#reload').onclick=run;
document.querySelector('#subscribe').onclick=sendSubscribe;
document.querySelector('#publish').onclick=publish;
document.querySelector('#ack').onclick=ackLast;
document.querySelector('#denied').onclick=proveDenied;
document.querySelector('#invalid').onclick=proveInvalidToken;
connectRealtime().then(run);
</script>
</body>
</html>'''


class Handler(http.server.BaseHTTPRequestHandler):
    def send_body(self, code, body, ctype):
        data = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path in ('/', '/docs/pg18-postgrest-rls-web.html'):
            self.send_body(200, HTML, 'text/html; charset=utf-8')
        elif self.path == '/healthz':
            self.send_body(200, 'ok', 'text/plain')
        elif self.path == '/api/realtime-token':
            self.send_body(200, json.dumps({'token': make_jwt(), 'app_user_id': APP_USER_ID}), 'application/json; charset=utf-8')
        elif self.path == '/api/realtime-invalid-token':
            self.send_body(200, json.dumps({'token': make_jwt() + 'x', 'app_user_id': APP_USER_ID}), 'application/json; charset=utf-8')
        else:
            self.send_body(404, 'not found', 'text/plain')

    def do_POST(self):
        rpc_by_path = {
            '/api/current-profile': 'current_profile',
            '/api/publish-realtime': 'publish_realtime_proof',
        }
        rpc = rpc_by_path.get(self.path)
        if not rpc:
            self.send_body(404, 'not found', 'text/plain')
            return
        try:
            body = call_postgrest_rpc(rpc)
            obj = json.loads(body)
            assert obj.get('app_user_id') == APP_USER_ID
            self.send_body(200, body, 'application/json; charset=utf-8')
        except Exception as exc:
            self.send_body(502, json.dumps({'error': str(exc)}), 'application/json')

    def log_message(self, format, *args):
        print('RLSWEB', self.address_string(), format % args, flush=True)


if __name__ == '__main__':
    print('Serving PG18 RLS + realtime v2 web proof on 0.0.0.0:8080', flush=True)
    http.server.ThreadingHTTPServer(('0.0.0.0', 8080), Handler).serve_forever()
