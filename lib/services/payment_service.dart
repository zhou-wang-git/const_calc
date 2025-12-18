import 'package:flutter/material.dart';

/// VIP 产品数据模型
class VipProduct {
  final String productId;      // 产品 ID（iOS: com.app.elite_12m, Android: price_xxx）
  final String title;           // 显示标题（如：精英会员12个月）
  final String price;           // 价格字符串（如：$99.99）
  final double amount;          // 原价金额
  final int vipTime;            // VIP 时长（月）
  final String vipLevelId;      // VIP 等级 ID
  final String vipName;         // VIP 名称（elite/supreme）

  VipProduct({
    required this.productId,
    required this.title,
    required this.price,
    required this.amount,
    required this.vipTime,
    required this.vipLevelId,
    required this.vipName,
  });
}

/// 支付服务抽象接口
/// iOS 使用 IAPService 实现，Android/Web 使用 StripePaymentService 实现
abstract class PaymentService {
  /// 发起支付
  ///
  /// 参数说明：
  /// - [context]: BuildContext，用于显示加载和错误提示
  /// - [vipLevelId]: VIP 等级 ID
  /// - [vipName]: VIP 名称（elite/supreme）
  /// - [vipTime]: VIP 时长（月）
  /// - [vipDate]: VIP 日期描述（如：12个月）
  /// - [amount]: 实付金额（折扣后）
  /// - [originalAmount]: 原价金额
  /// - [currency]: 货币代码（iOS 忽略，Android 使用 usd）
  ///
  /// 返回值：
  /// - true: 支付成功
  /// - false: 支付失败或取消
  Future<bool> pay({
    required BuildContext context,
    required String vipLevelId,
    required String vipName,
    required String vipTime,
    required String vipDate,
    required String amount,
    required String originalAmount,
    String currency = 'usd',
  });

  /// 恢复购买（仅 iOS IAP 需要）
  Future<void> restorePurchases(BuildContext context) async {
    // 默认实现为空，Android/Web 不需要恢复购买
  }
}
