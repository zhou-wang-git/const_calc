import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_category.dart';
import '../../dto/bigk/bigk_merchant.dart';
import '../../dto/bigk/bigk_product.dart';
import 'bigk_http_service.dart';

/// Shop service backed by PlenorHub.
class BigKShopService {
  static const String _publicMerchantsPath = '/integration/merchants';
  static const String _publicCategoriesPath = '/integration/categories';
  static const String _publicProductsPath = '/integration/products';

  static List<BigKCategory>? _categoriesCache;
  static DateTime? _categoriesCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  static List<BigKMerchant>? _merchantsCache;
  static DateTime? _merchantsCacheTime;

  static Future<List<BigKMerchant>> getMerchants({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _merchantsCache != null &&
        _merchantsCacheTime != null &&
        DateTime.now().difference(_merchantsCacheTime!) < _cacheDuration) {
      return _merchantsCache!;
    }

    debugPrint('BigKShopService: Fetching merchants...');
    final merchants = await _fetchList<BigKMerchant>(
      _publicMerchantsPath,
      (json) => BigKMerchant.fromJson(json),
    );

    _merchantsCache = merchants;
    _merchantsCacheTime = DateTime.now();

    return merchants;
  }

  static Future<List<BigKCategory>> getCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _categoriesCache != null &&
        _categoriesCacheTime != null &&
        DateTime.now().difference(_categoriesCacheTime!) < _cacheDuration) {
      return _categoriesCache!;
    }

    debugPrint('BigKShopService: Fetching categories...');
    final categories = await _fetchList<BigKCategory>(
      _publicCategoriesPath,
      (json) => BigKCategory.fromJson(json),
    );

    _categoriesCache = categories;
    _categoriesCacheTime = DateTime.now();

    return categories;
  }

  static Future<BigKProductPage> getProducts({
    int page = 1,
    int perPage = 20,
    String? category,
    int? merchantId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    debugPrint('BigKShopService: Fetching products page $page...');

    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (merchantId != null) queryParams['merchant_id'] = merchantId.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (sort != null) queryParams['sort'] = sort;

    return BigKHttpService.getPublic<BigKProductPage>(
      _publicProductsPath,
      (data) => BigKProductPage.fromJson(data),
      queryParams: queryParams,
    );
  }

  static Future<BigKProduct> getProduct(int productId) async {
    debugPrint('BigKShopService: Fetching product $productId...');

    return BigKHttpService.getPublic<BigKProduct>(
      '$_publicProductsPath/$productId',
      (data) => BigKProduct.fromJson(data['data'] ?? data),
    );
  }

  static Future<BigKProductPage> searchProducts(
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

  static Future<BigKProductPage> getProductsByCategory(
    String category, {
    int page = 1,
    int perPage = 20,
    String? sort,
  }) {
    return getProducts(
      page: page,
      perPage: perPage,
      category: category,
      sort: sort,
    );
  }

  static Future<BigKProductPage> getProductsByMerchant(
    int merchantId, {
    int page = 1,
    int perPage = 20,
  }) {
    return getProducts(
      page: page,
      perPage: perPage,
      merchantId: merchantId,
    );
  }

  static void clearCache() {
    _categoriesCache = null;
    _categoriesCacheTime = null;
    _merchantsCache = null;
    _merchantsCacheTime = null;
    debugPrint('BigKShopService: Cache cleared');
  }

  static Future<List<T>> _fetchList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<T> parser(dynamic data) {
      final list = data is List ? data : (data['data'] ?? []);
      return (list as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return BigKHttpService.getPublic<List<T>>(path, parser);
  }
}
