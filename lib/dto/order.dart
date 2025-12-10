class Order {
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
  final int payTime;
  final int source;
  final String remark;
  final int addTime;

  Order({
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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userid: json['userid'] ?? 0,
      originalAmount: json['original_amount']?.toString() ?? '0.00',
      amount: json['amount']?.toString() ?? '0.00',
      vipLevelId: json['vip_level_id'] ?? 0,
      vipTime: json['vip_time'] ?? 0,
      vipName: json['vip_name'] ?? '',
      vipDate: json['vip_date'] ?? '',
      orderSn: json['order_sn'] ?? '',
      orderName: json['order_name'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      payStatus: json['pay_status'] ?? 0,
      payTime: json['pay_time'] ?? 0,
      source: json['source'] ?? 0,
      remark: json['remark'] ?? '',
      addTime: json['add_time'] ?? 0,
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
    };
  }
}
