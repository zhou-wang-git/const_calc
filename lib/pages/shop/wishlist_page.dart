import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../dto/shop/shop_dto.dart';
import '../../handler/api_exception.dart';
import '../../services/cart_service.dart';
import '../../services/bigk/bigk_wishlist_service.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';
import '../../widgets/shop/shop_empty_state.dart';
import 'product_detail_page.dart';
import 'shop_main_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => WishlistPageState();

  static Future<void> addProduct(int productId) async {
    await BigKWishlistService.addToWishlist(productId);
  }

  static Future<void> removeProduct(int productId) async {
    final wishlist = await BigKWishlistService.getWishlist();
    for (final item in wishlist.items) {
      if (item.productId == productId) {
        await BigKWishlistService.removeFromWishlist(item.id);
        return;
      }
    }
  }

  static Future<bool> isInWishlist(int productId) async {
    try {
      final cached = BigKWishlistService.getCachedWishlist();
      if (cached != null) {
        return cached.containsProduct(productId);
      }
      return await BigKWishlistService.checkWishlist(productId);
    } catch (e) {
      if (e is ApiException && (e.code == 401 || e.code == 403)) {
        return false;
      }
      rethrow;
    }
  }

  static Future<bool> toggleWishlist(int productId) async {
    final response = await BigKWishlistService.toggleWishlist(productId);
    if (response.isInWishlist != null) {
      return response.isInWishlist!;
    }
    return isInWishlist(productId);
  }
}

class WishlistPageState extends State<WishlistPage> {
  List<Product> _products = [];
  final Set<int> _addingProductIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> refresh() => _loadWishlist();

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wishlist = await BigKWishlistService.getWishlist();
      final products = <Product>[];

      for (final item in wishlist.items) {
        try {
          if (item.product != null) {
            products.add(ShopService.mapBigKProduct(item.product!));
            continue;
          }

          final product = await ShopService.getProduct(item.productId);
          products.add(product);
        } catch (e) {
          debugPrint(
            'WishlistPage: failed to load wishlist product '
            '${item.productId}: $e',
          );
        }
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          if (wishlist.items.isNotEmpty && products.isEmpty) {
            _error = '心愿单商品加载失败，请稍后重试';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && (e.code == 401 || e.code == 403)) {
          setState(() {
            _products = [];
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromWishlist(Product product) async {
    await WishlistPage.removeProduct(product.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _products.removeWhere((p) => p.id == product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView(isDark);
    }

    if (_products.isEmpty) {
      return _buildEmptyView(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadWishlist,
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.58,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildWishlistItem(product, isDark);
        },
      ),
    );
  }

  Widget _buildWishlistItem(Product product, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ProductCard(
                  product: product,
                  onTap: () => _navigateToProduct(product),
                ),
              ),
              Positioned(
                top: 8.w,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => _removeFromWishlist(product),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 18.w,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          height: 34.h,
          child: ElevatedButton.icon(
            onPressed:
                product.inStock && !_addingProductIds.contains(product.id)
                    ? () => _addToCart(product)
                    : null,
            icon: _addingProductIds.contains(product.id)
                ? SizedBox(
                    width: 13.w,
                    height: 13.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.shopping_bag_outlined, size: 15.w),
            label: Text(
              product.inStock ? '加入购物车' : '已售罄',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor:
                  isDark ? Colors.white : Theme.of(context).colorScheme.primary,
              foregroundColor: isDark ? Colors.black87 : Colors.white,
              disabledBackgroundColor:
                  isDark ? Colors.white12 : Colors.grey.shade200,
              disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return ShopEmptyState(
      asset: 'assets/icons/shop_empty_wishlist.svg',
      title: '暂无心愿',
      subtitle: '把喜欢的商品加入心愿单，之后可以快速找到。',
      actionText: '去添加商品',
      onAction: _openProductListTab,
      carded: true,
    );
  }

  Widget _buildErrorView(bool isDark) {
    return ShopEmptyState(
      asset: 'assets/icons/shop_empty_error.svg',
      title: '心愿单加载失败',
      subtitle: '网络或登录状态可能异常，请稍后重试。',
      actionText: '重试',
      onAction: _loadWishlist,
    );
  }

  void _navigateToProduct(Product product) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );

    if (result == 'cart' && mounted) {
      final shopMainState =
          context.findAncestorStateOfType<ShopMainPageState>();
      shopMainState?.switchToTab(3);
    }
  }

  void _openProductListTab() {
    final shopMainState = context.findAncestorStateOfType<ShopMainPageState>();
    shopMainState?.switchToTab(1);
  }

  Future<void> _addToCart(Product product) async {
    setState(() => _addingProductIds.add(product.id));

    try {
      await CartService.addItem(product.id);
      if (!mounted) {
        return;
      }
      context.findAncestorStateOfType<ShopMainPageState>()?.refreshCartCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入购物车')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加入购物车失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _addingProductIds.remove(product.id));
      }
    }
  }
}
