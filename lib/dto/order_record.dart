/// 消费记录模型（安全解析版）
class OrderRecord {
  final int id;
  final int userid;
  final String originalAmount;
  final String amount;
  final int vipLevelId;
  final int vipTime;
  final String vipName;
  final String vipDate;
  final String orderSn;
  final String orderName;
  final String email;
  final String name;
  final int payStatus;
  final String payTime;
  final int source;
  final String remark;
  final String addTime;
  final String nickname;

  const OrderRecord({
    required this.id,
    required this.userid,
    required this.originalAmount,
    required this.amount,
    required this.vipLevelId,
    required this.vipTime,
    required this.vipName,
    required this.vipDate,
    required this.orderSn,
    required this.orderName,
    required this.email,
    required this.name,
    required this.payStatus,
    required this.payTime,
    required this.source,
    required this.remark,
    required this.addTime,
    required this.nickname,
  });

  /// 从 JSON 创建对象（安全版）
  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    return OrderRecord(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userid: int.tryParse(json['userid']?.toString() ?? '') ?? 0,
      originalAmount: json['original_amount']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      vipLevelId: int.tryParse(json['vip_level_id']?.toString() ?? '') ?? 0,
      vipTime: int.tryParse(json['vip_time']?.toString() ?? '') ?? 0,
      vipName: json['vip_name']?.toString() ?? '',
      vipDate: json['vip_date']?.toString() ?? '',
      orderSn: json['order_sn']?.toString() ?? '',
      orderName: json['order_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      payStatus: int.tryParse(json['pay_status']?.toString() ?? '') ?? 0,
      payTime: json['pay_time']?.toString() ?? '',
      source: int.tryParse(json['source']?.toString() ?? '') ?? 0,
      remark: json['remark']?.toString() ?? '',
      addTime: json['add_time']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userid': userid,
      'original_amount': originalAmount,
      'amount': amount,
      'vip_level_id': vipLevelId,
      'vip_time': vipTime,
      'vip_name': vipName,
      'vip_date': vipDate,
      'order_sn': orderSn,
      'order_name': orderName,
      'email': email,
      'name': name,
      'pay_status': payStatus,
      'pay_time': payTime,
      'source': source,
      'remark': remark,
      'add_time': addTime,
      'nickname': nickname,
    };
  }
}
