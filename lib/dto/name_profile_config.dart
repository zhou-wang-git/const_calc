class NameProfileConfig {
  final int? id;
  final double grid;
  final double elements;
  final double coherence;
  final double harmony;
  final double phonetics;
  final double genderStyle;
  final double balance;
  final double zodiac;
  final double personality;
  final double calibration;

  NameProfileConfig({
    this.id,
    this.grid = 0.0,
    this.elements = 0.0,
    this.coherence = 0.0,
    this.harmony = 0.0,
    this.phonetics = 0.0,
    this.genderStyle = 0.0,
    this.balance = 0.0,
    this.zodiac = 0.0,
    this.personality = 0.0,
    this.calibration = 0.0,
  });

  /// 工具函数，保证安全转换 double
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// 从 Map 创建对象（数据库/本地存储）
  factory NameProfileConfig.fromMap(Map<String, dynamic> map) {
    return NameProfileConfig(
      id: map['id'] as int?,
      grid: _toDouble(map['grid']),
      elements: _toDouble(map['elements']),
      coherence: _toDouble(map['coherence']),
      harmony: _toDouble(map['harmony']),
      phonetics: _toDouble(map['phonetics']),
      genderStyle: _toDouble(map['genderStyle']),
      balance: _toDouble(map['balance']),
      zodiac: _toDouble(map['zodiac']),
      personality: _toDouble(map['personality']),
      calibration: _toDouble(map['calibration']),
    );
  }

  /// 从 JSON 创建对象（接口交互）
  factory NameProfileConfig.fromJson(Map<String, dynamic> json) {
    return NameProfileConfig.fromMap(json);
  }

  Map<String, double> toMap() {
    return {
      'grid': grid,
      'elements': elements,
      'coherence': coherence,
      'harmony': harmony,
      'phonetics': phonetics,
      'genderStyle': genderStyle,
      'balance': balance,
      'zodiac': zodiac,
      'personality': personality,
      'calibration': calibration,
    };
  }

  /// 转换为 JSON（适合接口交互）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grid': grid,
      'elements': elements,
      'coherence': coherence,
      'harmony': harmony,
      'phonetics': phonetics,
      'genderStyle': genderStyle,
      'balance': balance,
      'zodiac': zodiac,
      'personality': personality,
      'calibration': calibration,
    };
  }
}
