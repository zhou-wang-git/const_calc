import 'bigk_product.dart';

class BigKWishlistItem {
  final int id;
  final int productId;
  final BigKProduct? product;
  final DateTime? addedAt;

  BigKWishlistItem({
    required this.id,
    required this.productId,
    this.product,
    this.addedAt,
  });

  factory BigKWishlistItem.fromJson(Map<String, dynamic> json) {
    final productJson = _mapValue(json['product']) ??
        _mapValue(json['product_data']) ??
        _mapValue(json['item']);

    return BigKWishlistItem(
      id: _parseInt(json['id'] ?? json['wishlist_id']),
      productId: _parseInt(
        json['product_id'] ??
            json['productId'] ??
            productJson?['id'] ??
            json['product'],
      ),
      product: productJson == null ? null : BigKProduct.fromJson(productJson),
      addedAt: json['added_at'] != null || json['created_at'] != null
          ? DateTime.tryParse(
              (json['added_at'] ?? json['created_at']).toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'added_at': addedAt?.toIso8601String(),
    };
  }

  static Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class BigKWishlist {
  final List<BigKWishlistItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  BigKWishlist({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory BigKWishlist.fromJson(Map<String, dynamic> json) {
    final payload = _mapValue(json['data']) ?? json;
    final itemsList = _listValue(json['data']) ??
        _listValue(payload['data']) ??
        _listValue(payload['items']) ??
        _listValue(payload['wishlist']) ??
        _listValue(json['items']) ??
        const [];
    final meta =
        _mapValue(payload['meta']) ?? _mapValue(json['meta']) ?? payload;

    return BigKWishlist(
      items: itemsList
          .map(
            (e) =>
                BigKWishlistItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      perPage: meta['per_page'] ?? itemsList.length,
      total: meta['total'] ?? itemsList.length,
    );
  }

  bool get isEmpty => items.isEmpty;

  bool containsProduct(int productId) {
    return items.any((item) => item.productId == productId);
  }

  static Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static List<dynamic>? _listValue(dynamic value) {
    if (value is List<dynamic>) {
      return value;
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return null;
  }
}

class BigKWishlistResponse {
  final bool success;
  final String? message;
  final bool? isInWishlist;

  BigKWishlistResponse({
    required this.success,
    this.message,
    this.isInWishlist,
  });

  factory BigKWishlistResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;

    return BigKWishlistResponse(
      success: json['success'] ?? data['success'] ?? true,
      message: json['message']?.toString() ?? data['message']?.toString(),
      isInWishlist: data['is_in_wishlist'] ?? data['in_wishlist'],
    );
  }
}
