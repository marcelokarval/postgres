#!/usr/bin/env python3
import http.server
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
HTML = ROOT / "docs" / "pg18-postgrest-web-proof.html"
POSTGREST_URL = "http://127.0.0.1:13000/rpc/hello"

class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, code, body, content_type):
        data = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path in ("/", "/docs/pg18-postgrest-web-proof.html"):
            self._send(200, HTML.read_bytes(), "text/html; charset=utf-8")
        elif self.path == "/healthz":
            self._send(200, b"ok", "text/plain")
        else:
            self._send(404, b"not found", "text/plain")

    def do_POST(self):
        if self.path != "/api/hello":
            self._send(404, b"not found", "text/plain")
            return
        req = urllib.request.Request(
            POSTGREST_URL,
            data=b"{}",
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                payload = res.read()
                # Validate shape before returning it to browser proof.
                data = json.loads(payload.decode())
                assert data.get("message") == "hello from pg18 postgrest"
                assert data.get("gateway") == "postgrest"
                self._send(200, payload, "application/json; charset=utf-8")
        except Exception as exc:
            self._send(502, json.dumps({"error": str(exc)}), "application/json")

    def log_message(self, format, *args):
        print("WEBPROOF", self.address_string(), format % args)

if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 18082), Handler)
    print("Serving PG18 PostgREST web proof on http://127.0.0.1:18082", flush=True)
    server.serve_forever()
