#!/usr/bin/env bash
# ============================================================
# CloudDoc-Viewer 服务管理脚本
# 统一管理 status-server (PM2) + OpenList (Docker Compose)
#
# 用法:
#   ./server/manage.sh status        查看所有服务状态
#   ./server/manage.sh start         启动所有服务
#   ./server/manage.sh stop          停止所有服务
#   ./server/manage.sh restart       重启所有服务
#   ./server/manage.sh logs [name]   查看日志（可选指定服务名）
#   ./server/manage.sh ps            查看 PM2 进程列表
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENLIST_DIR="/home/fei/projects/OpenList"
ECOSYSTEM="$SCRIPT_DIR/server/pm2-ecosystem.config.js"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}   $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
err()   { echo -e "${RED}[err]${NC}  $*" >&2; }

# ── 确保 PM2 和 Docker 可用 ──
check_deps() {
  command -v pm2 >/dev/null 2>&1 || { err "pm2 未安装"; exit 1; }
  command -v docker >/dev/null 2>&1 || { err "docker 未安装"; exit 1; }
}

# ── 状态 ──
cmd_status() {
  info "=== PM2 进程 ==="
  pm2 list 2>&1 | tail -n +3 | head -n -2 || true
  echo ""

  info "=== Docker 容器 ==="
  docker ps --filter "name=openlist" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1 || true
  echo ""

  info "=== API 健康检查 ==="
  # status-server
  if curl -sf --max-time 3 http://192.168.21.32:3001/status >/dev/null 2>&1; then
    ok "status-server  http://192.168.21.32:3001/status  ✅"
  else
    err "status-server  ❌"
  fi
  # OpenList
  if curl -sf --max-time 3 http://192.168.21.32:5244/api/public/settings >/dev/null 2>&1; then
    ok "OpenList       http://192.168.21.32:5244        ✅"
  else
    err "OpenList       ❌"
  fi
}

# ── 启动 ──
cmd_start() {
  info "启动 status-server ..."
  pm2 start "$ECOSYSTEM" --only status-server 2>&1 || true
  ok "status-server 已启动"

  info "启动 OpenList ..."
  (cd "$OPENLIST_DIR" && docker compose up -d 2>&1) || true
  ok "OpenList 已启动"

  echo ""
  cmd_status
}

# ── 停止 ──
cmd_stop() {
  info "停止 status-server ..."
  pm2 stop status-server 2>&1 || true
  ok "status-server 已停止"

  info "停止 OpenList ..."
  (cd "$OPENLIST_DIR" && docker compose stop 2>&1) || true
  ok "OpenList 已停止"
}

# ── 重启 ──
cmd_restart() {
  cmd_stop
  sleep 1
  cmd_start
}

# ── 日志 ──
cmd_logs() {
  local name="${1:-}"
  if [ -z "$name" ]; then
    pm2 logs status-server --lines 30
    echo ""
    info "OpenList 日志："
    (cd "$OPENLIST_DIR" && docker compose logs --tail=30)
  elif [ "$name" = "status-server" ]; then
    pm2 logs status-server --lines 50
  elif [ "$name" = "openlist" ]; then
    (cd "$OPENLIST_DIR" && docker compose logs --tail=50)
  else
    err "未知服务: $name (可选: status-server, openlist)"
    exit 1
  fi
}

# ── PM2 进程列表 ──
cmd_ps() {
  pm2 list 2>&1 | tail -n +3 | head -n -2 || true
}

# ── 主入口 ──
main() {
  check_deps

  # 去掉 http_proxy，本地 curl 不走代理
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

  local cmd="${1:-status}"
  shift 2>/dev/null || true

  case "$cmd" in
    status|start|stop|restart|logs|ps)
      "cmd_$cmd" "$@"
      ;;
    *)
      echo "用法: $0 {status|start|stop|restart|logs|ps}"
      echo ""
      echo "  status     查看所有服务状态 + API 健康检查"
      echo "  start      启动所有服务"
      echo "  stop       停止所有服务"
      echo "  restart    重启所有服务"
      echo "  logs [svc] 查看日志（可指定 status-server / openlist）"
      echo "  ps         查看 PM2 进程列表"
      exit 1
      ;;
  esac
}

main "$@"
