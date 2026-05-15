# ☁️ CloudDoc Viewer

多服务器 Markdown 文档阅读器 + 状态监控 Flutter APP

## 📱 功能

| 功能 | 说明 |
|------|------|
| 🔐 **多服务器管理** | 添加/编辑/删除多台云服务器 |
| 📂 **远程文件浏览** | 通过 Alist API 浏览服务器文件 |
| 📝 **Markdown 阅读器** | 在线渲染 .md 文件，支持代码高亮、深色模式 |
| 📊 **服务器状态监控** | 实时查看 CPU、内存、磁盘使用率 |
| ➕ **可扩展** | 随时可添加新的云服务器 |

## 🏗️ 项目结构

```
cloud_doc_viewer/
├── lib/
│   ├── main.dart                  # APP 入口
│   ├── models/
│   │   ├── server_config.dart     # 服务器配置模型
│   │   ├── server_status.dart     # 服务器状态模型
│   │   └── file_entry.dart        # 文件条目模型
│   ├── services/
│   │   ├── server_manager.dart    # 服务器配置管理（增删改查）
│   │   ├── alist_api.dart         # Alist API 客户端
│   │   └── status_api.dart        # 状态 API 客户端
│   └── pages/
│       ├── home_page.dart         # 首页 - 服务器列表
│       ├── add_server_page.dart   # 添加/编辑服务器
│       ├── login_page.dart        # 登录页
│       ├── server_detail_page.dart # 服务器详情（状态+文件）
│       ├── file_list_page.dart    # 文件浏览
│       └── markdown_viewer_page.dart # Markdown 阅读器
├── server/
│   └── status_server.py           # 服务器端状态监控 API
└── pubspec.yaml
```

## 🚀 使用流程

### 1. 服务器端部署

**每台云服务器上**都需要安装：

```bash
# 1. 安装 Alist（用于文件浏览）
docker run -d --restart=always --name alist \
  -p 5244:5244 \
  -v /home/fei:/home/fei \
  xhofe/alist:latest

# 2. 启动状态监控 API（可选）
pip3 install psutil
nohup python3 status_server.py &

# 3. 查看 Alist 默认密码
docker logs alist
```

### 2. Flutter APP 打包

```bash
# 进入项目目录
cd D:\DesktopDocument\FlutterProjects\cloud_doc_viewer

# 安装依赖
flutter pub get

# 打包 APK
flutter build apk --release
```

### 3. 在手机上使用

1. 安装 APK
2. 点击"添加服务器"
3. 填写服务器地址、Alist 端口(5244)、密码
4. 连接成功 → 浏览文件 → 点击 .md 直接查看
5. 后续加新服务器 → 首页点"添加"再填一次即可

## 🔧 技术栈

- **Flutter** 3.x + Material 3
- **Alist** (服务器端文件管理)
- **自建状态 API** (Python http.server + psutil)
