import '../dto/bigk/bigk_category.dart';
import '../dto/bigk/bigk_product.dart';
import '../dto/shop/shop_dto.dart';
import 'bigk/bigk_shop_service.dart';

class ShopService {
  static const List<int> _excludedCategoryIds = [47];
  static const List<String> _excludedCategorySlugs = ['membership_fee'];

  static List<Category>? _categoriesCache;
  static DateTime? _categoriesCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  static Future<List<Product>> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? onSale,
    bool? featured,
    String orderBy = 'date',
    String order = 'desc',
  }) async {
    final category = await _resolveCategoryFilter(categoryId);
    final result = await BigKShopService.getProducts(
      page: page,
      perPage: perPage,
      category: category,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: _mapSort(orderBy, order),
    );

    final products = result.data
        .map(mapBigKProduct)
        .where(_isVisibleProduct)
        .toList(growable: false);

    final sorted = _sortProducts(
      products,
      orderBy: orderBy,
      order: order,
    );

    if (onSale == true || featured == true) {
      return sorted;
    }

    return sorted;
  }

  static Future<Product> getProduct(int productId) async {
    final product = await BigKShopService.getProduct(productId);
    return mapBigKProduct(product);
  }

  static Future<List<Category>> getCategories({
    bool forceRefresh = false,
    bool hideEmpty = true,
  }) async {
    if (!forceRefresh &&
        _categoriesCache != null &&
        _categoriesCacheTime != null &&
        DateTime.now().difference(_categoriesCacheTime!) < _cacheDuration) {
      return _categoriesCache!;
    }

    final categories = (await BigKShopService.getCategories(
      forceRefresh: forceRefresh,
    ))
        .map(_mapCategory)
        .where((category) {
      final excluded = _excludedCategoryIds.contains(category.id) ||
          _excludedCategorySlugs.contains(category.slug);
      if (excluded) {
        return false;
      }
      if (hideEmpty && category.count <= 0) {
        return false;
      }
      return true;
    }).toList(growable: false);

    _categoriesCache = categories;
    _categoriesCacheTime = DateTime.now();
    return categories;
  }

  static Future<List<Product>> getSaleProducts({
    int page = 1,
    int perPage = 10,
  }) {
    return getProducts(
      page: page,
      perPage: perPage,
      onSale: true,
      orderBy: 'date',
      order: 'desc',
    );
  }

  static Future<List<Product>> getFeaturedProducts({
    int page = 1,
    int perPage = 10,
  }) {
    return getProducts(
      page: page,
      perPage: perPage,
      featured: true,
      orderBy: 'date',
      order: 'desc',
    );
  }

  static Future<List<Product>> getLatestProducts({
    int perPage = 10,
  }) {
    return getProducts(
      page: 1,
      perPage: perPage,
      orderBy: 'date',
      order: 'desc',
    );
  }

  static Future<List<Product>> getPopularProducts({
    int perPage = 10,
  }) {
    return getProducts(
      page: 1,
      perPage: perPage,
      orderBy: 'popularity',
      order: 'desc',
    );
  }

  static Future<List<Product>> searchProducts(
    String keyword, {
    int page = 1,
    int perPage = 20,
  }) {
    return getProducts(
      page: page,
      perPage: perPage,
      search: keyword,
    );
  }

  static Future<List<Product>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 20,
    String orderBy = 'date',
    String order = 'desc',
  }) {
    return getProducts(
      page: page,
      perPage: perPage,
      categoryId: categoryId,
      orderBy: orderBy,
      order: order,
    );
  }

  static Future<List<ProductVariation>> getProductVariations(
    int productId,
  ) async {
    final product = await BigKShopService.getProduct(productId);
    return product.variants.map(_mapVariation).toList(growable: false);
  }

  static void clearCategoriesCache() {
    _categoriesCache = null;
    _categoriesCacheTime = null;
    BigKShopService.clearCache();
  }

  static Product mapBigKProduct(BigKProduct product) {
    final price = _formatAmount(product.fiatPrice);
    final imageUrls = <String>{};
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      imageUrls.add(product.imageUrl!);
    }
    imageUrls.addAll(product.images.where((url) => url.isNotEmpty));

    return Product(
      id: product.id,
      name: product.name,
      slug: product.externalId?.isNotEmpty == true
          ? product.externalId!
          : _slugify(product.name),
      description: product.description ?? '',
      shortDescription: '',
      price: price,
      regularPrice: price,
      salePrice: '',
      onSale: false,
      images: imageUrls
          .toList(growable: false)
          .asMap()
          .entries
          .map(
            (entry) => ProductImage(
              id: entry.key + 1,
              src: entry.value,
              name: product.name,
              alt: product.name,
            ),
          )
          .toList(growable: false),
      categories: _mapProductCategories(product),
      inStock: product.inStock,
      stockQuantity: product.inventory,
      type: 'simple',
      variations: const [],
      attributes: const [],
      virtual: false,
      downloadable: false,
    );
  }

  static Category _mapCategory(BigKCategory category) {
    return Category(
      id: category.id,
      name: category.name,
      slug: (category.slug?.isNotEmpty == true)
          ? category.slug!
          : _slugify(category.name),
      parent: category.parentId ?? 0,
      description: category.description ?? '',
      image: category.imageUrl,
      count: category.productCount,
    );
  }

  static ProductVariation _mapVariation(BigKProductVariant variant) {
    final priceAdjustment = variant.priceAdjustment;
    final price =
        priceAdjustment == 0 ? '0.00' : priceAdjustment.toStringAsFixed(2);

    return ProductVariation(
      id: variant.id,
      price: price,
      regularPrice: price,
      salePrice: '',
      onSale: false,
      inStock: variant.inventory > 0,
      stockQuantity: variant.inventory,
      image: null,
      attributes: [
        VariationAttribute(
          id: 0,
          name: 'Variant',
          option: variant.name,
        ),
      ],
    );
  }

  static List<ProductCategory> _mapProductCategories(BigKProduct product) {
    if (product.category == null || product.category!.trim().isEmpty) {
      return const [];
    }

    final name = product.category!.trim();
    return [
      ProductCategory(
        id: 0,
        name: name,
        slug: _slugify(name),
      ),
    ];
  }

  static Future<String?> _resolveCategoryFilter(int? categoryId) async {
    if (categoryId == null) {
      return null;
    }

    final categories = await getCategories();
    for (final category in categories) {
      if (category.id == categoryId) {
        if (category.slug.isNotEmpty) {
          return category.slug;
        }
        if (category.name.isNotEmpty) {
          return category.name;
        }
      }
    }

    return categoryId.toString();
  }

  static bool _isVisibleProduct(Product product) {
    for (final category in product.categories) {
      if (_excludedCategoryIds.contains(category.id) ||
          _excludedCategorySlugs.contains(category.slug)) {
        return false;
      }
    }
    return true;
  }

  static String? _mapSort(String orderBy, String order) {
    switch ('$orderBy:$order') {
      case 'price:asc':
        return 'price_asc';
      case 'price:desc':
        return 'price_desc';
      case 'popularity:desc':
        return 'popular';
      case 'rating:desc':
        return 'popular';
      case 'date:asc':
        return 'oldest';
      case 'date:desc':
        return 'latest';
      default:
        return null;
    }
  }

  static List<Product> _sortProducts(
    List<Product> products, {
    required String orderBy,
    required String order,
  }) {
    final sorted = List<Product>.from(products);
    final descending = order.toLowerCase() == 'desc';

    int comparePrice(Product a, Product b) {
      final aPrice = double.tryParse(a.price) ?? 0;
      final bPrice = double.tryParse(b.price) ?? 0;
      return aPrice.compareTo(bPrice);
    }

    switch (orderBy) {
      case 'price':
        sorted.sort(comparePrice);
        break;
      case 'date':
      case 'popularity':
      case 'rating':
      default:
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
    }

    return descending ? sorted.reversed.toList(growable: false) : sorted;
  }

  static String _formatAmount(double? value) {
    return (value ?? 0).toStringAsFixed(2);
  }

  static String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class ProductVariation {
  final int id;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final bool inStock;
  final int? stockQuantity;
  final String? image;
  final List<VariationAttribute> attributes;

  ProductVariation({
    required this.id,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.inStock,
    this.stockQuantity,
    this.image,
    required this.attributes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'on_sale': onSale,
      'in_stock': inStock,
      'stock_quantity': stockQuantity,
      'image': image,
      'attributes': attributes.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasDiscount => onSale && salePrice.isNotEmpty;
}

class VariationAttribute {
  final int id;
  final String name;
  final String option;

  VariationAttribute({
    required this.id,
    required this.name,
    required this.option,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'option': option,
    };
  }
}
