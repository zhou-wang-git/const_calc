/// 奇门遁甲吉时出行结果模型
class QimenResult {
  final String luck; // 吉/凶
  final String description; // 详细描述
  final String descriptionQimen; // 奇门出行录说明
  final String yi; // 宜（适宜做的事）
  final String ji; // 忌（不适宜做的事）

  // 太元
  final String a1Taiyuan;
  final String a2; // 润下水
  final String a3Taixi; // 胎息
  final String a4Minggong; // 命宫

  // 时柱
  final String b1TimeShishen; // 时神
  final String b2TimeTiangan; // 时天干
  final String b3TimeDizhi; // 时地支
  final String b21Zhanggan; // 藏干1
  final String b31Zhanggan; // 藏干2
  final String b41Zhanggan; // 藏干3
  final String b22Zhanggan; // 十神1
  final String b32Zhanggan; // 十神2
  final String b42Zhanggan; // 十神3
  final String b31Yun; // 运
  final String b32Nayin; // 纳音
  final String b33Kongwang; // 空亡
  final List<String> b4Shensha; // 神煞数组

  // 日柱
  final String c2DayTiangan; // 日天干
  final String c3DayDizhi; // 日地支
  final String c21Zhanggan;
  final String c31Zhanggan;
  final String c41Zhanggan;
  final String c22Zhanggan;
  final String c32Zhanggan;
  final String c42Zhanggan;
  final String c31Yun;
  final String c32Nayin;
  final String c33Kongwang;
  final List<String> c4Shensha;

  // 月柱
  final String d1MonthShishen; // 月神
  final String d2MonthTiangan; // 月天干
  final String d3MonthDizhi; // 月地支
  final String d21Zhanggan;
  final String d31Zhanggan;
  final String d41Zhanggan;
  final String d22Zhanggan;
  final String d32Zhanggan;
  final String d42Zhanggan;
  final String d31Yun;
  final String d32Nayin;
  final String d33Kongwang;
  final List<String> d4Shensha;

  // 年柱
  final String e1YearShishen; // 年神
  final String e2YearTiangan; // 年天干
  final String e3YearDizhi; // 年地支
  final String e21Zhanggan;
  final String e31Zhanggan;
  final String e41Zhanggan;
  final String e22Zhanggan;
  final String e32Zhanggan;
  final String e42Zhanggan;
  final String e31Yun;
  final String e32Nayin;
  final String e33Kongwang;
  final List<String> e4Shensha;

  QimenResult({
    required this.luck,
    required this.description,
    required this.descriptionQimen,
    required this.yi,
    required this.ji,
    required this.a1Taiyuan,
    required this.a2,
    required this.a3Taixi,
    required this.a4Minggong,
    required this.b1TimeShishen,
    required this.b2TimeTiangan,
    required this.b3TimeDizhi,
    required this.b21Zhanggan,
    required this.b31Zhanggan,
    required this.b41Zhanggan,
    required this.b22Zhanggan,
    required this.b32Zhanggan,
    required this.b42Zhanggan,
    required this.b31Yun,
    required this.b32Nayin,
    required this.b33Kongwang,
    required this.b4Shensha,
    required this.c2DayTiangan,
    required this.c3DayDizhi,
    required this.c21Zhanggan,
    required this.c31Zhanggan,
    required this.c41Zhanggan,
    required this.c22Zhanggan,
    required this.c32Zhanggan,
    required this.c42Zhanggan,
    required this.c31Yun,
    required this.c32Nayin,
    required this.c33Kongwang,
    required this.c4Shensha,
    required this.d1MonthShishen,
    required this.d2MonthTiangan,
    required this.d3MonthDizhi,
    required this.d21Zhanggan,
    required this.d31Zhanggan,
    required this.d41Zhanggan,
    required this.d22Zhanggan,
    required this.d32Zhanggan,
    required this.d42Zhanggan,
    required this.d31Yun,
    required this.d32Nayin,
    required this.d33Kongwang,
    required this.d4Shensha,
    required this.e1YearShishen,
    required this.e2YearTiangan,
    required this.e3YearDizhi,
    required this.e21Zhanggan,
    required this.e31Zhanggan,
    required this.e41Zhanggan,
    required this.e22Zhanggan,
    required this.e32Zhanggan,
    required this.e42Zhanggan,
    required this.e31Yun,
    required this.e32Nayin,
    required this.e33Kongwang,
    required this.e4Shensha,
  });

  factory QimenResult.fromJson(Map<String, dynamic> json) {
    return QimenResult(
      luck: json['luck'] ?? '',
      description: json['description'] ?? '',
      descriptionQimen: json['description_qimen'] ?? '',
      yi: json['yi'] ?? '',
      ji: json['ji'] ?? '',
      a1Taiyuan: json['a1_taiyuan'] ?? '',
      a2: json['a2'] ?? '',
      a3Taixi: json['a3_taixi'] ?? '',
      a4Minggong: json['a4_minggong'] ?? '',
      b1TimeShishen: json['b1_time_shishen'] ?? '',
      b2TimeTiangan: json['b2_time_tiangan'] ?? '',
      b3TimeDizhi: json['b3_time_dizhi'] ?? '',
      b21Zhanggan: json['b2_1_zhanggan'] ?? '',
      b31Zhanggan: json['b3_1_zhanggan'] ?? '',
      b41Zhanggan: json['b4_1_zhanggan'] ?? '',
      b22Zhanggan: json['b2_2_zhanggan'] ?? '',
      b32Zhanggan: json['b3_2_zhanggan'] ?? '',
      b42Zhanggan: json['b4_2_zhanggan'] ?? '',
      b31Yun: json['b3_1_yun'] ?? '',
      b32Nayin: json['b3_2_nayin'] ?? '',
      b33Kongwang: json['b3_3_kongwang'] ?? '',
      b4Shensha: _parseShensha(json['b4_shensha']),
      c2DayTiangan: json['c2_day_tiangan'] ?? '',
      c3DayDizhi: json['c3_day_dizhi'] ?? '',
      c21Zhanggan: json['c2_1_zhanggan'] ?? '',
      c31Zhanggan: json['c3_1_zhanggan'] ?? '',
      c41Zhanggan: json['c4_1_zhanggan'] ?? '',
      c22Zhanggan: json['c2_2_zhanggan'] ?? '',
      c32Zhanggan: json['c3_2_zhanggan'] ?? '',
      c42Zhanggan: json['c4_2_zhanggan'] ?? '',
      c31Yun: json['c3_1_yun'] ?? '',
      c32Nayin: json['c3_2_nayin'] ?? '',
      c33Kongwang: json['c3_3_kongwang'] ?? '',
      c4Shensha: _parseShensha(json['c4_shensha']),
      d1MonthShishen: json['d1_month_shishen'] ?? '',
      d2MonthTiangan: json['d2_month_tiangan'] ?? '',
      d3MonthDizhi: json['d3_month_dizhi'] ?? '',
      d21Zhanggan: json['d2_1_zhanggan'] ?? '',
      d31Zhanggan: json['d3_1_zhanggan'] ?? '',
      d41Zhanggan: json['d4_1_zhanggan'] ?? '',
      d22Zhanggan: json['d2_2_zhanggan'] ?? '',
      d32Zhanggan: json['d3_2_zhanggan'] ?? '',
      d42Zhanggan: json['d4_2_zhanggan'] ?? '',
      d31Yun: json['d3_1_yun'] ?? '',
      d32Nayin: json['d3_2_nayin'] ?? '',
      d33Kongwang: json['d3_3_kongwang'] ?? '',
      d4Shensha: _parseShensha(json['d4_shensha']),
      e1YearShishen: json['e1_year_shishen'] ?? '',
      e2YearTiangan: json['e2_year_tiangan'] ?? '',
      e3YearDizhi: json['e3_year_dizhi'] ?? '',
      e21Zhanggan: json['e2_1_zhanggan'] ?? '',
      e31Zhanggan: json['e3_1_zhanggan'] ?? '',
      e41Zhanggan: json['e4_1_zhanggan'] ?? '',
      e22Zhanggan: json['e2_2_zhanggan'] ?? '',
      e32Zhanggan: json['e3_2_zhanggan'] ?? '',
      e42Zhanggan: json['e4_2_zhanggan'] ?? '',
      e31Yun: json['e3_1_yun'] ?? '',
      e32Nayin: json['e3_2_nayin'] ?? '',
      e33Kongwang: json['e3_3_kongwang'] ?? '',
      e4Shensha: _parseShensha(json['e4_shensha']),
    );
  }

  /// 解析神煞数组（处理 null 和非空字符串）
  static List<String> _parseShensha(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .where((item) => item != null && item.toString().isNotEmpty)
        .map((item) => item.toString())
        .toList();
  }
}

/// 六壬占卜结果模型
class LiurenResult {
  final String luck; // 吉/凶
  final String description; // 详细描述

  LiurenResult({
    required this.luck,
    required this.description,
  });

  factory LiurenResult.fromJson(Map<String, dynamic> json) {
    return LiurenResult(
      luck: json['luck'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

/// 配额信息模型
class QuotaInfo {
  final int remaining; // 剩余次数
  final int limit; // 总限制
  final bool isVip; // 是否 VIP

  QuotaInfo({
    required this.remaining,
    required this.limit,
    required this.isVip,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      remaining: json['remaining'] ?? 0,
      limit: json['limit'] ?? 10,
      isVip: json['isVip'] ?? false,
    );
  }
}
