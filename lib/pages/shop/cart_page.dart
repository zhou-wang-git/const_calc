import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../dto/shop/shop_dto.dart';
import '../../services/cart_service.dart';
import '../../widgets/shop/shop_empty_state.dart';
import 'checkout_page.dart';
import 'shop_main_page.dart';

/// 购物车页面
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  Cart? _cart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  /// 公开的刷新方法，供外部调用
  void refresh() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cart = await CartService.getCart();
      if (mounted) {
        setState(() {
          _cart = cart;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int delta) async {
    final newQuantity = item.quantity + delta;
    if (newQuantity < 1) {
      _removeItem(item);
      return;
    }

    try {
      await CartService.updateItemQuantity(item.key, newQuantity);
      _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除商品'),
        content: Text('确定要从购物车中移除 "${item.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CartService.removeItem(item.key);
      _loadCart();
      // 通知父组件刷新购物车数量
      final shopMainState = context.findAncestorStateOfType<ShopMainPageState>();
      shopMainState?.refreshCartCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }

  void _goToCheckout() {
    if (_cart == null || _cart!.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(cart: _cart!),
      ),
    );
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

    if (_cart == null || _cart!.isEmpty) {
      return _buildEmptyView(isDark);
    }

    return Column(
      children: [
        // 购物车列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCart,
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: _cart!.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                return _buildCartItem(_cart!.items[index], isDark);
              },
            ),
          ),
        ),
        // 底部结算栏
        _buildBottomBar(isDark),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: item.image != null
                ? Image.network(
                    item.image!,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                  )
                : _buildPlaceholder(isDark),
          ),
          SizedBox(width: 12.w),
          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variationDescription.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    item.variationDescription,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 价格
                    Text(
                      '¥${item.price}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Theme.of(context).primaryColor,
                      ),
                    ),
                    // 数量控制
                    _buildQuantityControl(item, isDark),
                  ],
                ),
              ],
            ),
          ),
          // 删除按钮
          GestureDetector(
            onTap: () => _removeItem(item),
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(
                Icons.close,
                size: 20.w,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 80.w,
      height: 80.w,
      color: isDark ? Colors.white12 : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 32.w,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            Icons.remove,
            () => _updateQuantity(item, -1),
            isDark,
          ),
          Container(
            width: 36.w,
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          _buildQuantityButton(
            Icons.add,
            () => _updateQuantity(item, 1),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16.w,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 总价
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '合计',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    _cart?.totals.formattedTotal ?? '¥0',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // 结算按钮
            SizedBox(
              width: 120.w,
              height: 44.h,
              child: ElevatedButton(
                onPressed: _goToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? Colors.white : Theme.of(context).primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '去结算(${_cart?.itemCount ?? 0})',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return ShopEmptyState(
      asset: 'assets/icons/shop_empty_cart.svg',
      title: '购物车是空的',
      subtitle: '去商城挑选商品，添加后会显示在这里。',
      actionText: '去添加商品',
      onAction: _openProductListTab,
    );
  }

  Widget _buildErrorView(bool isDark) {
    return ShopEmptyState(
      asset: 'assets/icons/shop_empty_error.svg',
      title: '购物车加载失败',
      subtitle: '网络或登录状态可能异常，请稍后重试。',
      actionText: '重试',
      onAction: _loadCart,
    );
  }

  void _openProductListTab() {
    final shopMainState = context.findAncestorStateOfType<ShopMainPageState>();
    shopMainState?.switchToTab(1);
  }
}
