/**
 * PM2 Ecosystem — CloudDoc-Viewer 后端服务管理
 *
 * 管理：
 *   1. status-server  — Python 状态监控 API（本机进程）
 *   2. openlist       — Docker Compose 封装（容器）
 *
 * 用法：
 *   pm2 start ecosystem.config.js        # 启动全部
 *   pm2 start ecosystem.config.js --only status-server
 *   pm2 stop  ecosystem.config.js
 *   pm2 status
 *   pm2 logs  ecosystem.config.js
 */

const OPENLIST_DIR = '/home/fei/projects/OpenList';

module.exports = {
  apps: [
    // ── status-server ──────────────────────────────
    {
      name: 'status-server',
      script: '/home/fei/projects/CloudDoc-Viewer/server/status_server.py',
      interpreter: 'python3',
      cwd: '/home/fei/projects/CloudDoc-Viewer/server',
      env: {
        PORT: '3001',
        HOST: '0.0.0.0',
      },
      max_restarts: 5,
      restart_delay: 3000,
      // 健康检查 — PM2 会每 30s GET /status
      // 返回非 200 或超时则自动重启
      // 注意：必须绕过 http_proxy
      health_check_url: 'http://127.0.0.1:3001/status',
      // 但 127.0.0.1 在镜像网络下路由到 Windows，所以禁用内置健康检查
      // 改用 listen_timeout 确认启动成功
      listen_timeout: 5000,
      kill_timeout: 5000,
    },

    // ── openlist (Docker Compose 封装) ─────────────
    {
      name: 'openlist',
      script: 'docker',
      args: 'compose -f ' + OPENLIST_DIR + '/docker-compose.yml up',
      cwd: OPENLIST_DIR,
      // 重启策略：PM2 管理 Docker 生命周期
      // docker compose up 是前台进程，PM2 会监控其存活
      max_restarts: 3,
      restart_delay: 5000,
      kill_timeout: 15000,
      stop_exit_codes: [0, 130, 143],  // docker stop 正常退出码
    },
  ],
};
