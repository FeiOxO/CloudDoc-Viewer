import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/server_config.dart';
import '../services/server_manager.dart';

/// 添加/编辑服务器页面
class AddServerPage extends StatefulWidget {
  final ServerConfig? editServer;

  const AddServerPage({super.key, this.editServer});

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _statusPortCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _enableStatus = true;
  bool _showPassword = false;
  bool _saving = false;

  bool get _isEditing => widget.editServer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.editServer!;
      _nameCtrl.text = s.name;
      _hostCtrl.text = s.host;
      _portCtrl.text = s.port.toString();
      _statusPortCtrl.text = s.statusPort.toString();
      _usernameCtrl.text = s.username;
      _passwordCtrl.text = s.password;
      _noteCtrl.text = s.note ?? '';
      _enableStatus = s.enableStatus;
    } else {
      _portCtrl.text = '5244';
      _statusPortCtrl.text = '3001';
      _usernameCtrl.text = 'admin';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _statusPortCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final manager = ServerManager();
    final server = ServerConfig(
      id: _isEditing ? widget.editServer!.id : const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      host: _hostCtrl.text.trim(),
      port: int.parse(_portCtrl.text.trim()),
      statusPort: int.parse(_statusPortCtrl.text.trim()),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      note: _noteCtrl.text.trim(),
      enableStatus: _enableStatus,
      createdAt: _isEditing ? widget.editServer!.createdAt : null,
    );

    if (_isEditing) {
      await manager.updateServer(server);
    } else {
      await manager.addServer(server);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑服务器' : '添加服务器'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── 基本信息 ──
            _sectionTitle('基本信息'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDec('服务器名称', '如：阿里云、腾讯云'),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hostCtrl,
              decoration: _inputDec('服务器地址 / IP', '如：123.45.67.89'),
              keyboardType: TextInputType.url,
              validator: (v) => v == null || v.trim().isEmpty ? '请输入地址' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _portCtrl,
                    decoration: _inputDec('Alist 端口'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '必填';
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 65535) return '无效端口';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _statusPortCtrl,
                    decoration: _inputDec('状态端口'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '必填';
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 65535) return '无效端口';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 登录信息 ──
            _sectionTitle('Alist 登录信息'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameCtrl,
              decoration: _inputDec('用户名', '默认 admin'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              decoration: _inputDec(
                '密码',
                null,
                suffix: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? '请输入密码' : null,
            ),

            const SizedBox(height: 24),

            // ── 其他设置 ──
            _sectionTitle('其他设置'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              decoration: _inputDec('备注（可选）', '如：跑 Hermes 的服务器'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('启用服务器状态监控'),
              subtitle: const Text('需要安装状态 API'),
              value: _enableStatus,
              onChanged: (v) => setState(() => _enableStatus = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),

            // ── 保存按钮 ──
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? '保存修改' : '添加服务器',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDec(String label, [String? hint, {Widget? suffix}]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
