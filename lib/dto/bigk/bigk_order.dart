class BigKOrder {
  final int id;
  final String orderNumber;
  final String state;
  final String paymentStatus;
  final double totalAmount;
  final double subtotalFiat;
  final double shippingFee;
  final double kccDiscountApplied;
  final String? itemName;
  final int quantity;
  final String? recipientName;
  final String? shippingAddress;
  final String? trackingNumber;
  final String currency;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> shipments;
  final Map<String, dynamic>? parsedShipping;
  final DateTime? placedAt;

  BigKOrder({
    required this.id,
    required this.orderNumber,
    required this.state,
    required this.paymentStatus,
    required this.totalAmount,
    required this.subtotalFiat,
    required this.shippingFee,
    required this.kccDiscountApplied,
    this.itemName,
    required this.quantity,
    this.recipientName,
    this.shippingAddress,
    this.trackingNumber,
    required this.currency,
    this.items = const [],
    this.shipments = const [],
    this.parsedShipping,
    this.placedAt,
  });

  factory BigKOrder.fromJson(Map<String, dynamic> json) {
    final items = _asMapList(json['items']);
    final shipments = _asMapList(json['shipments']);
    final parsedShipping = json['parsed_shipping'] is Map<String, dynamic>
        ? json['parsed_shipping'] as Map<String, dynamic>
        : json['parsed_shipping'] is Map
            ? Map<String, dynamic>.from(json['parsed_shipping'] as Map)
            : null;

    return BigKOrder(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      state: json['state'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      totalAmount: _parseDouble(
          json['total_amount'] ?? json['total'] ?? json['grand_total']),
      subtotalFiat: _parseDouble(json['subtotal_fiat'] ?? json['subtotal']),
      shippingFee: _parseDouble(json['shipping_fee']),
      kccDiscountApplied:
          _parseDouble(json['kcc_discount_applied'] ?? json['total_discount']),
      itemName:
          json['item_name'] ?? (items.isNotEmpty ? items.first['name'] : null),
      quantity: json['quantity'] ?? json['total_quantity'] ?? items.length,
      recipientName: json['recipient_name'],
      shippingAddress: json['shipping_address'],
      trackingNumber: json['tracking_number'],
      currency: json['currency'] ?? json['fiat_currency'] ?? 'KCC',
      items: items,
      shipments: shipments,
      parsedShipping: parsedShipping,
      placedAt: json['placed_at'] != null
          ? DateTime.tryParse(json['placed_at'].toString())
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  String get stateName {
    switch (state) {
      case 'pending':
        return '待处理';
      case 'confirmed':
        return '已确认';
      case 'processing':
        return '处理中';
      case 'dispatched':
        return '已发货';
      case 'delivered':
        return '已送达';
      default:
        return state;
    }
  }

  String get paymentStatusName {
    switch (paymentStatus) {
      case 'pending':
        return '待支付';
      case 'paid':
        return '已支付';
      case 'failed':
        return '支付失败';
      case 'refunded':
        return '已退款';
      default:
        return paymentStatus;
    }
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get canCancel => state == 'pending' && paymentStatus != 'paid';
  String get totalFormatted => '$currency ${totalAmount.toStringAsFixed(2)}';

  String get placedAtFormatted {
    if (placedAt == null) return '';
    return '${placedAt!.year}-${placedAt!.month.toString().padLeft(2, '0')}-${placedAt!.day.toString().padLeft(2, '0')} '
        '${placedAt!.hour.toString().padLeft(2, '0')}:${placedAt!.minute.toString().padLeft(2, '0')}';
  }
}

class BigKOrderPage {
  final List<BigKOrder> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  BigKOrderPage({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory BigKOrderPage.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? const [];
    final meta = json['meta'] ?? json;

    return BigKOrderPage(
      data: dataList
          .map((e) => BigKOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentPage: meta['current_page'] ?? meta['page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      perPage: meta['per_page'] ?? 20,
      total: meta['total'] ?? dataList.length,
    );
  }

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => data.isEmpty;
}
