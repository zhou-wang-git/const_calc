import 'dart:convert';

class DigitCalculationNameResult {
  final String hanzi;         // 汉字
  final String py;            // 拼音
  final String wubi;          // 五笔
  final String bushou;        // 部首
  final int bihua;            // 笔画数
  final String bishun;        // 笔顺
  final String pyyb;          // 拼音音标
  final String content;       // 释义
  final String explain;       // 详细解释

  DigitCalculationNameResult({
    required this.hanzi,
    required this.py,
    required this.wubi,
    required this.bushou,
    required this.bihua,
    required this.bishun,
    required this.pyyb,
    required this.content,
    required this.explain,
  });

  factory DigitCalculationNameResult.fromJson(Map<String, dynamic> json) {
    return DigitCalculationNameResult(
      hanzi: json['hanzi'] ?? '',
      py: json['py'] ?? '',
      wubi: json['wubi'] ?? '',
      bushou: json['bushou'] ?? '',
      bihua: json['bihua'] ?? 0,
      bishun: json['bishun'] ?? '',
      pyyb: json['pyyb'] ?? '',
      content: json['content'] ?? '',
      explain: json['explain'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hanzi': hanzi,
      'py': py,
      'wubi': wubi,
      'bushou': bushou,
      'bihua': bihua,
      'bishun': bishun,
      'pyyb': pyyb,
      'content': content,
      'explain': explain,
    };
  }


  // ✅ 顶层是数组
  static List<DigitCalculationNameResult>? listFromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr == '') {
      return null;
    }
    final root = json.decode(jsonStr);
    if (root is List) {
      return root
          .whereType<Map>() // 过滤非 map
          .map((e) => DigitCalculationNameResult.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList();
    }

    throw const FormatException('Expected a JSON array at root.');
  }

}

