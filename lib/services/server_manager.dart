import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/server_config.dart';

/// 服务器配置管理（增删改查 + 密码加密存储）
class ServerManager {
  static const String _keyServers = 'servers_list';
  static const String _keyLastServerId = 'last_server_id';
  static const String _storagePrefix = 'server_pwd_';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ──────────────────────────────────────────────
  // 获取所有服务器
  // ──────────────────────────────────────────────
  Future<List<ServerConfig>> getServers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyServers);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    final List<dynamic> list = jsonDecode(jsonStr);
    final servers = <ServerConfig>[];

    for (final item in list) {
      final server = ServerConfig.fromJson(item as Map<String, dynamic>);
      // 解密密码
      server.password =
          await _secureStorage.read(key: '$_storagePrefix${server.id}') ?? '';
      servers.add(server);
    }

    return servers;
  }

  // ──────────────────────────────────────────────
  // 保存服务器列表（密码单独存储）
  // ──────────────────────────────────────────────
  Future<void> _saveServers(List<ServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();

    // 密码存入安全存储，JSON 中不存密码
    for (final server in servers) {
      if (server.password.isNotEmpty) {
        await _secureStorage.write(
          key: '$_storagePrefix${server.id}',
          value: server.password,
        );
      }
    }

    // 只存脱敏数据
    final jsonList = servers.map((s) {
      final json = s.toJson();
      json.remove('password');
      return json;
    }).toList();

    await prefs.setString(_keyServers, jsonEncode(jsonList));
  }

  // ──────────────────────────────────────────────
  // 添加服务器
  // ──────────────────────────────────────────────
  Future<void> addServer(ServerConfig server) async {
    final servers = await getServers();
    servers.add(server);
    await _saveServers(servers);
  }

  // ──────────────────────────────────────────────
  // 更新服务器
  // ──────────────────────────────────────────────
  Future<void> updateServer(ServerConfig updated) async {
    final servers = await getServers();
    final index = servers.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      servers[index] = updated;
      await _saveServers(servers);
    }
  }

  // ──────────────────────────────────────────────
  // 删除服务器
  // ──────────────────────────────────────────────
  Future<void> deleteServer(String id) async {
    final servers = await getServers();
    servers.removeWhere((s) => s.id == id);
    await _saveServers(servers);

    // 删除密码
    await _secureStorage.delete(key: '$_storagePrefix$id');
  }

  // ──────────────────────────────────────────────
  // 记住上次登录的服务器
  // ──────────────────────────────────────────────
  Future<void> setLastServerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastServerId, id);
  }

  Future<String?> getLastServerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastServerId);
  }
}
