#!/usr/bin/env python3
"""
服务器状态监控 API
轻量级 HTTP 服务，返回 CPU、内存、磁盘等实时状态

用法：
  python3 status_server.py          # 默认端口 3001
  python3 status_server.py --port 8080  # 自定义端口

安装依赖：
  pip3 install psutil
"""

import json
import platform
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False


def get_status():
    """收集服务器状态信息"""
    if not HAS_PSUTIL:
        return {
            "error": "psutil 未安装，请运行: pip3 install psutil",
            "hostname": platform.node(),
            "platform": platform.platform(),
        }

    boot_time = psutil.boot_time()
    uptime_seconds = time.time() - boot_time
    days = int(uptime_seconds // 86400)
    hours = int((uptime_seconds % 86400) // 3600)
    minutes = int((uptime_seconds % 3600) // 60)

    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    return {
        "hostname": platform.node(),
        "uptime": f"{days}天 {hours}小时 {minutes}分",
        "cpu": {
            "usage_percent": psutil.cpu_percent(interval=1),
            "cores": psutil.cpu_count(logical=True),
            "load_avg": [round(x, 2) for x in psutil.getloadavg()],
        },
        "memory": {
            "total_gb": round(mem.total / (1024**3), 1),
            "used_gb": round(mem.used / (1024**3), 1),
            "free_gb": round(mem.available / (1024**3), 1),
            "usage_percent": round(mem.percent, 1),
        },
        "disk": {
            "total_gb": round(disk.total / (1024**3), 1),
            "used_gb": round(disk.used / (1024**3), 1),
            "free_gb": round(disk.free / (1024**3), 1),
            "usage_percent": round(disk.percent, 1),
        },
        "processes": len(psutil.pids()),
        "platform": platform.platform(),
        "timestamp": int(time.time()),
    }


class StatusHandler(BaseHTTPRequestHandler):
    """HTTP 请求处理"""

    def do_GET(self):
        parsed = urlparse(self.path)

        if parsed.path == '/status':
            data = get_status()
            self._json_response(200, data)
        elif parsed.path == '/health':
            self._json_response(200, {"status": "ok"})
        elif parsed.path == '/':
            self._json_response(200, {
                "service": "Server Status API",
                "endpoints": {
                    "/status": "服务器实时状态（CPU/内存/磁盘）",
                    "/health": "健康检查",
                },
                "docs": "配合 CloudDoc Viewer APP 使用",
            })
        else:
            self._json_response(404, {"error": "Not Found"})

    def do_OPTIONS(self):
        self._set_cors()
        self.send_response(200)
        self.end_headers()

    def _json_response(self, code, data):
        self._set_cors()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def _set_cors(self):
        pass

    def log_message(self, format, *args):
        # 简洁日志
        print(f"[{time.strftime('%H:%M:%S')}] {args[0]} {args[1]}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description='服务器状态监控 API')
    parser.add_argument('--port', type=int, default=3001, help='监听端口')
    parser.add_argument('--host', type=str, default='0.0.0.0', help='监听地址')
    args = parser.parse_args()

    if not HAS_PSUTIL:
        print("⚠️  psutil 未安装，状态数据将不完整")
        print("   运行: pip3 install psutil")
        print()

    server = HTTPServer((args.host, args.port), StatusHandler)
    print(f"✅ 状态监控 API 已启动")
    print(f"   http://{args.host}:{args.port}/status")
    print(f"   http://{args.host}:{args.port}/health")
    print()
    print(f"   在 APP 中添加服务器时，状态端口填写: {args.port}")
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 服务已停止")
        server.server_close()


if __name__ == '__main__':
    main()
