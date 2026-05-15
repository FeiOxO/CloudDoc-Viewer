import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/server_status.dart';

/// 服务器状态 API 客户端
class StatusApi {
  // ──────────────────────────────────────────────
  // 获取服务器状态
  // ──────────────────────────────────────────────
  static Future<ServerStatus> fetchStatus(
      String host, int port) async {
    try {
      final url = Uri.parse('http://$host:$port/status');
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ServerStatus.fromJson(data);
      }
      return ServerStatus.offline();
    } catch (e) {
      return ServerStatus.offline();
    }
  }
}
