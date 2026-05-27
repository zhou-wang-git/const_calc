class BigKCheckoutItemInput {
  final int productId;
  final int quantity;
  final int? variantId;
  final Map<String, dynamic>? options;

  const BigKCheckoutItemInput({
    required this.productId,
    required this.quantity,
    this.variantId,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (variantId != null) 'variant_id': variantId,
      if (options != null && options!.isNotEmpty) 'options': options,
    };
  }
}

class BigKShippingRate {
  final String id;
  final int? shippingOptionId;
  final String name;
  final String type;
  final double amount;
  final String currency;
  final bool isLiveRate;
  final String? carrier;
  final String? serviceLevel;
  final int? merchantAmount;
  final String? merchantCurrency;
  final String? estimatedDays;

  BigKShippingRate({
    required this.id,
    this.shippingOptionId,
    required this.name,
    required this.type,
    required this.amount,
    required this.currency,
    required this.isLiveRate,
    this.carrier,
    this.serviceLevel,
    this.merchantAmount,
    this.merchantCurrency,
    this.estimatedDays,
  });

  factory BigKShippingRate.fromJson(Map<String, dynamic> json) {
    return BigKShippingRate(
      id: json['id']?.toString() ?? '',
      shippingOptionId: json['shipping_option_id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      amount: _parseDouble(json['amount']),
      currency: json['currency'] ?? 'USD',
      isLiveRate: json['is_live_rate'] ?? false,
      carrier: json['carrier']?.toString(),
      serviceLevel: json['service_level']?.toString(),
      merchantAmount: json['merchant_amount'],
      merchantCurrency: json['merchant_currency']?.toString(),
      estimatedDays: json['estimated_days']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toCheckoutJson() {
    return {
      'id': id,
      'amount': amount,
      if (shippingOptionId != null) 'shipping_option_id': shippingOptionId,
      'is_live_rate': isLiveRate,
    };
  }

  String get amountFormatted => '$currency ${amount.toStringAsFixed(2)}';
}

class BigKShippingRatesResponse {
  final List<BigKShippingRate> rates;

  BigKShippingRatesResponse({required this.rates});

  factory BigKShippingRatesResponse.fromJson(Map<String, dynamic> json) {
    final ratesList = json['rates'] ?? json['data'] ?? const [];
    return BigKShippingRatesResponse(
      rates: (ratesList as List)
          .map((e) =>
              BigKShippingRate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class BigKCheckoutDiscount {
  final String name;
  final double amount;

  BigKCheckoutDiscount({
    required this.name,
    required this.amount,
  });

  factory BigKCheckoutDiscount.fromJson(Map<String, dynamic> json) {
    return BigKCheckoutDiscount(
      name: json['name'] ?? '',
      amount: BigKShippingRate._parseDouble(json['amount']),
    );
  }
}

class BigKCheckoutPreviewItem {
  final int productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final int? variantId;
  final String? variantName;

  BigKCheckoutPreviewItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.variantId,
    this.variantName,
  });

  factory BigKCheckoutPreviewItem.fromJson(Map<String, dynamic> json) {
    return BigKCheckoutPreviewItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      unitPrice: BigKShippingRate._parseDouble(json['unit_price']),
      quantity: json['qty'] ?? json['quantity'] ?? 1,
      lineTotal: BigKShippingRate._parseDouble(json['line_total']),
      variantId: json['variant_id'],
      variantName: json['variant_name']?.toString(),
    );
  }
}

class BigKCheckoutPreview {
  final List<BigKCheckoutPreviewItem> items;
  final double subtotal;
  final List<BigKCheckoutDiscount> discounts;
  final double totalDiscount;
  final double finalTotal;
  final String currency;

  BigKCheckoutPreview({
    required this.items,
    required this.subtotal,
    required this.discounts,
    required this.totalDiscount,
    required this.finalTotal,
    this.currency = 'KCC',
  });

  factory BigKCheckoutPreview.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;
    final itemList = data['items'] as List<dynamic>? ?? const [];
    final discountList = data['discounts'] as List<dynamic>? ?? const [];

    return BigKCheckoutPreview(
      items: itemList
          .map(
            (e) => BigKCheckoutPreviewItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      subtotal: BigKShippingRate._parseDouble(data['subtotal']),
      discounts: discountList
          .map(
            (e) => BigKCheckoutDiscount.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      totalDiscount: BigKShippingRate._parseDouble(data['total_discount']),
      finalTotal: BigKShippingRate._parseDouble(
        data['final_total'] ?? data['total'],
      ),
      currency: data['currency'] ?? 'KCC',
    );
  }

  String get subtotalFormatted => '$currency ${subtotal.toStringAsFixed(2)}';
  String get totalDiscountFormatted =>
      '-$currency ${totalDiscount.toStringAsFixed(2)}';
  String get totalFormatted => '$currency ${finalTotal.toStringAsFixed(2)}';
}

class BigKStripeSession {
  final String sessionId;
  final String checkoutUrl;
  final int? orderId;
  final String? orderNumber;

  BigKStripeSession({
    required this.sessionId,
    required this.checkoutUrl,
    this.orderId,
    this.orderNumber,
  });

  factory BigKStripeSession.fromJson(Map<String, dynamic> json) {
    return BigKStripeSession(
      sessionId: json['session_id'] ?? '',
      checkoutUrl: json['checkout_url'] ?? '',
      orderId: json['order_id'],
      orderNumber: json['order_number'],
    );
  }
}

class BigKShippingAddress {
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String? phone;

  const BigKShippingAddress({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }
}
