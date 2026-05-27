import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_cart.dart';
import 'bigk_http_service.dart';

class BigKCartService {
  static BigKCart? _cachedCart;

  static Future<BigKCart> getCart() async {
    debugPrint('BigKCartService: Fetching cart...');

    final cart = await BigKHttpService.get<BigKCart>(
      '/app/cart',
      (data) => BigKCart.fromJson(data),
    );

    _cachedCart = cart;
    return cart;
  }

  static BigKCart? getCachedCart() => _cachedCart;

  static Future<BigKCart> addItem(
    int productId, {
    int quantity = 1,
    int? variantId,
    Map<String, dynamic>? options,
  }) async {
    debugPrint('BigKCartService: Adding product $productId to cart...');

    await BigKHttpService.post<BigKAddToCartResponse>(
      '/app/cart/items',
      {
        'product_id': productId,
        'quantity': quantity,
        if (variantId != null) 'variant_id': variantId,
        if (options != null && options.isNotEmpty) 'options': options,
      },
      (data) => BigKAddToCartResponse.fromJson(data),
    );

    return getCart();
  }

  static Future<BigKCart> updateItemQuantity(int itemId, int quantity) async {
    debugPrint(
        'BigKCartService: Updating item $itemId quantity to $quantity...');

    await BigKHttpService.put<Map<String, dynamic>>(
      '/app/cart/items/$itemId',
      {'quantity': quantity},
      (data) => Map<String, dynamic>.from(data as Map),
    );

    return getCart();
  }

  static Future<BigKCart> removeItem(int itemId) async {
    debugPrint('BigKCartService: Removing item $itemId from cart...');

    await BigKHttpService.delete<Map<String, dynamic>>(
      '/app/cart/items/$itemId',
      (data) => Map<String, dynamic>.from(data as Map),
    );

    return getCart();
  }

  static Future<BigKCart> clearCart() async {
    debugPrint('BigKCartService: Clearing cart...');

    await BigKHttpService.delete<Map<String, dynamic>>(
      '/app/cart',
      (data) => Map<String, dynamic>.from(data as Map),
    );

    _cachedCart = BigKCart.empty();
    return _cachedCart!;
  }

  static Future<int> getItemCount() async {
    try {
      final cart = await getCart();
      return cart.itemCount;
    } catch (_) {
      return 0;
    }
  }

  static void clearCache() {
    _cachedCart = null;
    debugPrint('BigKCartService: Cache cleared');
  }
}
