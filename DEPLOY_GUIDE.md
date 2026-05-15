# ☁️ CloudDoc Viewer — 服务端部署指南

> 在每台云服务器上部署 Alist 文件服务 + 状态监控 API

---

## 📦 一、安装 Alist（文件浏览服务）

### 方式 A：Docker 安装（推荐）

```bash
# 一键启动 Alist
docker run -d --restart=always \
  --name alist \
  -p 5244:5244 \
  -v /home/fei:/home/fei \
  xhofe/alist:latest

# 查看初始密码（重要！）
docker logs alist 2>&1 | grep "password"
```

### 方式 B：直接安装（无 Docker）

```bash
# 下载 Alist
curl -fsSL "https://github.com/AlistGo/alist/releases/latest/download/alist-linux-amd64.tar.gz" -o alist.tar.gz
tar -xzf alist.tar.gz && rm alist.tar.gz

# 启动（首次会生成密码）
./alist server

# 查看密码
./alist admin
```

### 验证安装

浏览器打开 `http://你的服务器IP:5244` → 输入 admin + 密码 → 登录成功 ✅

---

## 📁 二、配置 Alist 文件目录

登录 Alist 网页后台后：

1. **管理 → 存储 → 添加驱动**
2. 选择 **`本机存储（Local）`**
3. 挂载路径：`/`
4. 根目录路径：`/home/fei`（或你想展示的目录）
5. 保存

> 这样手机 APP 就能看到 `/home/fei` 下的所有文件了。

---

## 📊 三、安装状态监控 API（可选）

```bash
# 1. 下载脚本
wget -O /home/status_server.py https://raw.githubusercontent.com/FeiOxO/CloudDoc-Viewer/main/server/status_server.py
# 或直接从项目复制 server/status_server.py 到服务器

# 2. 安装依赖
pip3 install psutil

# 3. 后台启动
nohup python3 /home/status_server.py --port 3001 > /tmp/status_server.log 2>&1 &

# 4. 验证
curl http://localhost:3001/status
# 返回 JSON 说明成功 ✅
```

### 设置开机自启（systemd）

```bash
sudo tee /etc/systemd/system/status-server.service << 'EOF'
[Unit]
Description=Server Status Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/status_server.py --port 3001
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now status-server
```

---

## 🔒 四、放行防火墙端口

```bash
# 阿里云/腾讯云安全组放行：
#   - 5244（Alist）
#   - 3001（状态监控，可选）

# 服务器内部放行（如果有 firewalld 或 ufw）
sudo firewall-cmd --add-port=5244/tcp --permanent  # firewalld
sudo firewall-cmd --add-port=3001/tcp --permanent
sudo firewall-cmd --reload

# 或
sudo ufw allow 5244/tcp  # ufw
sudo ufw allow 3001/tcp
```

---

## 📱 五、手机 APP 添加服务器

完成上述步骤后，打开 APP：

```
首页 → ➕ 添加服务器
  ├─ 名称:     阿里云（自定义）
  ├─ 地址:     你的服务器公网 IP
  ├─ Alist端口: 5244
  ├─ 状态端口:  3001
  ├─ 用户名:    admin
  ├─ 密码:      Alist 密码（docker logs 看到的）
  └─ 保存 → 点击连接
```

---

## ✅ 验证清单

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 1 | `docker ps` | alist 容器在运行 |
| 2 | 浏览器访问 `IP:5244` | 看到 Alist 登录页 |
| 3 | 登录 Alist 后台配置存储 | 能看到文件列表 |
| 4 | `curl localhost:3001/status` | 返回 JSON 状态数据 |
| 5 | 手机 APP 添加服务器后点击 | 连上并显示文件/状态 |
