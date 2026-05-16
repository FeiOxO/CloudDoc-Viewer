import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/openlist_api.dart';

/// Markdown 文件阅读器（使用 HTML 渲染引擎）
/// 支持标准 HTML / Markdown 混合内容
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
    final isDark = _darkMode;
    final textColor = isDark ? Colors.grey[300]! : Colors.black87;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

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
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _darkMode = !_darkMode),
            tooltip: '切换主题',
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: _copyContent,
            tooltip: '复制全文',
          ),
        ],
      ),
      body: Container(
        color: bgColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: HtmlWidget(
            _content,
            textStyle: TextStyle(
              fontSize: 15,
              color: textColor,
              height: 1.6,
            ),
            customStylesBuilder: (element) {
              return _buildElementStyles(element, isDark);
            },
            onTapUrl: (url) async {
              // 可以添加链接处理逻辑
              return false;
            },
          ),
        ),
      ),
    );
  }

  Map<String, String>? _buildElementStyles(element, bool isDark) {
    final tag = element.localName;

    switch (tag) {
      case 'h1':
        return {
          'font-size': '24px',
          'font-weight': 'bold',
          'color': isDark ? '#FFFFFF' : '#000000',
          'margin': '20px 0 10px 0',
          'padding': '0',
        };
      case 'h2':
        return {
          'font-size': '20px',
          'font-weight': 'bold',
          'color': isDark ? '#FFFFFF' : '#000000',
          'margin': '18px 0 8px 0',
          'padding': '0 0 4px 0',
          'border-bottom': isDark ? '1px solid #424242' : '1px solid #E0E0E0',
        };
      case 'h3':
        return {
          'font-size': '17px',
          'font-weight': 'bold',
          'color': isDark ? '#FFFFFF' : '#000000',
          'margin': '14px 0 6px 0',
          'padding': '0',
        };

      // ——— 代码块 ———
      case 'pre':
        return {
          'background-color': isDark ? '#2D2D3F' : '#F5F5F5',
          'padding': '12px',
          'border-radius': '8px',
          'overflow-x': 'auto',
          'margin': '8px 0',
        };
      case 'code':
        // 内联代码（不在 <pre> 里）
        if (element.parent?.localName != 'pre') {
          return {
            'font-size': '13px',
            'background-color': isDark ? '#2D2D3F' : '#EEEEEE',
            'color': isDark ? '#A5D6A7' : '#E65100',
            'padding': '2px 6px',
            'border-radius': '4px',
            'font-family': 'monospace',
          };
        }
        // <pre><code> 里的代码
        return {
          'font-size': '13px',
          'font-family': 'monospace',
          'color': isDark ? '#E0E0E0' : '#212121',
          'line-height': '1.5',
          'white-space': 'pre',
        };

      // ——— 引用 ———
      case 'blockquote':
        return {
          'border-left': isDark ? '4px solid #64B5F6' : '4px solid #2196F3',
          'background-color':
              isDark ? 'rgba(33,150,243,0.1)' : 'rgba(33,150,243,0.05)',
          'padding': '8px 12px',
          'margin': '8px 0',
          'border-radius': '0 4px 4px 0',
        };

      // ——— 表格 ———
      case 'table':
        return {
          'border-collapse': 'collapse',
          'width': '100%',
          'margin': '8px 0',
          'font-size': '14px',
        };
      case 'th':
        return {
          'font-weight': 'bold',
          'padding': '8px 10px',
          'border':
              '1px solid ${isDark ? "#424242" : "#E0E0E0"}',
          'background-color': isDark ? '#2D2D3F' : '#F5F5F5',
          'text-align': 'left',
        };
      case 'td':
        return {
          'padding': '8px 10px',
          'border': '1px solid ${isDark ? "#424242" : "#E0E0E0"}',
        };

      // ——— 分割线 ———
      case 'hr':
        return {
          'margin': '16px 0',
          'border': 'none',
          'border-top':
              '1px solid ${isDark ? "#424242" : "#E0E0E0"}',
        };

      // ——— 列表 ———
      case 'ul':
        return {
          'margin': '6px 0',
          'padding-left': '20px',
        };
      case 'ol':
        return {
          'margin': '6px 0',
          'padding-left': '20px',
        };
      case 'li':
        return {
          'margin': '3px 0',
        };

      // ——— 链接 ———
      case 'a':
        return {
          'color': isDark ? '#64B5F6' : '#1565C0',
          'text-decoration': 'none',
        };

      // ——— 图片 ———
      case 'img':
        // 如果是相对路径，拼接 OpenList 的原始地址
        final src = element.attributes['src'];
        if (src != null && !src.startsWith('http')) {
          final basePath = widget.basePath ?? '';
          element.attributes['src'] = '$basePath/$src';
        }
        return {
          'max-width': '100%',
          'border-radius': '4px',
          'margin': '8px 0',
        };

      default:
        return null;
    }
  }

  void _copyContent() {
    // 复制到剪贴板（后续可扩展）
  }
}
