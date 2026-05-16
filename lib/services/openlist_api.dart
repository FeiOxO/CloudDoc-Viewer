import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_entry.dart';
import '../models/server_config.dart';

/// OpenList REST API 客户端
class OpenListApi {
  String? _token;
  ServerConfig? _server;

  OpenListApi();

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ──────────────────────────────────────────────
  // 登录（获取 token）
  // ──────────────────────────────────────────────
  Future<bool> login(ServerConfig server) async {
    _server = server;
    _token = null;

    try {
      final url = Uri.parse('${server.baseUrl}/api/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': server.username,
              'password': server.password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          _token = data['data']['token'] as String;
          return true;
        }
      }
      return false;
    } catch (e) {
      _token = null;
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // 获取目录列表
  // ──────────────────────────────────────────────
  Future<List<FileEntry>> listFiles(String path) async {
    if (_server == null || _token == null) throw Exception('未登录');

    try {
      final url = Uri.parse('${_server!.baseUrl}/api/fs/list');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _token!,
            },
            body: jsonEncode({
              'path': path,
              'page': 1,
              'per_page': 0, // 全部
              'refresh': false,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List<dynamic> items = data['data']['content'] ?? [];
          return items.map((e) => FileEntry.fromJson(e)).toList();
        }
      }
      throw Exception('获取文件列表失败');
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  // 获取签名后的文件直链
  // ──────────────────────────────────────────────
  Future<String> _getSignedUrl(String path) async {
    final url = Uri.parse('${_server!.baseUrl}/api/fs/get');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': _token!,
          },
          body: jsonEncode({'path': path}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200) {
        final rawUrl = data['data']['raw_url'] as String?;
        if (rawUrl != null && rawUrl.isNotEmpty) {
          return '${_server!.baseUrl}$rawUrl';
        }
      }
    }
    throw Exception('获取文件直链失败');
  }

  // ──────────────────────────────────────────────
  // 获取文件内容（适用于 .md 等文本文件）
  // ──────────────────────────────────────────────
  Future<String> getFileContent(String path) async {
    if (_server == null || _token == null) throw Exception('未登录');

    try {
      final signedUrl = await _getSignedUrl(path);
      final response = await http
          .get(Uri.parse(signedUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception('获取文件内容失败');
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  // 获取文件 RAW URL（用于图片等）
  // ──────────────────────────────────────────────
  String getRawUrl(String path) {
    if (_server == null) return '';
    return '${_server!.baseUrl}/d$path';
  }

  // ──────────────────────────────────────────────
  // 获取图片 bytes
  // ──────────────────────────────────────────────
  Future<List<int>> getImageBytes(String path) async {
    if (_server == null || _token == null) throw Exception('未登录');
    try {
      final signedUrl = await _getSignedUrl(path);
      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('获取图片失败');
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  // 登出
  // ──────────────────────────────────────────────
  void logout() {
    _token = null;
    _server = null;
  }
}
