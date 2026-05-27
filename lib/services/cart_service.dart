import '../dto/shop/shop_dto.dart';
import '../handler/api_exception.dart';
import 'bigk/bigk_cart_service.dart';
import 'bigk/bigk_http_service.dart';

class CartService {
  static const String singleMerchantCartMessage =
      '购物车一次只能包含同一个商家的商品';

  static Future<Cart> getCart() async {
    try {
      final cart = await BigKCartService.getCart();
      return _mapCart(cart);
    } catch (e) {
      if (e is ApiException && (e.code == 401 || e.code == 403)) {
        return Cart.empty();
      }
      if (e is ApiException) {
        rethrow;
      }
      return Cart.empty();
    }
  }

  static Future<Cart> addItem(
    int productId, {
    int quantity = 1,
    int? variationId,
    Map<String, String>? variation,
  }) async {
    try {
      final cart = await BigKCartService.addItem(
        productId,
        quantity: quantity,
        variantId: variationId,
        options: variation,
      );
      return _mapCart(cart);
    } catch (e) {
      throw _normalizeError(e);
    }
  }

  static Future<Cart> updateItemQuantity(String itemKey, int quantity) async {
    final itemId = int.tryParse(itemKey);
    if (itemId == null) {
      throw ApiException(400, 'Invalid cart item id');
    }

    try {
      final cart = await BigKCartService.updateItemQuantity(itemId, quantity);
      return _mapCart(cart);
    } catch (e) {
      throw _normalizeError(e);
    }
  }

  static Future<Cart> removeItem(String itemKey) async {
    final itemId = int.tryParse(itemKey);
    if (itemId == null) {
      throw ApiException(400, 'Invalid cart item id');
    }

    try {
      final cart = await BigKCartService.removeItem(itemId);
      return _mapCart(cart);
    } catch (e) {
      throw _normalizeError(e);
    }
  }

  static Future<Cart> clearCart() async {
    try {
      final cart = await BigKCartService.clearCart();
      return _mapCart(cart);
    } catch (e) {
      throw _normalizeError(e);
    }
  }

  static Future<int> getItemCount() async {
    try {
      final cart = await getCart();
      return cart.itemCount;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> resetCart() async {
    BigKCartService.clearCache();
  }

  static Future<void> syncCartKeyAfterLogin() async {}

  static bool isSingleMerchantConflict(dynamic error) {
    if (error is ApiException) {
      return _isSingleMerchantConflict(error.message);
    }
    return _isSingleMerchantConflict(error?.toString() ?? '');
  }

  static Cart _mapCart(dynamic bigkCart) {
    return Cart(
      items: bigkCart.items.map<CartItem>(_mapItem).toList(growable: false),
      totals: CartTotals(
        subtotal: _formatAmount(bigkCart.subtotal),
        total: _formatAmount(bigkCart.total),
        taxTotal: '0.00',
        shippingTotal: '0.00',
        discountTotal: '0.00',
        currencyCode: bigkCart.currency,
        currencySymbol: _currencySymbol(bigkCart.currency),
      ),
      itemCount: bigkCart.itemCount,
    );
  }

  static CartItem _mapItem(dynamic item) {
    return CartItem(
      key: item.id.toString(),
      id: item.productId,
      name: item.productName,
      quantity: item.quantity,
      price: _formatAmount(item.price),
      lineTotal: _formatAmount(item.lineTotal),
      image: item.imageUrl,
      variationId: item.variantId,
      variation: _mapVariation(item),
    );
  }

  static Map<String, String> _mapVariation(dynamic item) {
    final variation = <String, String>{};

    if (item.variantName != null && item.variantName.toString().isNotEmpty) {
      variation['Variant'] = item.variantName.toString();
    }

    final options = item.options;
    if (options is Map) {
      for (final entry in options.entries) {
        final key = entry.key.toString();
        final value = entry.value?.toString() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          variation[key] = value;
        }
      }
    }

    return variation;
  }

  static String _formatAmount(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return double.tryParse(value?.toString() ?? '0')?.toStringAsFixed(2) ??
        '0.00';
  }

  static String _currencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'CNY':
        return '楼';
      default:
        return '$currencyCode ';
    }
  }

  static ApiException _normalizeError(dynamic error) {
    if (error is ApiException && (error.code == 401 || error.code == 403)) {
      if (BigKHttpService.hasValidToken) {
        return ApiException(error.code, '商城登录状态已失效，请重新登录后再试');
      }
      return ApiException(error.code, '商城身份未同步，请退出后重新登录再试');
    }

    if (error is ApiException && _isSingleMerchantConflict(error.message)) {
      return ApiException(error.code, singleMerchantCartMessage);
    }

    if (error is ApiException) {
      return error;
    }

    return ApiException(-1, error.toString());
  }

  static bool _isSingleMerchantConflict(String message) {
    final lower = message.toLowerCase();
    return lower.contains('cart can only contain items from one merchant');
  }
}
