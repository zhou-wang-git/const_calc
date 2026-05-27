import 'package:flutter/foundation.dart';

import '../dto/coin_balance.dart';
import '../dto/coin_config.dart';
import '../dto/coin_record.dart';
import 'auth_service.dart';
import 'http_service.dart';

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

/// KCC Coin 积分服务
class CoinService {
  static CoinBalance? _cachedBalance;
  static CoinConfig? _cachedConfig;

  /// 功能ID常量 - 与后端 function_costs 配置对应
  static const String funcDigitalCalc = 'digital_calc'; // 数字测算 - 3积分
  static const String funcNameCalc = 'name_calc'; // 姓名批算 - 5积分
  static const String funcTarotBasic = 'tarot_basic'; // 塔罗基础(1-5牌) - 3积分
  static const String funcTarotAdvanced = 'tarot_advanced'; // 塔罗进阶(7-10牌) - 8积分
  static const String funcLuckyTime = 'lucky_time'; // 吉时出行 - 1积分

  /// 获取积分余额
  static Future<CoinBalance> getBalance() async {
    final user = AuthService().loginUser;
    final userid = user?.userid ?? 0;
    final token = user?.token ?? '';

    // Debug logging
    debugPrint('🔍 CoinService.getBalance - userid: $userid, token: $token');

    final res = await HttpService.get<CoinBalance>(
      '/coin/balance?userid=$userid&token=$token',
      fromData: (data) => CoinBalance.fromJson(data),
    );

    _cachedBalance = res.data;
    return res.data!;
  }

  /// 获取缓存的余额
  static CoinBalance? getCachedBalance() => _cachedBalance;

  /// 获取积分记录
  static Future<CoinRecordPage> getRecords({
    int page = 1,
    int pageSize = 20,
    int type = 0,
  }) async {
    final user = AuthService().loginUser;
    final userid = user?.userid ?? 0;
    final token = user?.token ?? '';

    final res = await HttpService.get<CoinRecordPage>(
      '/coin/records?userid=$userid&token=$token&page=$page&page_size=$pageSize&type=$type',
      fromData: (data) => CoinRecordPage.fromJson(data),
    );

    return res.data!;
  }

  /// 获取积分配置
  static Future<CoinConfig> getConfig() async {
    final res = await HttpService.get<CoinConfig>(
      '/coin/config',
      fromData: (data) => CoinConfig.fromJson(data),
    );

    _cachedConfig = res.data;
    return res.data!;
  }

  /// 获取缓存的配置
  static CoinConfig? getCachedConfig() => _cachedConfig;

  /// 消费积分
  static Future<ConsumeResult> consume({
    required String functionId,
    required int coins,
  }) async {
    final user = AuthService().loginUser;
    final userid = user?.userid ?? 0;
    final token = user?.token ?? '';

    final res = await HttpService.postForm<ConsumeResult>(
      '/coin/consume',
      {
        'userid': userid.toString(),
        'token': token,
        'function_id': functionId,
        'coins': coins.toString(),
      },
      fromData: (data) => ConsumeResult.fromJson(data),
    );

    // 更新缓存的余额
    if (res.data != null) {
      _cachedBalance = CoinBalance(
        coins: res.data!.balance,
        isSuper: _cachedBalance?.isSuper ?? 0,
        superType: _cachedBalance?.superType,
        isLifetime: _cachedBalance?.isLifetime ?? false,
        shouldCharge: _cachedBalance?.shouldCharge ?? true,
        vipLevelId: _cachedBalance?.vipLevelId ?? 0,
      );
    }

    return res.data!;
  }

  /// 创建充值订单（调用外部支付接口）
  /// 返回支付信息，前端根据返回跳转支付页面
  static Future<RechargeOrderResult> createRechargeOrder({
    required int packageId,
  }) async {
    final user = AuthService().loginUser;
    final userid = user?.userid ?? 0;
    final token = user?.token ?? '';

    final res = await HttpService.postForm<RechargeOrderResult>(
      '/coin/createOrder',
      {
        'userid': userid.toString(),
        'token': token,
        'package_id': packageId.toString(),
      },
      fromData: (data) => RechargeOrderResult.fromJson(data),
    );

    return res.data!;
  }

  /// 查询充值订单状态
  static Future<RechargeOrderStatus> queryOrderStatus({
    required String orderSn,
  }) async {
    final user = AuthService().loginUser;
    final userid = user?.userid ?? 0;
    final token = user?.token ?? '';

    final res = await HttpService.get<RechargeOrderStatus>(
      '/coin/orderStatus?userid=$userid&token=$token&order_sn=$orderSn',
      fromData: (data) => RechargeOrderStatus.fromJson(data),
    );

    // 如果订单已完成，更新余额缓存
    if (res.data != null && res.data!.status == 'paid') {
      _cachedBalance = CoinBalance(
        coins: res.data!.balance ?? _cachedBalance?.coins ?? 0,
        isSuper: _cachedBalance?.isSuper ?? 0,
        superType: _cachedBalance?.superType,
        isLifetime: _cachedBalance?.isLifetime ?? false,
        shouldCharge: _cachedBalance?.shouldCharge ?? true,
        vipLevelId: _cachedBalance?.vipLevelId ?? 0,
      );
    }

    return res.data!;
  }

  /// IAP 收据验证并充值
  /// [platform] - 'ios' 或 'android'
  /// [receipt] - iOS: receipt-data, Android: purchaseToken
  /// [productId] - 商品ID
  /// [packageId] - 套餐ID
  static Future<IAPVerifyResult> verifyIAPReceipt({
    required String platform,
    required String receipt,
    required String productId,
    required int packageId,
  }) async {
    final user = AuthService().loginUser;
    final userid = user?.userid ?? 0;
    final token = user?.token ?? '';

    final res = await HttpService.postForm<IAPVerifyResult>(
      '/coin/verifyIAP',
      {
        'userid': userid.toString(),
        'token': token,
        'platform': platform,
        'receipt': receipt,
        'product_id': productId,
        'package_id': packageId.toString(),
      },
      fromData: (data) => IAPVerifyResult.fromJson(data),
    );

    // 更新缓存的余额
    if (res.data != null && res.data!.success) {
      _cachedBalance = CoinBalance(
        coins: res.data!.balance,
        isSuper: _cachedBalance?.isSuper ?? 0,
        superType: _cachedBalance?.superType,
        isLifetime: _cachedBalance?.isLifetime ?? false,
        shouldCharge: _cachedBalance?.shouldCharge ?? true,
        vipLevelId: _cachedBalance?.vipLevelId ?? 0,
      );
    }

    return res.data!;
  }

  /// 检查是否有足够积分
  static Future<bool> hasEnoughCoins(int required) async {
    final balance = _cachedBalance ?? await getBalance();

    // 免费用户无需检查
    if (balance.isFreeUser) return true;

    return balance.coins >= required;
  }

  /// 清除缓存
  static void clearCache() {
    _cachedBalance = null;
    _cachedConfig = null;
  }
}

/// 消费结果
class ConsumeResult {
  final bool charged;
  final int coinsUsed;
  final int balance;
  final int? consumeId;
  final String? reason;

  ConsumeResult({
    required this.charged,
    required this.coinsUsed,
    required this.balance,
    this.consumeId,
    this.reason,
  });

  factory ConsumeResult.fromJson(Map<String, dynamic> json) {
    return ConsumeResult(
      charged: _parseBool(json['charged']),
      coinsUsed: _parseInt(json['coins_used']),
      balance: _parseInt(json['balance']),
      consumeId:
          json['consume_id'] == null ? null : _parseInt(json['consume_id']),
      reason: json['reason']?.toString(),
    );
  }
}

/// 充值订单创建结果
class RechargeOrderResult {
  final String orderSn; // 订单号
  final String paymentUrl; // 支付跳转链接
  final String? qrCodeUrl; // 二维码支付链接（可选）
  final int expireTime; // 订单过期时间戳

  RechargeOrderResult({
    required this.orderSn,
    required this.paymentUrl,
    this.qrCodeUrl,
    required this.expireTime,
  });

  factory RechargeOrderResult.fromJson(Map<String, dynamic> json) {
    return RechargeOrderResult(
      orderSn: json['order_sn']?.toString() ?? '',
      paymentUrl: json['payment_url']?.toString() ?? '',
      qrCodeUrl: json['qr_code_url']?.toString(),
      expireTime: _parseInt(json['expire_time']),
    );
  }
}

/// 充值订单状态
class RechargeOrderStatus {
  final String orderSn;
  final String status; // pending, paid, expired, cancelled
  final int? coinsAdded; // 充值成功时的积分数
  final int? balance; // 充值成功时的当前余额

  RechargeOrderStatus({
    required this.orderSn,
    required this.status,
    this.coinsAdded,
    this.balance,
  });

  factory RechargeOrderStatus.fromJson(Map<String, dynamic> json) {
    return RechargeOrderStatus(
      orderSn: json['order_sn']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      coinsAdded:
          json['coins_added'] == null ? null : _parseInt(json['coins_added']),
      balance: json['balance'] == null ? null : _parseInt(json['balance']),
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';
}

/// IAP 收据验证结果
class IAPVerifyResult {
  final bool success;
  final int coinsAdded;
  final int balance;
  final String? message;

  IAPVerifyResult({
    required this.success,
    required this.coinsAdded,
    required this.balance,
    this.message,
  });

  factory IAPVerifyResult.fromJson(Map<String, dynamic> json) {
    return IAPVerifyResult(
      success: _parseBool(json['success']),
      coinsAdded: _parseInt(json['coins_added']),
      balance: _parseInt(json['balance']),
      message: json['message']?.toString(),
    );
  }
}
