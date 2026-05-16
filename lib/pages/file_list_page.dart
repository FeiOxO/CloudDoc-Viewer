import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/file_entry.dart';
import '../services/openlist_api.dart';
import 'markdown_viewer_page.dart';

/// 文件浏览页面
class FileListPage extends StatefulWidget {
  final OpenListApi openListApi;

  const FileListPage({super.key, required this.openListApi});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  final List<String> _pathHistory = ['/'];
  List<FileEntry> _files = [];
  bool _loading = true;
  String? _error;

  String get _currentPath => _pathHistory.last;

  @override
  void initState() {
    super.initState();
    _loadFiles('/');
  }

  Future<void> _loadFiles(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final files = await widget.openListApi.listFiles(path);
      // 排序：目录在前，文件在后
      files.sort((a, b) {
        if (a.isDir && !b.isDir) return -1;
        if (!a.isDir && b.isDir) return 1;
        return a.name.compareTo(b.name);
      });

      if (mounted) {
        setState(() {
          _files = files;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _loading = false;
        });
      }
    }
  }

  String _joinPath(String name) {
    if (_currentPath == '/') return '/$name';
    return '$_currentPath/$name';
  }

  void _enterDir(FileEntry entry) {
    final dirPath = _joinPath(entry.name);
    _pathHistory.add(dirPath);
    _loadFiles(dirPath);
  }

  void _goBack() {
    if (_pathHistory.length > 1) {
      _pathHistory.removeLast();
      _loadFiles(_currentPath);
    }
  }

  void _openFile(FileEntry entry) async {
    if (entry.isMarkdown) {
      try {
        final content = await widget.openListApi.getFileContent(_joinPath(entry.name));
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarkdownViewerPage(
                title: entry.name,
                content: content,
                openListApi: widget.openListApi,
                basePath: _currentPath,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 路径导航
        _buildPathBar(),
        // 文件列表
        Expanded(
          child: _loading
              ? _buildShimmer()
              : _error != null
                  ? _buildError()
                  : _files.isEmpty
                      ? _buildEmpty()
                      : _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildPathBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (_pathHistory.length > 1)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (_pathHistory.length > 1) const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbs(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _loadFiles(_currentPath),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbs() {
    final parts = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final crumbs = <Widget>[];

    // 根目录
    crumbs.add(
      GestureDetector(
        onTap: () {
          _pathHistory.clear();
          _pathHistory.add('/');
          _loadFiles('/');
        },
        child: const Icon(Icons.home, size: 16),
      ),
    );

    // 逐级路径
    for (int i = 0; i < parts.length; i++) {
      crumbs.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.chevron_right, size: 14, color: Colors.grey),
      ));
      final path = '/${parts.sublist(0, i + 1).join('/')}';
      crumbs.add(
        GestureDetector(
          onTap: () {
            // 跳转到该级目录
            final idx = _pathHistory.indexOf(path);
            if (idx != -1) {
              _pathHistory.removeRange(idx + 1, _pathHistory.length);
              _loadFiles(path);
            }
          },
          child: Text(
            parts[i],
            style: TextStyle(
              fontSize: 13,
              color: i == parts.length - 1 ? Colors.blue : Colors.grey[700],
              fontWeight: i == parts.length - 1 ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return crumbs;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Container(
            height: 14,
            width: 150,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 10,
            width: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _loadFiles(_currentPath),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('该目录为空', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return RefreshIndicator(
      onRefresh: () => _loadFiles(_currentPath),
      child: ListView.separated(
        itemCount: _files.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final entry = _files[index];
          return _buildFileTile(entry);
        },
      ),
    );
  }

  Widget _buildFileTile(FileEntry entry) {
    IconData icon;
    Color iconColor;

    if (entry.isDir) {
      icon = Icons.folder;
      iconColor = Colors.amber[700]!;
    } else if (entry.isMarkdown) {
      icon = Icons.description;
      iconColor = Colors.blue;
    } else if (entry.isImage) {
      icon = Icons.image;
      iconColor = Colors.green;
    } else {
      icon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        entry.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: entry.isDir
          ? null
          : Text(
              entry.sizeText,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
      trailing: entry.isDir
          ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
          : null,
      onTap: () {
        if (entry.isDir) {
          _enterDir(entry);
        } else if (entry.isMarkdown) {
          _openFile(entry);
        }
      },
    );
  }
}
