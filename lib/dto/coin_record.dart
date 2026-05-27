/// KCC Coin 积分记录
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? defaultValue;
}

class CoinRecord {
  final int id;
  final int userid;
  final int type;
  final int coins;
  final int balance;
  final String? orderSn;
  final String? relatedId;
  final String? remark;
  final int addTime;
  final String typeName;
  final String addTimeStr;

  CoinRecord({
    required this.id,
    required this.userid,
    required this.type,
    required this.coins,
    required this.balance,
    this.orderSn,
    this.relatedId,
    this.remark,
    required this.addTime,
    required this.typeName,
    required this.addTimeStr,
  });

  factory CoinRecord.fromJson(Map<String, dynamic> json) {
    return CoinRecord(
      id: _parseInt(json['id']),
      userid: _parseInt(json['userid']),
      type: _parseInt(json['type']),
      coins: _parseInt(json['coins']),
      balance: _parseInt(json['balance']),
      orderSn: json['order_sn']?.toString(),
      relatedId: json['related_id']?.toString(),
      remark: json['remark']?.toString(),
      addTime: _parseInt(json['add_time']),
      typeName: json['type_name'] ?? '未知',
      addTimeStr: json['add_time_str'] ?? '',
    );
  }

  /// 是否是增加积分
  bool get isIncome => coins > 0;

  /// 格式化积分数（带符号）
  String get coinsFormatted => isIncome ? '+$coins' : '$coins';
}

/// 积分记录分页结果
class CoinRecordPage {
  final List<CoinRecord> list;
  final int total;
  final int page;
  final int pageSize;

  CoinRecordPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory CoinRecordPage.fromJson(Map<String, dynamic> json) {
    return CoinRecordPage(
      list: (json['list'] as List<dynamic>?)
              ?.map((e) => CoinRecord.fromJson(e))
              .toList() ??
          [],
      total: _parseInt(json['total']),
      page: _parseInt(json['page'], defaultValue: 1),
      pageSize: _parseInt(json['page_size'], defaultValue: 20),
    );
  }

  /// 是否还有更多数据
  bool get hasMore => list.length < total;
}
