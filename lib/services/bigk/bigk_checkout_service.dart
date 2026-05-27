import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_checkout.dart';
import '../../dto/bigk/bigk_order.dart';
import 'bigk_http_service.dart';

class BigKCheckoutService {
  static Future<BigKShippingRatesResponse> getShippingRates({
    required int merchantId,
    required List<BigKCheckoutItemInput> items,
    required BigKShippingAddress shippingAddress,
  }) async {
    debugPrint('BigKCheckoutService: Getting shipping rates...');

    return BigKHttpService.post<BigKShippingRatesResponse>(
      '/checkout/shipping-rates',
      {
        'merchant_id': merchantId,
        'items': items.map((e) => e.toJson()).toList(),
        'shipping_address': shippingAddress.toJson(),
      },
      (data) => BigKShippingRatesResponse.fromJson(data),
    );
  }

  static Future<BigKCheckoutPreview> previewOrder({
    required List<BigKCheckoutItemInput> items,
    int? shippingOptionId,
    bool applyKccDiscount = false,
    double? kccAmount,
  }) async {
    debugPrint('BigKCheckoutService: Previewing order...');

    return BigKHttpService.post<BigKCheckoutPreview>(
      '/checkout/preview',
      {
        'items': items.map((e) => e.toJson()).toList(),
        if (shippingOptionId != null) 'shipping_option_id': shippingOptionId,
        'apply_kcc_discount': applyKccDiscount,
        if (kccAmount != null) 'kcc_amount': kccAmount,
      },
      (data) => BigKCheckoutPreview.fromJson(data),
    );
  }

  static Future<BigKStripeSession> createCheckoutSession({
    required List<BigKCheckoutItemInput> items,
    required BigKShippingAddress shippingAddress,
    required BigKShippingRate shippingRate,
    bool applyKccDiscount = false,
    double? kccAmount,
    required String successUrl,
    required String cancelUrl,
  }) async {
    debugPrint('BigKCheckoutService: Creating checkout session...');

    return BigKHttpService.post<BigKStripeSession>(
      '/checkout/create-session',
      {
        'items': items.map((e) => e.toJson()).toList(),
        'shipping_address': shippingAddress.toJson(),
        'shipping_rate': shippingRate.toCheckoutJson(),
        'apply_kcc_discount': applyKccDiscount,
        if (kccAmount != null) 'kcc_amount': kccAmount,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
      (data) => BigKStripeSession.fromJson(data),
    );
  }

  static Future<Map<String, dynamic>> placeOrder({
    required List<BigKCheckoutItemInput> items,
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    required String city,
    required String province,
    required String postalCode,
  }) async {
    debugPrint('BigKCheckoutService: Placing direct KCC order...');

    return BigKHttpService.post<Map<String, dynamic>>(
      '/kmall/public/orders',
      {
        'items': items
            .map(
              (e) => {
                'product_id': e.productId,
                'qty': e.quantity,
                if (e.variantId != null) 'variant_id': e.variantId,
                if (e.options != null && e.options!.isNotEmpty)
                  'options': e.options,
              },
            )
            .toList(),
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'shipping_address': shippingAddress,
        'city': city,
        'province': province,
        'postal_code': postalCode,
      },
      (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<BigKOrderPage> getOrders({
    int page = 1,
    int perPage = 20,
  }) async {
    debugPrint('BigKCheckoutService: Fetching orders page $page...');

    return BigKHttpService.get<BigKOrderPage>(
      '/kmall/public/orders',
      (data) => BigKOrderPage.fromJson(data),
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  static Future<BigKOrder> getOrder(int orderId) async {
    debugPrint('BigKCheckoutService: Fetching order $orderId...');

    return BigKHttpService.get<BigKOrder>(
      '/kmall/public/orders/$orderId',
      (data) => BigKOrder.fromJson(
        Map<String, dynamic>.from((data['data'] ?? data) as Map),
      ),
    );
  }
}
