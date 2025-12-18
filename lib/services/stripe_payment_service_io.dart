import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'http_service.dart';
import 'payment_service.dart';

class StripePaymentService implements PaymentService {
  /// 发起支付（实现 PaymentService 接口）
  @override
  Future<bool> pay({
    required BuildContext context,
    required String vipLevelId,
    required String vipName,
    required String vipTime,
    required String vipDate,
    required String amount,
    required String originalAmount,
    String currency = 'usd',
  }) async {
    try {
      await _payWithPaymentSheet(
        vipLevelId: vipLevelId,
        vipTime: vipTime,
        vipName: vipName,
        vipDate: vipDate,
        amount: amount,
        originalAmount: originalAmount,
      );
      return true;
    } catch (e) {
      // 支付失败或用户取消
      return false;
    }
  }

  /// 恢复购买（Stripe 不需要此功能，提供空实现）
  @override
  Future<void> restorePurchases(BuildContext context) async {
    // Stripe 支付不需要恢复购买功能，仅 iOS IAP 需要
  }

  static Future<void> _payWithPaymentSheet({
    required String vipLevelId,
    required String vipTime,
    required String vipName,
    required String vipDate,
    required String amount,
    required String originalAmount,
  }) async {
    // 获取用户信息
    final user = AuthService().loginUser;
    if (user == null) {
      throw Exception('请先登录');
    }

    // 1. 调用后端 addAPPPay 创建 PaymentIntent
    final res = await http.post(
      Uri.parse('${HttpService.baseUrl}/order/addAPPPay'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'vip_level_id': vipLevelId,
        'vip_time': vipTime,
        'vip_name': vipName,
        'vip_date': vipDate,
        'original_amount': originalAmount,
        'amount': amount,
        'userid': user.userid.toString(),
        'token': user.token ?? '',
      },
    );

    if (res.statusCode >= 400) {
      throw Exception('Create PaymentIntent failed: ${res.body}');
    }

    final json = jsonDecode(res.body);
    if (json['code'] != 1) {
      throw Exception(json['msg'] ?? '创建支付失败');
    }

    final data = json['data'];

    // 2. 初始化 PaymentSheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: data['merchantName'] ?? '数易赋能',
        paymentIntentClientSecret: data['paymentIntent'],
        customerId: data['customer'],
        customerEphemeralKeySecret: data['ephemeralKey'],
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          testEnv: false, // 生产环境
        ),
        // Apple Pay 需要配置 merchantIdentifier，暂不启用
        // applePay: const PaymentSheetApplePay(merchantCountryCode: 'US'),
      ),
    );

    // 3. 展示收银台
    await Stripe.instance.presentPaymentSheet();
  }
}
