#!/usr/bin/env bash
# ============================================================
# 服务健康检查 — status-server + OpenList API 一键检测
#
# 用法:
#   ./server/status-check.sh                              # 默认 localhost
#   ./server/status-check.sh 192.168.21.32                # 指定 IP
#   SERVER_HOST=192.168.21.32 ./server/status-check.sh    # 环境变量
#   ./server/status-check.sh --watch [秒数] [HOST]
#   ./server/status-check.sh --json [HOST]
# ============================================================
set -euo pipefail

# ── 解析参数 ──
MODE=""
INTERVAL=10
HOST=""
ARGS=()

for arg in "$@"; do
  case "$arg" in
    --watch|-w) MODE="watch" ;;
    --json|-j)  MODE="json" ;;
    --help|-h)  MODE="help" ;;
    *)
      # 数字 = interval（watch 模式），否则 = host
      if [[ "$MODE" == "watch" && "$arg" =~ ^[0-9]+$ ]]; then
        INTERVAL="$arg"
      else
        ARGS+=("$arg")
      fi
      ;;
  esac
done

# 优先环境变量 SERVER_HOST，否则第一个非选项参数，否则默认
HOST="${SERVER_HOST:-${ARGS[0]:-127.0.0.1}}"

STATUS_URL="http://$HOST:3001"
OPENLIST_URL="http://$HOST:5244"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 绕过代理
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

check_status_server() {
  local resp
  resp=$(curl -sf --max-time 5 "$STATUS_URL/status" 2>/dev/null) || return 1
  echo "$resp"
}

check_openlist() {
  local resp
  resp=$(curl -sf --max-time 5 "$OPENLIST_URL/api/public/settings" 2>/dev/null) || return 1
  echo "$resp"
}

print_human() {
  echo "=========================================="
  echo -e "  ${BOLD}服务健康检查 — $HOST${NC}"
  echo "=========================================="
  echo ""

  # status-server
  local ss_resp
  ss_resp=$(check_status_server) && {
    local hostname cpu mem disk uptime
    hostname=$(echo "$ss_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hostname','?'))" 2>/dev/null)
    cpu=$(echo "$ss_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d['cpu']['usage_percent']:.1f}%\")" 2>/dev/null)
    mem=$(echo "$ss_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d['memory']['used_gb']:.1f}/{d['memory']['total_gb']:.1f} GB\")" 2>/dev/null)
    disk=$(echo "$ss_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d['disk']['used_gb']:.1f}/{d['disk']['total_gb']:.1f} GB\")" 2>/dev/null)
    uptime=$(echo "$ss_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uptime','?'))" 2>/dev/null)
    echo -e "  ${GREEN}✅ status-server${NC}  (端口 3001)"
    echo "     主机名 : $hostname"
    echo "     运行   : $uptime"
    echo "     CPU    : $cpu"
    echo "     内存   : $mem"
    echo "     磁盘   : $disk"
  } || {
    echo -e "  ${RED}❌ status-server${NC}  (端口 3001) — 未响应"
  }

  echo ""

  # OpenList
  local ol_resp
  ol_resp=$(check_openlist) && {
    local version
    version=$(echo "$ol_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('version','?'))" 2>/dev/null)
    echo -e "  ${GREEN}✅ OpenList${NC}  (端口 5244)"
    echo "     版本 : $version"
  } || {
    echo -e "  ${RED}❌ OpenList${NC}  (端口 5244) — 未响应"
  }

  echo ""
  echo "=========================================="
}

print_json() {
  local ss_ok=false ol_ok=false
  local ss_data="null" ol_data="null"

  local resp
  resp=$(check_status_server) && { ss_ok=true; ss_data=$resp; } || true
  resp=$(check_openlist) && { ol_ok=true; ol_data=$resp; } || true

  python3 -c "
import json, sys
result = {
  'host': '$HOST',
  'timestamp': $(date +%s),
  'services': {
    'status-server': {'online': $ss_ok, 'data': $ss_data},
    'openlist':      {'online': $ol_ok, 'data': $ol_data},
  }
}
json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
"
}

cmd_watch() {
  echo "每 ${INTERVAL}s 轮询 $HOST — Ctrl+C 退出"
  echo ""
  while true; do
    clear 2>/dev/null || true
    print_human
    sleep "$INTERVAL"
  done
}

# ── 主入口 ──
case "$MODE" in
  json)  print_json ;;
  watch) cmd_watch ;;
  help)  echo "用法: $0 [--watch 秒数|--json] [HOST]"; echo "       SERVER_HOST=ip $0" ;;
  *)     print_human ;;
esac
