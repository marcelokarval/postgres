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


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def make_jwt() -> str:
    now = int(time.time())
    header = {'alg': 'HS256', 'typ': 'JWT'}
    payload = {'role': 'authenticated', 'app_user_id': APP_USER_ID, 'iat': now, 'exp': now + 3600}
    unsigned = b64url(json.dumps(header, separators=(',', ':')).encode()) + '.' + b64url(json.dumps(payload, separators=(',', ':')).encode())
    sig = hmac.new(SECRET, unsigned.encode(), hashlib.sha256).digest()
    return unsigned + '.' + b64url(sig)


HTML = '''<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>PG18 RLS Web Proof</title>
  <style>
    body{font-family:Inter,system-ui,sans-serif;background:#09111f;color:#eef4ff;margin:0;padding:32px}
    .card{max-width:980px;margin:auto;background:#111d35;border:1px solid #315083;border-radius:18px;padding:28px}
    .badge{display:inline-block;background:#216e4e;color:#dcffe9;border-radius:999px;padding:6px 10px;font-weight:800}
    .grid{display:grid;grid-template-columns:190px 1fr;gap:10px}.k{color:#95b7ff}
    .v,pre{font-family:ui-monospace,monospace;background:#071124;border-radius:10px;padding:10px;white-space:pre-wrap}
    button{background:#5b8cff;color:#fff;border:0;border-radius:10px;padding:10px 14px;font-weight:800}
  </style>
</head>
<body>
<main class="card">
  <span class="badge">PG18 POSTGREST JWT/RLS PROOF</span>
  <h1>Database-centric RPC with JWT claims + RLS</h1>
  <p>Web client calls same-origin <code>/api/current-profile</code>, which proxies to PostgREST <code>/rpc/current_profile</code> with a local JWT.</p>
  <button id="reload">Chamar current_profile</button>
  <div class="grid">
    <div class="k">Status</div><div class="v" id="status">loading</div>
    <div class="k">User</div><div class="v" id="user">...</div>
    <div class="k">Plan</div><div class="v" id="plan">...</div>
    <div class="k">Role</div><div class="v" id="role">...</div>
    <div class="k">Postgres</div><div class="v" id="pg">...</div>
  </div>
  <h2>Payload</h2>
  <pre id="payload">{}</pre>
</main>
<script>
async function run(){
  const s=document.querySelector('#status');
  s.textContent='fetching';
  const res=await fetch('/api/current-profile',{method:'POST'});
  const data=await res.json();
  s.textContent=res.status+' '+(res.ok?'OK':'ERROR');
  document.querySelector('#user').textContent=data.app_user_id||'';
  document.querySelector('#plan').textContent=data.plan||'';
  document.querySelector('#role').textContent=data.role||'';
  document.querySelector('#pg').textContent=data.postgres_version||'';
  document.querySelector('#payload').textContent=JSON.stringify(data,null,2);
}
document.querySelector('#reload').onclick=run;
run();
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
        else:
            self.send_body(404, 'not found', 'text/plain')

    def do_POST(self):
        if self.path != '/api/current-profile':
            self.send_body(404, 'not found', 'text/plain')
            return
        req = urllib.request.Request(
            PGRST_URL + '/rpc/current_profile',
            data=b'{}',
            method='POST',
            headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + make_jwt()},
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                body = res.read()
                obj = json.loads(body)
                assert obj.get('app_user_id') == APP_USER_ID
                self.send_body(200, body, 'application/json; charset=utf-8')
        except Exception as exc:
            self.send_body(502, json.dumps({'error': str(exc)}), 'application/json')

    def log_message(self, format, *args):
        print('RLSWEB', self.address_string(), format % args, flush=True)


if __name__ == '__main__':
    print('Serving PG18 RLS web proof on 0.0.0.0:8080', flush=True)
    http.server.ThreadingHTTPServer(('0.0.0.0', 8080), Handler).serve_forever()
