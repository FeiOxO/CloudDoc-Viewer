/// Alist 文件条目数据模型
class FileEntry {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime? modified;
  final String? contentType;

  FileEntry({
    required this.name,
    required this.path,
    required this.isDir,
    this.size = 0,
    this.modified,
    this.contentType,
  });

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isDir: json['is_dir'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      modified: json['modified'] != null
          ? DateTime.tryParse(json['modified'] as String)
          : null,
      contentType: json['contentType'] as String?,
    );
  }

  // 文件大小文本
  String get sizeText {
    if (isDir) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  bool get isMarkdown => name.endsWith('.md');
  bool get isImage =>
      name.endsWith('.png') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.webp') ||
      name.endsWith('.gif');
}
