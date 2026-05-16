# CloudDoc-Viewer 开发记录 & 问题解决

> 记录项目开发过程中遇到的所有问题、排查思路和解决方案。

---

## 目录

1. [Flutter 环境搭建](#1-flutter-环境搭建)
2. [代码错误修复](#2-代码错误修复)
3. [弃用 API 迁移](#3-弃用-api-迁移)
4. [Android 平台支持](#4-android-平台支持)
5. [Alist → OpenList 迁移](#5-alist--openlist-迁移)
6. [Markdown 渲染不支持 HTML](#6-markdown-渲染不支持-html)
7. [服务器状态监控 (status-server)](#7-服务器状态监控-status-server)
8. [WSL 镜像网络下 Flutter Web 构建失败](#8-wsl-镜像网络下-flutter-web-构建失败)
9. [脚本参数硬编码](#9-脚本参数硬编码)
10. [Git 提交规范](#10-git-提交规范)

---

## 1. Flutter 环境搭建

### 问题

WSL 上需要搭建 Flutter 开发环境并支持 Web 平台。Flutter SDK 需要下载、配置 PATH 和代理。

### 解决

```bash
# SDK 下载到 /etc/flutter/
sudo mkdir -p /etc/flutter && sudo chown $USER:$USER /etc/flutter
cd /etc
curl -L -o flutter.tar.xz \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz
tar xf flutter.tar.xz
rm flutter.tar.xz

# PATH 写入 ~/.bashrc
export PATH="/etc/flutter/bin:$PATH"

# 配置代理（GFW 需要）
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897

# 启用 Web
flutter config --enable-web
```

**坑**：
- WSL 镜像网络下 `127.0.0.1:7897` 路由到 Windows 主机的代理客户端，所以代理配 `127.0.0.1` 可以正常走 Windows 代理
- 首次 `flutter --version` 会下载 Dart SDK（～50MB），需要等 30-60s，超时设长一点

---

## 2. 代码错误修复

### 问题

`flutter analyze` 报告 4 个错误、13 个警告/信息。

### 解决清单

| 文件 | 问题 | 原因 | 修复 |
|------|------|------|------|
| `home_page.dart` | ❌ `ServerManager` 未导入 | 缺少 import | 添加 `import '../services/server_manager.dart'` |
| `add_server_page.dart` | ❌ 命名参数在可选位置参数组内 | Dart 不支持 `[String? hint, {Widget? suffix}]` 语法 | 改为 `[String? hint, Widget? suffix]`，调用处去掉 `suffix:` 命名前缀 |
| `login_page.dart` | ⚠️ 未使用 import | 残留引用 | 移除行 |
| `markdown_viewer_page.dart` | ⚠️ 未使用变量 `theme` | 声明未使用 | 移除变量 |

### 关键教训

**Dart 函数参数规则**：可选位置参数（`[]`）内部不能包含命名参数（`{}`）。如果需要可选命名参数，必须放在单独的位置：

```dart
// ❌ 错误
void foo([String? a, {Widget? b}]) {}

// ✅ 正确 — 命名参数单独声明
void foo([String? a], {Widget? b}) {}

// ✅ 或全部命名参数
void foo({String? a, Widget? b}) {}
```

---

## 3. 弃用 API 迁移

### 3.1 `Color.withOpacity(x)` → `withValues(alpha: x)`

Flutter 3.27+ 弃用了 `withOpacity`，替换为 `withValues(alpha: ...)`。

```dart
// ❌ 弃用
Colors.blue.withOpacity(0.1)

// ✅ 现代
Colors.blue.withValues(alpha: 0.1)
```

共修复 6 处，分布在 4 个文件。

### 3.2 `imageBuilder` → `sizedImageBuilder` (flutter_markdown)

`flutter_markdown` 0.7.7+ 弃用了 `imageBuilder`，替换为 `sizedImageBuilder`，且函数签名不同：

```dart
// ❌ 弃用 — 3 参数
imageBuilder: (uri, title, alt) { ... }

// ✅ 现代 — 单参数 MarkdownImageConfig
sizedImageBuilder: (config) {
  final src = config.uri.toString();
  // config.title, config.alt, config.width, config.height
}
```

---

## 4. Android 平台支持

### 问题

项目支持 Web，但需要添加 Android 平台。运行 `flutter create --platforms=android .` 后出现多个问题。

### 4.1 自动生成的测试文件引用 `MyApp`

项目主类为 `CloudDocViewerApp`，但生成的 `test/widget_test.dart` 引用 `MyApp`：

**解决**：直接删除 `test/widget_test.dart`（或更新为正确类名）。

### 4.2 INTERNET 权限

Android 默认不允许 HTTP 请求，需要手动添加：

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    ...
```

### 4.3 依赖位置错误

`uuid` 包在 `dev_dependencies` 下但在生产代码中被引用，`flutter analyze` 报错：

**解决**：将 `uuid` 从 `dev_dependencies` 移到 `dependencies`。

### 4.4 新增 info 级别 lint

| 规则 | 修复方式 |
|------|----------|
| `prefer_final_fields` | 只赋值一次的字段加 `final` |
| `prefer_const_constructors` | 能用 `const` 的构造函数加上 `const` |
| `prefer_interpolation_to_compose_strings` | 字符串拼接改用插值 `$var` |

运行 `flutter analyze --no-fatal-infos` 可在开发时忽略 info 级别问题。

---

## 5. Alist → OpenList 迁移

### 问题

后端从 Alist v3 切换为 OpenList（基于 Alist v4），需要迁移全部 API 调用代码。

### API 兼容性

OpenList 完全兼容 Alist 的 API 路径和认证方式（JWT token），仅需重命名类和方法引用。

### 迁移步骤

1. 重命名 `lib/services/alist_api.dart` → `openlist_api.dart`
2. 类名 `AlistApi` → `OpenListApi`
3. 更新所有 `import` 语句（5 个文件）
4. 变量名 `_alistApi` → `_openListApi`
5. UI 标签：`"Alist 端口"` → `"OpenList 端口"`，等
6. 注释更新

### 注意事项

- 业务逻辑不变，仅做命名替换，降低风险
- OpenList v4 的 `/api/fs/get` 已弃用，文件内容改为通过 `/d` 原始路径 GET 获取
- OpenList v4 的文件列表 API 返回条目中**缺少 `path` 字段**，前端需要自行拼接：`_currentPath + entry.name`

---

## 6. Markdown 渲染不支持 HTML

### 问题

服务端返回的 `.md` 文件实际上是 **HTML 内容**（`<h1>`、`<table>`、`<pre><code>` 等标签），但 APP 用 `flutter_markdown`（Markdown 解析器）渲染，导致 HTML 标签全部被忽略，只显示了 4.2~4.3 小节的部分代码块内容。

### 解决

将 Markdown 渲染器替换为 HTML 渲染引擎：

1. 移除 `flutter_markdown` + `flutter_highlight`
2. 添加 `flutter_widget_from_html: ^0.16.1`
3. 将 `Markdown(data: _content)` 替换为 `HtmlWidget(_content)`
4. 使用 `customStylesBuilder` 配置所有 HTML 元素样式：
   - 标题（h1/h2/h3）、表格（table/th/td）、代码块（pre/code）、引用（blockquote）、列表（ul/ol/li）、分割线（hr）、链接（a）、图片（img）
   - 暗色/亮色主题双支持

**关键文件**：`lib/pages/markdown_viewer_page.dart`

---

## 7. 服务器状态监控 (status-server)

### 问题

APP 的服务器详情页显示"未启用服务器状态监控"或无法获取数据。

### 原因 1 — 服务未运行

`status_server.py`（Python 轻量 HTTP 服务，监听端口 3001）没有在运行。

**解决**：通过 PM2 管理：

```bash
pm2 start server/status_server.py --name status-server
pm2 save
```

### 原因 2 — 配置未开启

APP 中添加服务器时 `enableStatus` 为 `false`，或状态端口不匹配。

**解决**：在 APP 的服务器编辑页面中：
1. 打开「启用服务器状态监控」开关
2. 确认「状态端口」为 `3001`

### 管理脚本

新增三个工具脚本到 `server/` 目录：

| 文件 | 用途 |
|------|------|
| `pm2-ecosystem.config.js` | PM2 ecosystem 配置，定义 status-server 和 openlist（Docker）两个进程 |
| `manage.sh` | 统一管理命令：`start\|stop\|restart\|status\|logs\|ps` |
| `status-check.sh` | API 健康检查：检测 status-server + OpenList 是否正常运行 |

**坑**：WSL 下 `curl` 默认走 `http_proxy` 代理，本地请求需先 `unset http_proxy`，否则代理返回 502。

---

## 8. WSL 镜像网络下 Flutter Web 构建失败

### 问题

在 WSL 镜像网络模式（`networkingMode=mirrored`）下运行 `flutter build web --release`，`dart2js` 连接 VM 服务时使用 `127.0.0.1`，但在镜像模式下 `127.0.0.1` 路由到 **Windows 主机** 而非 WSL，导致连接失败：

```
HttpException: Connection closed before full header was received
DartDevelopmentServiceException: WebSocketChannelException
```

### 解决

**开发测试**：使用 `flutter run -d edge`（使用 DDC 编译，不走 dart2js）。

**发布构建**：两个方案：
- 临时将 WSL 网络模式改为 NAT
- 或设置 `DART_VM_SERVICE_HOST=192.168.21.32` 环境变量

```bash
export DART_VM_SERVICE_HOST=192.168.21.32
flutter build web --release
```

---

## 9. 脚本参数硬编码

### 问题

管理脚本中 IP 地址 `192.168.21.32` 被硬编码，无法用于其他服务器。

### 解决

所有可变参数改为可配置：

```bash
# 直接传参
./server/status-check.sh 123.45.67.89
./server/manage.sh status 123.45.67.89

# 环境变量
SERVER_HOST=123.45.67.89 ./server/status-check.sh
```

**原则**：任何可能变化的参数（IP、端口、路径、用户名等）都不能硬编码，必须做成参数、环境变量或配置文件读取的方式。

---

## 10. Git 提交规范

### 要求

每次修改代码后必须执行 `git add + commit + push`。

### 仓库信息

- 远程仓库：`github.com/FeiOxO/CloudDoc-Viewer.git`
- 分支：`main`
- 用户：`FeiOxO` / `3500756911@qq.com`

### 冲突处理

`git push` 被拒绝时（远程有更新），使用 rebase：

```bash
git pull --rebase
# 解决冲突后
git add <files>
git rebase --continue
git push
```

自动生成的文件（`.metadata`、`android/` 等）在冲突时接受本地版本：
```bash
git checkout --theirs <file>
```

---

## 项目信息

| 项目 | 值 |
|------|-----|
| 项目路径 | `/home/fei/projects/CloudDoc-Viewer/` |
| Flutter SDK | `/etc/flutter/bin/flutter` (v3.27.4) |
| 代理 | `http://127.0.0.1:7897`（WSL → Windows 代理） |
| OpenList 路径 | `/home/fei/projects/OpenList/` |
| 状态服务 | `server/status_server.py` (PM2: `status-server`, port 3001) |
| Git 仓库 | `github.com/FeiOxO/CloudDoc-Viewer.git` |
| 本地测试 IP | `192.168.21.32`（WSL 镜像网络下的 eth0 IP） |
