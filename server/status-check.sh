#!/usr/bin/env bash
# ============================================================
# 服务健康检查 — status-server + OpenList API 一键检测
#
# 用法:
#   ./server/status-check.sh
#   ./server/status-check.sh --watch   每 10 秒轮询一次
#   ./server/status-check.sh --json    输出 JSON 格式
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATUS_URL="http://192.168.21.32:3001"
OPENLIST_URL="http://192.168.21.32:5244"

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
  echo "======================================"
  echo -e "  ${BOLD}CloudDoc-Viewer 服务健康检查${NC}"
  echo "======================================"
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
  echo "======================================"
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
  'timestamp': $(date +%s),
  'services': {
    'status-server': {'online': $ss_ok, 'data': $ss_data},
    'openlist':      {'online': $ol_ok, 'data': $ol_data},
  }
}
json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
"
}

cmd_default() {
  print_human
  # 返回码: 0=全部正常, 1=部分异常
  check_status_server >/dev/null && check_openlist >/dev/null
}

cmd_watch() {
  local interval="${1:-10}"
  info "每 ${interval}s 轮询 — Ctrl+C 退出"
  echo ""
  while true; do
    clear 2>/dev/null || true
    print_human
    sleep "$interval"
  done
}

# ── 主入口 ──
main() {
  local mode="${1:-}"
  shift 2>/dev/null || true

  case "$mode" in
    --json|-j)           print_json ;;
    --watch|-w)          cmd_watch "${1:-10}" ;;
    --help|-h)           echo "用法: $0 [--json|--watch [秒数]]" ;;
    *)                   cmd_default ;;
  esac
}

main "$@"
