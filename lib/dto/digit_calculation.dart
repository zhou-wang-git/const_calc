class DigitCalculation {
  final String? id;

  DigitCalculation({this.id});

  /// 工厂构造：从 JSON 创建对象
  factory DigitCalculation.fromJson(Map<String, dynamic> json) {
    return DigitCalculation(
      id: json['id']?.toString(), // ✅ 安全访问 + 强制转 String
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '', // ✅ 空值处理，避免 null
    };
  }
}
