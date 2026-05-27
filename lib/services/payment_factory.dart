import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'payment_service.dart';
import 'iap_service.dart';
import 'stripe_payment_service_io.dart';

/// 支付方式枚举
enum PaymentMethod {
  /// Apple In-App Purchase (iOS only)
  appleIAP,
  /// Google Play In-App Purchase (Android only)
  googlePlayIAP,
  /// Stripe 支付 (all platforms)
  stripe,
}

/// 支付服务工厂
/// 根据平台返回对应的支付服务实现
class PaymentFactory {
  /// 创建平台默认的支付服务
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

  /// 根据指定的支付方式创建对应的支付服务
  static PaymentService createByMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.appleIAP:
        return IAPService();
      case PaymentMethod.googlePlayIAP:
        return IAPService(); // 复用 IAPService，内部会区分平台
      case PaymentMethod.stripe:
        return StripePaymentService();
    }
  }

  /// 获取当前平台支持的支付方式列表
  static List<PaymentMethod> getAvailableMethods() {
    if (kIsWeb) {
      return [PaymentMethod.stripe];
    } else if (Platform.isIOS) {
      // iOS 只能用 Apple IAP（政策要求）
      return [PaymentMethod.appleIAP];
    } else if (Platform.isAndroid) {
      // Android 支持 Google Play IAP 和 Stripe
      return [PaymentMethod.googlePlayIAP, PaymentMethod.stripe];
    }
    return [PaymentMethod.stripe];
  }

  /// 当前平台是否支持多种支付方式
  static bool hasMultipleMethods() {
    return getAvailableMethods().length > 1;
  }

  /// 获取支付方式的显示名称
  static String getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.appleIAP:
        return 'Apple Pay';
      case PaymentMethod.googlePlayIAP:
        return 'Google Play';
      case PaymentMethod.stripe:
        return '信用卡支付';
    }
  }

  /// 获取支付方式的图标
  static String getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.appleIAP:
        return 'assets/icons/apple_pay.png';
      case PaymentMethod.googlePlayIAP:
        return 'assets/icons/google_play.png';
      case PaymentMethod.stripe:
        return 'assets/icons/credit_card.png';
    }
  }
}
