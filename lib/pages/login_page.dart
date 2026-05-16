import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../services/alist_api.dart';
import '../services/server_manager.dart';
import 'server_detail_page.dart';

/// 服务器登录页
class LoginPage extends StatefulWidget {
  final ServerConfig server;

  const LoginPage({super.key, required this.server});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordCtrl = TextEditingController();
  final _alistApi = AlistApi();
  final _manager = ServerManager();
  bool _logging = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.text = widget.server.password;
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _logging = true;
      _error = null;
    });

    // 更新密码（可能用户手动输入了新密码）
    final server = widget.server.copyWith(password: _passwordCtrl.text);
    await _manager.updateServer(server);

    final success = await _alistApi.login(server);
    await _manager.setLastServerId(server.id);

    if (!mounted) return;

    setState(() => _logging = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ServerDetailPage(
            server: server,
            alistApi: _alistApi,
          ),
        ),
      );
    } else {
      setState(() => _error = '登录失败，请检查服务器地址和密码');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 服务器图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cloud, size: 48, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              widget.server.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.server.host,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 32),

            // 密码输入
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Alist 密码',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
            const SizedBox(height: 24),

            // 登录按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _logging ? null : _login,
                icon: _logging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_logging ? '登录中...' : '连接服务器'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
