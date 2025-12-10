class MyFortune {
  final int id;
  final String realName;

  const MyFortune({
    required this.id,
    required this.realName,
  });

  factory MyFortune.fromJson(Map<String, dynamic> json) {
    return MyFortune(
      id: _toInt(json['id']),
      realName: (json['real_name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'real_name': realName,
    };
  }

  /// 兼容 id 可能为 int/string/num/bool/null 的情况
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();     // e.g. double
    if (v is bool) return v ? 1 : 0;
    if (v is String) {
      final s = v.trim();
      final i = int.tryParse(s);
      if (i != null) return i;
      // 兼容 "123.0" 这类
      final d = double.tryParse(s);
      if (d != null) return d.toInt();
      // 兜底：提取第一个整数片段（如 "id=42"）
      final m = RegExp(r'-?\d+').firstMatch(s);
      if (m != null) return int.tryParse(m.group(0)!) ?? 0;
    }
    return 0; // 其他未知类型兜底
  }
}
