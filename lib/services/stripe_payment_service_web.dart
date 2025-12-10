import 'package:web/web.dart' as web;

import '../dto/stripe_checkout_session.dart';
import '../dto/user.dart';
import 'http_service.dart';
import 'package:const_calc/services/user_service.dart';

class StripePaymentService {
  static Future<void> pay({
    required String vipLevelId,
    required String currency,
    required String vipTime,
    required String vipName,
    required String vipDate,
    required String amount,
    required String originalAmount,
    Object? context, // Web 无需 BuildContext
  }) async {
    await _payWithCheckout(
      vipLevelId: vipLevelId,
      currency: currency,
      vipTime: vipTime,
      vipName: vipName,
      vipDate: vipDate,
      amount: amount,
      originalAmount: originalAmount,
    );
  }

  static Future<void> _payWithCheckout({
    required String vipLevelId,
    required String currency,
    required String vipTime,
    required String vipName,
    required String vipDate,
    required String amount,
    required String originalAmount,
  }) async {
    final User? user = await UserService().getUserInfo();

    final res = await HttpService.postForm<StripeCheckoutSession>(
      '/order/addH5Pay',
      {
        'token': user?.token ?? '',
        'userid': user?.id.toString() ?? '',
        'vip_level_id': vipLevelId,
        'vip_time': vipTime,
        'vip_name': vipName,
        'vip_date': vipDate,
        'amount': amount,
        'original_amount': originalAmount,
      },
      fromData: (json) => StripeCheckoutSession.fromJson(json),
    );

    final checkoutUrl = res.data?.redirectUrl;
    if (checkoutUrl == null) {
      throw Exception('Checkout URL not returned from backend');
    }

    // 同页跳转（避免新窗口在嵌入场景被拦）
    web.window.location.href = checkoutUrl.toString();
  }
}
