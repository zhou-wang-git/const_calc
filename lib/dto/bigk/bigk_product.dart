import 'bigk_merchant.dart';

class BigKProductVariant {
  final int id;
  final String name;
  final double priceAdjustment;
  final int inventory;

  BigKProductVariant({
    required this.id,
    required this.name,
    this.priceAdjustment = 0,
    this.inventory = 0,
  });

  factory BigKProductVariant.fromJson(Map<String, dynamic> json) {
    return BigKProductVariant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      priceAdjustment: _parseDouble(json['price_adjustment']),
      inventory: json['inventory'] ?? 0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class BigKProduct {
  final int id;
  final String? externalId;
  final String name;
  final String? description;
  final double? fiatPrice;
  final String fiatCurrency;
  final String status;
  final String? category;
  final int? inventory;
  final String? imageUrl;
  final List<String> images;
  final int? merchantId;
  final BigKMerchant? merchant;
  final List<BigKProductVariant> variants;

  BigKProduct({
    required this.id,
    this.externalId,
    required this.name,
    this.description,
    this.fiatPrice,
    this.fiatCurrency = 'USD',
    required this.status,
    this.category,
    this.inventory,
    this.imageUrl,
    this.images = const [],
    this.merchantId,
    this.merchant,
    this.variants = const [],
  });

  factory BigKProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'] is List
        ? (json['images'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final variants = json['variants'] is List
        ? (json['variants'] as List)
            .map((e) => BigKProductVariant.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList()
        : <BigKProductVariant>[];

    final merchantJson = json['merchant'];

    return BigKProduct(
      id: json['id'] ?? 0,
      externalId: json['external_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description']?.toString(),
      fiatPrice: _parseDouble(json['fiat_price'] ?? json['price']),
      fiatCurrency: json['fiat_currency'] ?? json['currency'] ?? 'USD',
      status: json['status'] ?? 'active',
      category: json['category']?.toString(),
      inventory: json['inventory'] ?? json['stock'],
      imageUrl: json['image_url']?.toString(),
      images: images,
      merchantId: json['merchant_id'] ??
          (merchantJson is Map ? merchantJson['id'] : null),
      merchant: merchantJson is Map
          ? BigKMerchant.fromJson(Map<String, dynamic>.from(merchantJson))
          : null,
      variants: variants,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'external_id': externalId,
      'name': name,
      'description': description,
      'fiat_price': fiatPrice,
      'fiat_currency': fiatCurrency,
      'status': status,
      'category': category,
      'inventory': inventory,
      'image_url': imageUrl,
      'images': images,
      'merchant_id': merchantId,
    };
  }

  bool get inStock => inventory == null || inventory! > 0;
  bool get isActive => status == 'active';

  String get priceFormatted {
    if (fiatPrice == null) return 'N/A';
    return '$fiatCurrency ${fiatPrice!.toStringAsFixed(2)}';
  }

  String? get mainImage =>
      imageUrl ?? (images.isNotEmpty ? images.first : null);
  bool get hasVariants => variants.isNotEmpty;
}

class BigKProductPage {
  final List<BigKProduct> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  BigKProductPage({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory BigKProductPage.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] ?? json;

    return BigKProductPage(
      data: dataList
          .map((e) => BigKProduct.fromJson(Map<String, dynamic>.from(e as Map)))
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
