import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../dto/shop/shop_dto.dart';
import '../../services/shop_service.dart';
import '../../services/cart_service.dart';
import 'wishlist_page.dart';
import 'shop_main_page.dart';

/// 商品详情页
class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product _product;
  List<ProductVariation> _variations = [];
  ProductVariation? _selectedVariation;
  final Map<String, String> _selectedAttributes = {};
  int _quantity = 1;
  bool _isInWishlist = false;
  bool _isLoadingVariations = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadDetails();
    _checkWishlist();
  }

  Future<void> _loadDetails() async {
    // 加载变体（如果是变体商品）
    if (_product.type == 'variable' && _product.variations.isNotEmpty) {
      setState(() => _isLoadingVariations = true);
      try {
        final variations = await ShopService.getProductVariations(_product.id);
        if (mounted) {
          setState(() {
            _variations = variations;
            _isLoadingVariations = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingVariations = false);
        }
      }
    }
  }

  Future<void> _checkWishlist() async {
    final isIn = await WishlistPage.isInWishlist(_product.id);
    if (mounted) {
      setState(() => _isInWishlist = isIn);
    }
  }

  Future<void> _toggleWishlist() async {
    final newState = await WishlistPage.toggleWishlist(_product.id);
    if (mounted) {
      setState(() => _isInWishlist = newState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? '已添加到心愿单' : '已从心愿单移除'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _addToCart() async {
    if (!_product.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品已售罄')),
      );
      return;
    }

    // 变体商品检查
    if (_product.type == 'variable' && _selectedVariation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择商品规格')),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      await CartService.addItem(
        _product.id,
        quantity: _quantity,
        variationId: _selectedVariation?.id,
        variation: _selectedAttributes.isNotEmpty ? _selectedAttributes : null,
      );

      if (mounted) {
        // 更新购物车数量角标
        final shopMainState =
            context.findAncestorStateOfType<ShopMainPageState>();
        shopMainState?.refreshCartCount();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加到购物车')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _selectVariation() {
    // 根据选中的属性找到对应的变体
    if (_selectedAttributes.length != _product.attributes.length) {
      setState(() => _selectedVariation = null);
      return;
    }

    for (final variation in _variations) {
      bool match = true;
      for (final attr in variation.attributes) {
        if (_selectedAttributes[attr.name] != attr.option) {
          match = false;
          break;
        }
      }
      if (match) {
        setState(() => _selectedVariation = variation);
        return;
      }
    }

    setState(() => _selectedVariation = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      body: CustomScrollView(
        slivers: [
          // 顶部图片区域
          _buildImageSliver(isDark),
          // 商品信息
          SliverToBoxAdapter(
            child: _buildProductInfo(theme, isDark),
          ),
          // 商品描述
          SliverToBoxAdapter(
            child: _buildDescription(isDark),
          ),
          // 底部占位
          SliverToBoxAdapter(
            child: SizedBox(height: 100.h),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme, isDark),
    );
  }

  Widget _buildImageSliver(bool isDark) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor:
          isDark ? Theme.of(context).appBarTheme.backgroundColor : Colors.white,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.black38 : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
            size: 20.w,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.black38 : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_outline,
              color: _isInWishlist
                  ? Colors.red
                  : (isDark ? Colors.white : Colors.black87),
              size: 20.w,
            ),
          ),
          onPressed: _toggleWishlist,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGallery(isDark),
      ),
    );
  }

  Widget _buildImageGallery(bool isDark) {
    if (_product.images.isEmpty) {
      return Container(
        color: isDark ? Colors.white12 : Colors.grey.shade100,
        child: Icon(
          Icons.image_outlined,
          size: 64.w,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      );
    }

    // 简单的图片画廊（可扩展为 PageView）
    return PageView.builder(
      itemCount: _product.images.length,
      itemBuilder: (context, index) {
        return Image.network(
          _product.images[index].src,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: isDark ? Colors.white12 : Colors.grey.shade100,
            child: Icon(
              Icons.broken_image_outlined,
              size: 64.w,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfo(ThemeData theme, bool isDark) {
    final displayPrice = _selectedVariation?.price ?? _product.price;
    final displayRegularPrice =
        _selectedVariation?.regularPrice ?? _product.regularPrice;
    final hasDiscount = _selectedVariation?.hasDiscount ?? _product.hasDiscount;
    final salePrice = _selectedVariation?.salePrice ?? _product.salePrice;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品名称
          Text(
            _product.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          // 价格
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${hasDiscount ? salePrice : displayPrice}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: hasDiscount
                      ? Colors.redAccent
                      : (isDark ? const Color(0xFFFFD54F) : theme.primaryColor),
                ),
              ),
              if (hasDiscount) ...[
                SizedBox(width: 8.w),
                Text(
                  '¥$displayRegularPrice',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.62)
                        : Colors.black38,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          // 库存状态
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: _product.inStock ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                _product.inStock ? '有货' : '已售罄',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              if (_product.stockQuantity != null && _product.inStock) ...[
                SizedBox(width: 8.w),
                Text(
                  '库存 ${_product.stockQuantity} 件',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.black45,
                  ),
                ),
              ],
            ],
          ),
          // 变体选择
          if (_product.attributes.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _buildAttributeSelector(isDark),
          ],
          // 数量选择
          SizedBox(height: 20.h),
          _buildQuantitySelector(isDark),
        ],
      ),
    );
  }

  Widget _buildAttributeSelector(bool isDark) {
    if (_isLoadingVariations) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _product.attributes.where((attr) => attr.variation).map((attr) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attr.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: attr.options.map((option) {
                final isSelected = _selectedAttributes[attr.name] == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAttributes[attr.name] = option;
                    });
                    _selectVariation();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8.r),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isSelected
                            ? Colors.black87
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector(bool isDark) {
    return Row(
      children: [
        Text(
          '数量',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              _buildQtyButton(
                Icons.remove,
                () {
                  if (_quantity > 1) {
                    setState(() => _quantity--);
                  }
                },
                isDark,
              ),
              Container(
                width: 48.w,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              _buildQtyButton(
                Icons.add,
                () => setState(() => _quantity++),
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18.w,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDescription(bool isDark) {
    if (_product.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          SizedBox(height: 8.h),
          Text(
            '商品详情',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Html(
            data: _product.description,
            style: {
              'body': Style(
                fontSize: FontSize(14.sp),
                color: isDark ? Colors.white70 : Colors.black87,
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              'img': Style(
                width: Width(100, Unit.percent),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? theme.cardTheme.color : Colors.white,
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
            // 客服按钮
            _buildActionButton(
              Icons.chat_outlined,
              '客服',
              () {
                // TODO: 客服功能
              },
              isDark,
            ),
            SizedBox(width: 12.w),
            // 购物车按钮
            _buildActionButton(
              Icons.shopping_cart_outlined,
              '购物车',
              () {
                // 返回并传递切换到购物车 Tab 的信号
                Navigator.pop(context, 'cart');
              },
              isDark,
            ),
            SizedBox(width: 12.w),
            // 加入购物车
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: ElevatedButton(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : theme.primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isAddingToCart
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        )
                      : Text(
                          '加入购物车',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22.w,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
