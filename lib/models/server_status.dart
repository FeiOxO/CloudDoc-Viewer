/// 服务器状态数据模型
class ServerStatus {
  final String hostname;
  final String? uptime;
  final double cpuUsage;
  final int cpuCores;
  final double memoryTotalGb;
  final double memoryUsedGb;
  final double memoryUsagePercent;
  final double diskTotalGb;
  final double diskUsedGb;
  final double diskUsagePercent;
  final int processes;
  final String platform;
  final bool online;

  ServerStatus({
    required this.hostname,
    this.uptime,
    required this.cpuUsage,
    required this.cpuCores,
    required this.memoryTotalGb,
    required this.memoryUsedGb,
    required this.memoryUsagePercent,
    required this.diskTotalGb,
    required this.diskUsedGb,
    required this.diskUsagePercent,
    required this.processes,
    required this.platform,
    this.online = true,
  });

  factory ServerStatus.offline() => ServerStatus(
        hostname: '--',
        cpuUsage: 0,
        cpuCores: 0,
        memoryTotalGb: 0,
        memoryUsedGb: 0,
        memoryUsagePercent: 0,
        diskTotalGb: 0,
        diskUsedGb: 0,
        diskUsagePercent: 0,
        processes: 0,
        platform: '--',
        online: false,
      );

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      hostname: json['hostname'] as String? ?? 'unknown',
      uptime: json['uptime'] as String?,
      cpuUsage: (json['cpu']?['usage_percent'] as num?)?.toDouble() ?? 0,
      cpuCores: (json['cpu']?['cores'] as num?)?.toInt() ?? 0,
      memoryTotalGb: (json['memory']?['total_gb'] as num?)?.toDouble() ?? 0,
      memoryUsedGb: (json['memory']?['used_gb'] as num?)?.toDouble() ?? 0,
      memoryUsagePercent:
          (json['memory']?['usage_percent'] as num?)?.toDouble() ?? 0,
      diskTotalGb: (json['disk']?['total_gb'] as num?)?.toDouble() ?? 0,
      diskUsedGb: (json['disk']?['used_gb'] as num?)?.toDouble() ?? 0,
      diskUsagePercent:
          (json['disk']?['usage_percent'] as num?)?.toDouble() ?? 0,
      processes: (json['processes'] as num?)?.toInt() ?? 0,
      platform: json['platform'] as String? ?? '--',
    );
  }
}
