import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'payment_service.dart';
import 'iap_service.dart';
import 'stripe_payment_service_io.dart';

/// 支付服务工厂
/// 根据平台返回对应的支付服务实现
class PaymentFactory {
  /// 创建平台对应的支付服务
  ///
  /// - iOS: 返回 IAPService（Apple In-App Purchase）
  /// - Android/Web: 返回 StripePaymentService
  static PaymentService create() {
    if (kIsWeb) {
      // Web 平台使用 Stripe
      return StripePaymentService();
    } else if (Platform.isIOS) {
      // iOS 平台使用 Apple IAP
      return IAPService();
    } else {
      // Android 平台使用 Stripe
      return StripePaymentService();
    }
  }
}
