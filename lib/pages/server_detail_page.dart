import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../models/server_status.dart';
import '../services/alist_api.dart';
import '../services/status_api.dart';
import 'file_list_page.dart';

/// 服务器详情页（状态 + 文件浏览 Tab）
class ServerDetailPage extends StatefulWidget {
  final ServerConfig server;
  final AlistApi alistApi;

  const ServerDetailPage({
    super.key,
    required this.server,
    required this.alistApi,
  });

  @override
  State<ServerDetailPage> createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ServerStatus? _status;
  bool _statusLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    if (!widget.server.enableStatus) {
      setState(() => _statusLoading = false);
      return;
    }

    setState(() => _statusLoading = true);
    final status = await StatusApi.fetchStatus(
      widget.server.host,
      widget.server.statusPort,
    );
    if (mounted) {
      setState(() {
        _status = status;
        _statusLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStatus();
              setState(() {}); // 触发文件列表刷新
            },
            tooltip: '刷新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart_outlined), text: '服务器状态'),
            Tab(icon: Icon(Icons.folder_outlined), text: '文件管理'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(),
          FileListPage(alistApi: widget.alistApi),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    if (_statusLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!widget.server.enableStatus) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '未启用服务器状态监控\n可到编辑页面开启',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_status == null || !_status!.online) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            const Text('服务器离线', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadStatus,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final s = _status!;

    return RefreshIndicator(
      onRefresh: _loadStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态概览卡片
            _buildInfoCard(s),
            const SizedBox(height: 16),

            // CPU
            _buildProgressCard(
              'CPU',
              '${s.cpuUsage.toStringAsFixed(1)}% · ${s.cpuCores} 核',
              s.cpuUsage / 100,
              Colors.blue,
            ),
            const SizedBox(height: 12),

            // 内存
            _buildProgressCard(
              '内存',
              '${s.memoryUsedGb.toStringAsFixed(1)} GB / ${s.memoryTotalGb.toStringAsFixed(1)} GB',
              s.memoryUsagePercent / 100,
              Colors.green,
            ),
            const SizedBox(height: 12),

            // 磁盘
            _buildProgressCard(
              '磁盘',
              '${s.diskUsedGb.toStringAsFixed(1)} GB / ${s.diskTotalGb.toStringAsFixed(1)} GB',
              s.diskUsagePercent / 100,
              Colors.orange,
            ),
            const SizedBox(height: 16),

            // 其他信息
            _buildDetailCard(s),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ServerStatus s) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.hostname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已运行 ${s.uptime ?? '--'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '在线',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      String label, String detail, double progress, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(ServerStatus s) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细信息',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _detailRow('平台', s.platform),
            _detailRow('进程数', '${s.processes}'),
            _detailRow('服务器地址', widget.server.host),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}
