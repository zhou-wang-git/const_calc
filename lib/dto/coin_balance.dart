/// KCC Coin 积分余额信息
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? defaultValue;
}

bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return defaultValue;
}

class CoinBalance {
  final int coins;
  final int isSuper;
  final String? superType;
  final bool isLifetime;
  final bool shouldCharge;
  final int vipLevelId;

  CoinBalance({
    required this.coins,
    required this.isSuper,
    this.superType,
    required this.isLifetime,
    required this.shouldCharge,
    required this.vipLevelId,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      coins: _parseInt(json['coins']),
      isSuper: _parseInt(json['is_super']),
      superType: json['super_type']?.toString(),
      isLifetime: _parseBool(json['is_lifetime']),
      shouldCharge: _parseBool(json['should_charge'], defaultValue: true),
      vipLevelId: _parseInt(json['vip_level_id']),
    );
  }

  /// 是否是超级用户
  bool get isSuperUser => isSuper == 1;

  /// 是否免费使用（仅超级用户）
  bool get isFreeUser => isSuperUser;

  /// 获取用户身份描述
  String get userTypeLabel {
    if (isSuperUser) {
      switch (superType) {
        case 'tester':
          return '测试用户';
        case 'boss':
          return '老板';
        case 'teacher':
          return '导师';
        default:
          return '超级用户';
      }
    }
    switch (vipLevelId) {
      case 3:
        return '至尊会员';
      case 2:
        return '精英会员';
      default:
        return '基础用户';
    }
  }
}
