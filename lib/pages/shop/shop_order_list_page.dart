import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../handler/api_exception.dart';
import '../../services/shop_order_service.dart';

class ShopOrderListPage extends StatefulWidget {
  const ShopOrderListPage({super.key});

  @override
  State<ShopOrderListPage> createState() => _ShopOrderListPageState();
}

class _ShopOrderListPageState extends State<ShopOrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['全部', '待付款', '处理中', '待收货', '已完成'];
  final Map<String, String> _statusMap = {
    '全部': '',
    '待付款': 'pending',
    '处理中': 'processing',
    '待收货': 'on-hold',
    '已完成': 'completed',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : Colors.white,
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
          '商城订单',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: isDark ? const Color(0xFFFFD54F) : Colors.black87,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: theme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return _OrderListTab(status: _statusMap[tab]!);
        }).toList(),
      ),
    );
  }
}

class _OrderListTab extends StatefulWidget {
  final String status;

  const _OrderListTab({required this.status});

  @override
  State<_OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<_OrderListTab>
    with AutomaticKeepAliveClientMixin {
  List<ShopOrder> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await ShopOrderService.getOrders(
        page: 1,
        perPage: 100,
        status: widget.status.isEmpty ? null : widget.status,
      );

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted && _shouldShowEmptyState(e)) {
        setState(() {
          _orders = const <ShopOrder>[];
          _error = null;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
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

  bool _shouldShowEmptyState(ApiException error) {
    final message = error.message.toLowerCase();
    if (error.code == 404) {
      return true;
    }

    return message.contains('no order') ||
        message.contains('no orders') ||
        message.contains('no record') ||
        message.contains('empty') ||
        message.contains('not found') ||
        message.contains('could not be found');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView(isDark);
    }

    if (_orders.isEmpty) {
      return _buildEmptyView(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index], isDark);
        },
      ),
    );
  }

  Widget _buildOrderCard(ShopOrder order, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '订单号 ${order.number}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              _buildStatusChip(order.status, isDark),
            ],
          ),
          SizedBox(height: 12.h),
          ...order.items.take(2).map((item) => _buildOrderItem(item, isDark)),
          if (order.items.length > 2)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                '共 ${order.items.length} 件商品',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            height: 24.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.dateCreated,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              Text(
                '合计: ${order.currency} ${order.total}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(ShopOrderItem item, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: item.image != null
                ? Image.network(
                    item.image!,
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                  )
                : _buildPlaceholder(isDark),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.price} x${item.quantity}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
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
      width: 50.w,
      height: 50.w,
      color: isDark ? Colors.white12 : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 20.w,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isDark) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: statusInfo.$2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        statusInfo.$1,
        style: TextStyle(
          fontSize: 11.sp,
          color: statusInfo.$2,
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return ('待付款', Colors.orange);
      case 'processing':
        return ('处理中', Colors.blue);
      case 'on-hold':
        return ('待收货', Colors.purple);
      case 'completed':
        return ('已完成', Colors.green);
      case 'cancelled':
        return ('已取消', Colors.grey);
      case 'refunded':
        return ('已退款', Colors.red);
      case 'failed':
        return ('失败', Colors.red);
      default:
        return (status, Colors.grey);
    }
  }

  Widget _buildEmptyView(bool isDark) {
    final emptyAreaMinHeight = MediaQuery.of(context).size.height * 0.55;
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Theme.of(context).primaryColor.withValues(alpha: 0.10);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : Theme.of(context).primaryColor.withValues(alpha: 0.85);

    return SizedBox.expand(
      child: Container(
        constraints: BoxConstraints(minHeight: emptyAreaMinHeight),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88.w,
                height: 88.w,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 44.w,
                  color: iconColor,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                '当前暂无商城订单',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '下单后，订单会显示在这里',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          SizedBox(height: 16.h),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          SizedBox(height: 8.h),
          ElevatedButton(
            onPressed: _loadOrders,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
