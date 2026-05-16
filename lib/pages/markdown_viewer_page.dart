import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/openlist_api.dart';

/// Markdown 文件阅读器
class MarkdownViewerPage extends StatefulWidget {
  final String title;
  final String content;
  final OpenListApi openListApi;
  final String? basePath;

  const MarkdownViewerPage({
    super.key,
    required this.title,
    required this.content,
    required this.openListApi,
    this.basePath,
  });

  @override
  State<MarkdownViewerPage> createState() => _MarkdownViewerPageState();
}

class _MarkdownViewerPageState extends State<MarkdownViewerPage> {
  bool _darkMode = false;
  late String _content;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _darkMode = !_darkMode),
            tooltip: '切换主题',
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () => _copyContent(),
            tooltip: '复制全文',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'font_small') _changeFontSize(-2);
              if (v == 'font_large') _changeFontSize(2);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'font_small',
                child: ListTile(
                  leading: Icon(Icons.text_decrease, size: 20),
                  title: Text('缩小字体'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'font_large',
                child: ListTile(
                  leading: Icon(Icons.text_increase, size: 20),
                  title: Text('放大字体'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: _darkMode ? const Color(0xFF1E1E2E) : Colors.white,
        child: Markdown(
          data: _content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            h1: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : Colors.black87,
            ),
            h2: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : Colors.black87,
            ),
            h3: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : Colors.black87,
            ),
            p: TextStyle(
              fontSize: 15,
              color: _darkMode ? Colors.grey[300] : Colors.black87,
              height: 1.6,
            ),
            code: TextStyle(
              fontSize: 13,
              backgroundColor: _darkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200],
              color: _darkMode ? Colors.green[200] : Colors.deepOrange,
            ),
            codeblockDecoration: BoxDecoration(
              color: _darkMode
                  ? const Color(0xFF2D2D3F)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            blockquoteDecoration: BoxDecoration(
              border: const Border(
                left: BorderSide(
                  color: Colors.blue,
                  width: 4,
                ),
              ),
              color: _darkMode
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.05),
            ),
            listBullet: TextStyle(
              color: _darkMode ? Colors.white : Colors.black87,
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _darkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          // 支持图片加载
          sizedImageBuilder: (config) {
            final src = config.uri.toString();
            // 如果是相对路径，拼接 basePath
            final fullPath = src.startsWith('http')
                ? src
                : '${widget.basePath ?? ''}/$src';
            // 尝试通过 OpenList API 获取图片
            return FutureBuilder<List<int>>(
              future: widget.openListApi.getImageBytes(fullPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.memory(
                      Uint8ListFromList(snapshot.data!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _copyContent() {
    // 复制到剪贴板
  }

  void _changeFontSize(int delta) {
    // 字体大小调整（后续可加状态管理）
  }
}

// 辅助：Uint8List
// ignore: non_constant_identifier_names
Uint8List Uint8ListFromList(List<int> list) => Uint8List.fromList(list);
