class VipFee {
  final String name; // 套餐名称，比如 "1个月"
  final double price; // 价格
  final int vipTime; // 时长（天）
  final String describe; // 描述
  final int vipLevelId; // 会员等级 ID

  VipFee({
    required this.name,
    required this.price,
    required this.vipTime,
    required this.describe,
    required this.vipLevelId,
  });

  /// 从 JSON 转换
  factory VipFee.fromJson(Map<String, dynamic> json) {
    return VipFee(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      vipTime: json['vip_time'] ?? 0,
      describe: json['describe'] ?? '',
      vipLevelId: json['vip_level_id'] ?? 0,
    );
  }

  /// 转成 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'vip_time': vipTime,
      'describe': describe,
      'vip_level_id': vipLevelId,
    };
  }
}
