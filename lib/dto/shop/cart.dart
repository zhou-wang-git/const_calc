/// 购物车数据模型
class Cart {
  final List<CartItem> items;
  final CartTotals totals;
  final int itemCount;

  Cart({
    required this.items,
    required this.totals,
    required this.itemCount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e))
              .toList() ??
          [],
      totals: CartTotals.fromJson(json['totals'] ?? {}),
      itemCount: json['item_count'] ?? json['items_count'] ?? 0,
    );
  }

  factory Cart.empty() {
    return Cart(
      items: [],
      totals: CartTotals.empty(),
      itemCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'totals': totals.toJson(),
      'item_count': itemCount,
    };
  }

  /// 购物车是否为空
  bool get isEmpty => items.isEmpty;

  /// 商品总数量
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

/// 购物车商品项
class CartItem {
  final String key;
  final int id;
  final String name;
  final int quantity;
  final String price;
  final String lineTotal;
  final String? image;
  final int? variationId;
  final Map<String, String> variation;

  CartItem({
    required this.key,
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    this.image,
    this.variationId,
    required this.variation,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // 处理图片
    String? imageUrl;
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      imageUrl = json['images'][0]['src'];
    } else if (json['featured_image'] != null) {
      imageUrl = json['featured_image'];
    }

    // 处理变体属性
    Map<String, String> variationMap = {};
    if (json['variation'] != null && json['variation'] is List) {
      for (var v in json['variation']) {
        if (v is Map && v['attribute'] != null && v['value'] != null) {
          variationMap[v['attribute']] = v['value'];
        }
      }
    }

    return CartItem(
      key: json['key'] ?? json['item_key'] ?? '',
      id: json['id'] ?? json['product_id'] ?? 0,
      name: json['name'] ?? json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: _extractPrice(json['price'] ?? json['prices']),
      lineTotal: _extractPrice(json['line_total'] ?? json['totals']?['line_total']),
      image: imageUrl,
      variationId: json['variation_id'],
      variation: variationMap,
    );
  }

  static String _extractPrice(dynamic priceData) {
    if (priceData == null) return '0';
    if (priceData is String) return priceData;
    if (priceData is num) return priceData.toString();
    if (priceData is Map) {
      // WooCommerce Store API 格式
      return priceData['price'] ?? priceData['raw'] ?? '0';
    }
    return '0';
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'line_total': lineTotal,
      'image': image,
      'variation_id': variationId,
      'variation': variation,
    };
  }

  /// 单价（数值）
  double get priceValue => double.tryParse(price) ?? 0;

  /// 行总价（数值）
  double get lineTotalValue => double.tryParse(lineTotal) ?? 0;

  /// 是否为变体商品
  bool get isVariation => variationId != null && variationId! > 0;

  /// 变体描述
  String get variationDescription {
    if (variation.isEmpty) return '';
    return variation.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

/// 购物车总计
class CartTotals {
  final String subtotal;
  final String total;
  final String taxTotal;
  final String shippingTotal;
  final String discountTotal;
  final String currencyCode;
  final String currencySymbol;

  CartTotals({
    required this.subtotal,
    required this.total,
    required this.taxTotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.currencyCode,
    required this.currencySymbol,
  });

  factory CartTotals.fromJson(Map<String, dynamic> json) {
    return CartTotals(
      subtotal: _extractValue(json['subtotal'] ?? json['total_items']),
      total: _extractValue(json['total'] ?? json['total_price']),
      taxTotal: _extractValue(json['tax_total'] ?? json['total_tax']),
      shippingTotal: _extractValue(json['shipping_total']),
      discountTotal: _extractValue(json['discount_total']),
      currencyCode: json['currency_code'] ?? 'CNY',
      currencySymbol: json['currency_symbol'] ?? '¥',
    );
  }

  factory CartTotals.empty() {
    return CartTotals(
      subtotal: '0',
      total: '0',
      taxTotal: '0',
      shippingTotal: '0',
      discountTotal: '0',
      currencyCode: 'CNY',
      currencySymbol: '¥',
    );
  }

  static String _extractValue(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return '0';
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'total': total,
      'tax_total': taxTotal,
      'shipping_total': shippingTotal,
      'discount_total': discountTotal,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
    };
  }

  /// 小计（数值）
  double get subtotalValue => double.tryParse(subtotal) ?? 0;

  /// 总计（数值）
  double get totalValue => double.tryParse(total) ?? 0;

  /// 格式化总价
  String get formattedTotal => '$currencySymbol$total';

  /// 格式化小计
  String get formattedSubtotal => '$currencySymbol$subtotal';
}

/// 添加到购物车的请求
class AddToCartRequest {
  final int productId;
  final int quantity;
  final int? variationId;
  final Map<String, String>? variation;

  AddToCartRequest({
    required this.productId,
    this.quantity = 1,
    this.variationId,
    this.variation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': productId,
      'quantity': quantity,
    };
    if (variationId != null) {
      map['variation_id'] = variationId;
    }
    if (variation != null && variation!.isNotEmpty) {
      map['variation'] = variation;
    }
    return map;
  }
}
