import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../dto/shop/shop_dto.dart';

/// 商品卡片组件
/// 用于首页和商品列表展示
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showWishlistButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showWishlistButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.10))
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            Expanded(
              flex: 3,
              child: _buildImage(isDark),
            ),
            // 商品信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名称
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // 价格
                    _buildPrice(theme, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 图片
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
          child: product.mainImageUrl != null
              ? Image.network(
                  product.mainImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildPlaceholder(isDark);
                  },
                )
              : _buildPlaceholder(isDark),
        ),
        // 折扣标签
        if (product.hasDiscount)
          Positioned(
            top: 8.w,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '-${product.discountPercent}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // 虚拟商品标签
        if (product.isVirtualProduct)
          Positioned(
            top: 8.w,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '虚拟商品',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // 售罄标签
        if (!product.inStock)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              ),
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '已售罄',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.grey.shade100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 40.w,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }

  Widget _buildPrice(ThemeData theme, bool isDark) {
    if (product.hasDiscount) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '¥${product.salePrice}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '¥${product.regularPrice}',
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.62)
                  : Colors.black38,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    return Text(
      '¥${product.price}',
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFFFD54F) : theme.primaryColor,
      ),
    );
  }
}
