import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../dto/shop/shop_dto.dart';
import '../../services/shop_order_service.dart';

/// 结算页面
class CheckoutPage extends StatefulWidget {
  final Cart cart;

  const CheckoutPage({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  String _selectedPayment = 'stripe'; // 默认 Stripe

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '确认订单',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  // 商品列表
                  _buildItemsSection(isDark),
                  SizedBox(height: 12.h),
                  // 价格明细
                  _buildPriceSection(isDark),
                  SizedBox(height: 12.h),
                  // 支付方式
                  _buildPaymentSection(isDark),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          // 底部提交栏
          _buildBottomBar(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: child,
    );
  }

  Widget _buildItemsSection(bool isDark) {
    return _buildSection(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '商品清单',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          ...widget.cart.items.map((item) => _buildOrderItem(item, isDark)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // 图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: item.image != null
                ? Image.network(
                    item.image!,
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                  )
                : _buildPlaceholder(isDark),
          ),
          SizedBox(width: 12.w),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variationDescription.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.variationDescription,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¥${item.price}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 60.w,
      height: 60.w,
      color: isDark ? Colors.white12 : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 24.w,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }

  Widget _buildPriceSection(bool isDark) {
    final totals = widget.cart.totals;

    return _buildSection(
      isDark: isDark,
      child: Column(
        children: [
          _buildPriceRow('商品小计', totals.formattedSubtotal, isDark),
          if (double.tryParse(totals.shippingTotal) != 0)
            _buildPriceRow('运费', '¥${totals.shippingTotal}', isDark),
          if (double.tryParse(totals.discountTotal) != 0)
            _buildPriceRow(
              '优惠',
              '-¥${totals.discountTotal}',
              isDark,
              isDiscount: true,
            ),
          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            height: 24.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '合计',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                totals.formattedTotal,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDark,
      {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount ? Colors.green : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(bool isDark) {
    return _buildSection(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支付方式',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          // Stripe 支付
          _buildPaymentOption(
            Icons.credit_card,
            '信用卡/借记卡',
            'stripe',
            _selectedPayment == 'stripe',
            isDark,
          ),
          SizedBox(height: 8.h),
          _buildPaymentOption(
            Icons.account_balance_wallet,
            'Google Pay',
            'google_pay',
            _selectedPayment == 'google_pay',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    IconData icon,
    String label,
    String value,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPayment = value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : (isDark ? Colors.white12 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                icon,
                size: 18.w,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: 2,
                ),
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12.w,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
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
            // 总价
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '应付金额',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    widget.cart.totals.formattedTotal,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // 提交按钮
            SizedBox(
              width: 140.w,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : theme.primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        '提交订单',
                        style: TextStyle(
                          fontSize: 16.sp,
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

  Future<void> _submitOrder() async {
    setState(() => _isProcessing = true);

    try {
      // 调用 ShopOrderService 创建订单并发起 Stripe 支付
      final success = await ShopOrderService.createOrderAndPay(context);

      if (success && mounted) {
        // 支付成功，返回商城首页并显示成功提示
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('支付成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
