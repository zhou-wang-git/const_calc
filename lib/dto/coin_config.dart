/// KCC Coin 积分配置
class CoinConfig {
  final List<RechargePackage> rechargePackages;
  final Map<String, int> memberCoins;
  final Map<String, int> functionCosts;
  final int newUserCoins;
  final int dailySignCoins;
  final int inviteCoins;
  final double supremeDiscount;

  CoinConfig({
    required this.rechargePackages,
    required this.memberCoins,
    required this.functionCosts,
    required this.newUserCoins,
    required this.dailySignCoins,
    required this.inviteCoins,
    required this.supremeDiscount,
  });

  factory CoinConfig.fromJson(Map<String, dynamic> json) {
    // 解析充值套餐
    List<RechargePackage> packages = [];
    if (json['recharge_packages'] is List) {
      packages = (json['recharge_packages'] as List)
          .map((e) => RechargePackage.fromJson(e))
          .toList();
    }

    // 解析会员赠送积分配置
    Map<String, int> memberCoins = {};
    if (json['member_coins'] is Map) {
      (json['member_coins'] as Map).forEach((key, value) {
        memberCoins[key.toString()] =
            value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    // 解析功能消耗配置
    Map<String, int> functionCosts = {};
    if (json['function_costs'] is Map) {
      (json['function_costs'] as Map).forEach((key, value) {
        functionCosts[key.toString()] =
            value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return CoinConfig(
      rechargePackages: packages,
      memberCoins: memberCoins,
      functionCosts: functionCosts,
      newUserCoins: _parseIntValue(json['new_user_coins']),
      dailySignCoins: _parseIntValue(json['daily_sign_coins']),
      inviteCoins: _parseIntValue(json['invite_coins']),
      supremeDiscount: _parseDoubleValue(json['supreme_discount']),
    );
  }

  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 1.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 1.0;
  }

  /// 获取功能消耗积分
  int getFunctionCost(String functionId) {
    return functionCosts[functionId] ?? functionCosts['default'] ?? 10;
  }
}

/// 充值套餐
class RechargePackage {
  final int id;
  final double price;
  final int coins;
  final String name;
  final String? iosProductId; // iOS IAP 商品ID
  final String? androidProductId; // Android IAP 商品ID

  RechargePackage({
    required this.id,
    required this.price,
    required this.coins,
    required this.name,
    this.iosProductId,
    this.androidProductId,
  });

  factory RechargePackage.fromJson(Map<String, dynamic> json) {
    return RechargePackage(
      id: CoinConfig._parseIntValue(json['id']),
      price: CoinConfig._parseDoubleValue(json['price']),
      coins: CoinConfig._parseIntValue(json['coins']),
      name: json['name']?.toString() ?? '',
      iosProductId: json['ios_product_id']?.toString(),
      androidProductId: json['android_product_id']?.toString(),
    );
  }

  /// 格式化价格
  String get priceFormatted => '\$${price.toStringAsFixed(2)}';

  /// 单价（每积分多少钱）
  double get pricePerCoin => coins > 0 ? price / coins : 0;
}
