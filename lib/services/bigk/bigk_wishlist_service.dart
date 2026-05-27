import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_wishlist.dart';
import 'bigk_http_service.dart';

class BigKWishlistService {
  static BigKWishlist? _cachedWishlist;

  static Future<BigKWishlist> getWishlist() async {
    debugPrint('BigKWishlistService: Fetching wishlist...');

    final wishlist = await BigKHttpService.get<BigKWishlist>(
      '/app/wishlist',
      (data) => BigKWishlist.fromJson(data),
    );

    _cachedWishlist = wishlist;
    return wishlist;
  }

  static BigKWishlist? getCachedWishlist() => _cachedWishlist;

  static Future<BigKWishlistResponse> addToWishlist(int productId) async {
    debugPrint('BigKWishlistService: Adding product $productId to wishlist...');

    final response = await BigKHttpService.post<BigKWishlistResponse>(
      '/app/wishlist',
      {'product_id': productId},
      (data) => BigKWishlistResponse.fromJson(data),
    );

    _cachedWishlist = null;
    return response;
  }

  static Future<BigKWishlistResponse> toggleWishlist(int productId) async {
    debugPrint(
        'BigKWishlistService: Toggling wishlist for product $productId...');

    final response = await BigKHttpService.post<BigKWishlistResponse>(
      '/app/wishlist/toggle',
      {'product_id': productId},
      (data) => BigKWishlistResponse.fromJson(data),
    );

    _cachedWishlist = null;
    return response;
  }

  static Future<BigKWishlistResponse> removeFromWishlist(int itemId) async {
    debugPrint('BigKWishlistService: Removing wishlist item $itemId...');

    final response = await BigKHttpService.delete<BigKWishlistResponse>(
      '/app/wishlist/$itemId',
      (data) => BigKWishlistResponse.fromJson(data),
    );

    _cachedWishlist = null;
    return response;
  }

  static Future<bool> checkWishlist(int productId) async {
    final response = await BigKHttpService.get<Map<String, dynamic>>(
      '/app/wishlist/check/$productId',
      (data) => Map<String, dynamic>.from(data as Map),
    );
    return response['in_wishlist'] == true;
  }

  static bool isInWishlist(int productId) {
    if (_cachedWishlist == null) return false;
    return _cachedWishlist!.containsProduct(productId);
  }

  static void clearCache() {
    _cachedWishlist = null;
    debugPrint('BigKWishlistService: Cache cleared');
  }
}
