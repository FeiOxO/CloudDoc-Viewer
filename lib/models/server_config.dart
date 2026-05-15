/// 服务器配置数据模型
class ServerConfig {
  String id; // 唯一标识（UUID）
  String name; // 显示名称（如"阿里云"）
  String host; // IP 或域名
  int port; // Alist 端口
  int statusPort; // 状态 API 端口
  String username; // Alist 用户名
  String password; // Alist 密码
  String? note; // 备注
  bool enableStatus; // 是否启用状态监控
  DateTime createdAt;

  ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    this.port = 5244,
    this.statusPort = 3001,
    this.username = 'admin',
    this.password = '',
    this.note,
    this.enableStatus = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ServerConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    int? statusPort,
    String? username,
    String? password,
    String? note,
    bool? enableStatus,
    DateTime? createdAt,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      statusPort: statusPort ?? this.statusPort,
      username: username ?? this.username,
      password: password ?? this.password,
      note: note ?? this.note,
      enableStatus: enableStatus ?? this.enableStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'statusPort': statusPort,
        'username': username,
        'note': note,
        'enableStatus': enableStatus,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int? ?? 5244,
        statusPort: json['statusPort'] as int? ?? 3001,
        username: json['username'] as String? ?? 'admin',
        password: '',
        note: json['note'] as String?,
        enableStatus: json['enableStatus'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  String get baseUrl => 'http://$host:$port';
  String get statusUrl => 'http://$host:$statusPort';
}
