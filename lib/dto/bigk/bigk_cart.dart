class BigKCartItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double lineTotal;
  final String? imageUrl;
  final int? variantId;
  final String? variantName;
  final Map<String, dynamic>? options;

  BigKCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    this.imageUrl,
    this.variantId,
    this.variantName,
    this.options,
  });

  factory BigKCartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : json['product'] is Map
            ? Map<String, dynamic>.from(json['product'] as Map)
            : <String, dynamic>{};
    final variant = json['variant'] is Map<String, dynamic>
        ? json['variant'] as Map<String, dynamic>
        : json['variant'] is Map
            ? Map<String, dynamic>.from(json['variant'] as Map)
            : <String, dynamic>{};

    return BigKCartItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? product['id'] ?? 0,
      productName:
          json['product_name'] ?? product['name'] ?? json['name'] ?? '',
      quantity: json['quantity'] ?? json['qty'] ?? 1,
      price: _parseDouble(json['price'] ?? product['price']),
      lineTotal:
          _parseDouble(json['line_total'] ?? json['subtotal'] ?? json['total']),
      imageUrl: json['image_url'] ?? product['image_url'] ?? json['image'],
      variantId: json['variant_id'] ?? variant['id'],
      variantName: json['variant_name'] ?? variant['name'],
      options: json['options'] is Map<String, dynamic>
          ? json['options'] as Map<String, dynamic>
          : json['options'] is Map
              ? Map<String, dynamic>.from(json['options'] as Map)
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'line_total': lineTotal,
      'image_url': imageUrl,
      'variant_id': variantId,
      'variant_name': variantName,
      'options': options,
    };
  }

  String get priceFormatted => price.toStringAsFixed(2);
  String get lineTotalFormatted => lineTotal.toStringAsFixed(2);
}

class BigKCart {
  final int? id;
  final List<BigKCartItem> items;
  final int itemCount;
  final double subtotal;
  final double total;
  final String currency;

  BigKCart({
    this.id,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.total,
    this.currency = 'KCC',
  });

  factory BigKCart.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;
    final itemsList = data['items'] as List<dynamic>? ?? const [];
    final subtotal = _parseDouble(data['subtotal']);
    final total = _parseDouble(data['total']);

    return BigKCart(
      id: data['id'],
      items: itemsList
          .map(
              (e) => BigKCartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      itemCount: data['item_count'] ?? itemsList.length,
      subtotal: subtotal == 0 ? total : subtotal,
      total: total,
      currency: data['currency'] ?? json['currency'] ?? 'KCC',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'item_count': itemCount,
      'subtotal': subtotal,
      'total': total,
      'currency': currency,
    };
  }

  bool get isEmpty => items.isEmpty;
  String get subtotalFormatted => '$currency ${subtotal.toStringAsFixed(2)}';
  String get totalFormatted => '$currency ${total.toStringAsFixed(2)}';

  factory BigKCart.empty() {
    return BigKCart(
      items: const [],
      itemCount: 0,
      subtotal: 0,
      total: 0,
    );
  }
}

class BigKAddToCartResponse {
  final bool success;
  final String? message;
  final int? itemId;
  final int? cartItemCount;
  final double? cartTotal;
  final BigKCart? cart;

  BigKAddToCartResponse({
    required this.success,
    this.message,
    this.itemId,
    this.cartItemCount,
    this.cartTotal,
    this.cart,
  });

  factory BigKAddToCartResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : <String, dynamic>{};

    return BigKAddToCartResponse(
      success: json['success'] ?? true,
      message: json['message']?.toString(),
      itemId: data['item_id'],
      cartItemCount: data['cart_item_count'],
      cartTotal: data['cart_total'] == null
          ? null
          : BigKCart._parseDouble(data['cart_total']),
      cart: json['cart'] != null ? BigKCart.fromJson(json['cart']) : null,
    );
  }
}
