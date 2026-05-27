/// 商品数据模型
/// 对应 WooCommerce Product 实体
class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String shortDescription;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final List<ProductImage> images;
  final List<ProductCategory> categories;
  final bool inStock;
  final int? stockQuantity;
  final String type; // simple, variable, grouped
  final List<int> variations;
  final List<ProductAttribute> attributes;
  final bool virtual;
  final bool downloadable;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.images,
    required this.categories,
    required this.inStock,
    this.stockQuantity,
    required this.type,
    required this.variations,
    required this.attributes,
    required this.virtual,
    required this.downloadable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      price: json['price'] ?? '0',
      regularPrice: json['regular_price'] ?? '0',
      salePrice: json['sale_price'] ?? '',
      onSale: json['on_sale'] ?? false,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => ProductCategory.fromJson(e))
              .toList() ??
          [],
      inStock: json['in_stock'] ?? (json['stock_status'] == 'instock'),
      stockQuantity: json['stock_quantity'],
      type: json['type'] ?? 'simple',
      variations: (json['variations'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) => ProductAttribute.fromJson(e))
              .toList() ??
          [],
      virtual: json['virtual'] ?? false,
      downloadable: json['downloadable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'on_sale': onSale,
      'images': images.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'in_stock': inStock,
      'stock_quantity': stockQuantity,
      'type': type,
      'variations': variations,
      'attributes': attributes.map((e) => e.toJson()).toList(),
      'virtual': virtual,
      'downloadable': downloadable,
    };
  }

  /// 是否有折扣
  bool get hasDiscount => onSale && salePrice.isNotEmpty;

  /// 折扣百分比
  int get discountPercent {
    if (!hasDiscount) return 0;
    final regular = double.tryParse(regularPrice) ?? 0;
    final sale = double.tryParse(salePrice) ?? 0;
    if (regular <= 0) return 0;
    return ((regular - sale) / regular * 100).round();
  }

  /// 主图URL
  String? get mainImageUrl => images.isNotEmpty ? images.first.src : null;

  /// 是否为虚拟商品（会员、订阅等）
  bool get isVirtualProduct => virtual || downloadable;
}

/// 商品图片
class ProductImage {
  final int id;
  final String src;
  final String name;
  final String alt;

  ProductImage({
    required this.id,
    required this.src,
    required this.name,
    required this.alt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      name: json['name'] ?? '',
      alt: json['alt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'src': src,
      'alt': alt,
    };
  }
}

/// 商品分类（嵌入在商品中的简化版）
class ProductCategory {
  final int id;
  final String name;
  final String slug;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

/// 商品属性（用于变体商品）
class ProductAttribute {
  final int id;
  final String name;
  final int position;
  final bool visible;
  final bool variation;
  final List<String> options;

  ProductAttribute({
    required this.id,
    required this.name,
    required this.position,
    required this.visible,
    required this.variation,
    required this.options,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? 0,
      visible: json['visible'] ?? true,
      variation: json['variation'] ?? false,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'visible': visible,
      'variation': variation,
      'options': options,
    };
  }
}
