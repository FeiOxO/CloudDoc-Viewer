import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/server_config.dart';
import '../models/server_status.dart';
import '../services/server_manager.dart';
import '../services/status_api.dart';
import 'add_server_page.dart';
import 'login_page.dart';

/// 首页 — 服务器选择列表
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ServerManager _manager = ServerManager();
  List<ServerConfig> _servers = [];
  final Map<String, ServerStatus> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() => _loading = true);
    final servers = await _manager.getServers();
    setState(() {
      _servers = servers;
      _loading = false;
    });

    // 异步加载每台服务器的状态
    for (final server in servers) {
      if (server.enableStatus) {
        _refreshStatus(server);
      }
    }
  }

  Future<void> _refreshStatus(ServerConfig server) async {
    final status = await StatusApi.fetchStatus(server.host, server.statusPort);
    if (mounted) {
      setState(() => _statuses[server.id] = status);
    }
  }

  void _navigateToAddServer() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddServerPage()),
    );
    if (result == true) _loadServers();
  }

  void _navigateToLogin(ServerConfig server) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(server: server)),
    );
    if (result == true) {
      // 登录成功后进入文件浏览
      // LoginPage 内部会跳转到文件列表
    }
  }

  Color _statusColor(ServerStatus? status) {
    if (status == null || !status.online) return Colors.grey;
    return Colors.green;
  }

  String _statusText(ServerStatus? status) {
    if (status == null) return '加载中...';
    if (!status.online) return '离线';
    return 'CPU ${status.cpuUsage.toStringAsFixed(0)}% · 内存 ${status.memoryUsagePercent.toStringAsFixed(0)}% · 磁盘 ${status.diskUsagePercent.toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的云服务器'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServers,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _loading
          ? _buildShimmer()
          : _servers.isEmpty
              ? _buildEmptyState()
              : _buildServerList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddServer,
        icon: const Icon(Icons.add),
        label: const Text('添加服务器'),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '还没有添加任何服务器',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加你的第一台服务器',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildServerList() {
    return RefreshIndicator(
      onRefresh: _loadServers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _servers.length,
        itemBuilder: (context, index) {
          final server = _servers[index];
          final status = _statuses[server.id];
          return _buildServerCard(server, status);
        },
      ),
    );
  }

  Widget _buildServerCard(ServerConfig server, ServerStatus? status) {
    final isOnline = status?.online ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToLogin(server),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 状态指示灯
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 16),

              // 文字信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server.host,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (server.note != null && server.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          server.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _statusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green[700] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // 箭头
              const Icon(Icons.chevron_right, color: Colors.grey),

              // 长按弹出菜单
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, server),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, size: 20),
                      title: Text('编辑'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red, size: 20),
                      title: Text('删除', style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, ServerConfig server) async {
    if (action == 'edit') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AddServerPage(editServer: server),
        ),
      );
      if (result == true) _loadServers();
    } else if (action == 'delete') {
      _confirmDelete(server);
    }
  }

  void _confirmDelete(ServerConfig server) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定删除「${server.name}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _manager.deleteServer(server.id);
              _loadServers();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
