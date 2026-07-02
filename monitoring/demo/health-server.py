#!/usr/bin/env python3
"""極簡 HTTP 健康服務 — 給監控當 canary 與失敗測試靶子。

用 stdlib，無外部依賴（VM 沒 Go toolchain，Python 免編譯直接跑）。
路由：
  /health, /   → 200 ok（正常回應）
  /crash       → 故意 exit(1)：進程退出 → systemd 標 failed → OnFailure 告警
  /hang        → 停止回應但進程不死：health-check timer 抓得到、systemd 抓不到
                 （示範「進程活著 ≠ 在運作」）
"""
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = "127.0.0.1"
PORT = 8899


class Handler(BaseHTTPRequestHandler):
    def _text(self, code, body):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(body.encode())

    def do_GET(self):
        if self.path in ("/health", "/"):
            self._text(200, "ok\n")
        elif self.path == "/crash":
            self._text(200, "crashing\n")
            sys.exit(1)  # 故意 crash
        elif self.path == "/hang":
            self._text(200, "hanging\n")
            time.sleep(3600)  # 進程還在、但不再處理請求
        else:
            self._text(404, "not found\n")

    def log_message(self, *args):
        pass  # 安靜，不洗 journal


if __name__ == "__main__":
    HTTPServer((HOST, PORT), Handler).serve_forever()
