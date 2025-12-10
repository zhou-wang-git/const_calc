import 'package:const_calc/services/my_service.dart';
import 'package:flutter/material.dart';

// 引入我们新建的筛选条组件
import '../../dto/order_record.dart';
import '../../util/http_util.dart';
import './order_list_search_filter_bar.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPage();
}

class _OrderListPage extends State<OrderListPage> {
  final List<OrderRecord> orders = [];
  final ScrollController _scrollController = ScrollController();

  int _page = 1; // 当前页码
  final int _pageSize = 10; // 每页数量
  bool _isLoading = false; // 是否正在加载
  bool _hasMore = true; // 是否还有更多数据

  // 🔹 新增：保存最近一次筛选条件
  OrderListSearchFilterParams _lastParams = OrderListSearchFilterParams();

  @override
  void initState() {
    super.initState();

    // 首次加载
    _initOrderList();

    // 监听滚动到底部
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  Future<void> _initOrderList() async {
    _page = 1;
    _hasMore = true; // 重新查询时重置
    orders.clear();
    await _fetchData();
  }

  Future<void> _loadMore() async {
    _page++;
    await _fetchData();
  }

  /// 拉取数据（透传筛选条件）
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // 模拟网络延迟（保留原逻辑）
    await Future.delayed(const Duration(seconds: 1));

    // 仅传递非空筛选项
    final q = _lastParams.toQuery();

    // ⚠️ 假设 MyService.getOrderList 支持这些命名参数；
    // 如果你的服务端参数名不同，请把下面的命名参数名改成你的真实签名。
    List<OrderRecord>? fetched = await HttpUtil.request<List<OrderRecord>?>(
      () => MyService.getOrderList(
        pageNo: _page.toString(),
        pageSize: _pageSize.toString(),
        keyword: q['keyword'],
        orderSn: q['orderSn'],
        payEmail: q['payEmail'],
        payName: q['payName'],
        payTimeStart: q['payTimeStart'],
        payTimeEnd: q['payTimeEnd'],
        amountStart: q['amountStart'],
        amountEnd: q['amountEnd'],
      ),
      // ignore: use_build_context_synchronously
      context,
      () => mounted,
    );

    if (fetched == null) return;

    if (fetched.length < _pageSize) {
      _hasMore = false; // 没有更多了
    }

    setState(() {
      orders.addAll(fetched);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '消费记录',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0.5,
      ),
      // 🔹 把筛选条放在列表上方；下方保留原 Refresh + List + 分页加载样式
      body: Column(
        children: [
          OrderListSearchFilterBar(
            onSearch: (p) {
              _lastParams = p;
              _initOrderList(); // 条件变更后重查
            },
          ),
          Expanded(
            child: orders.isEmpty && !_isLoading
                ? _buildEmptyView(context)
                : RefreshIndicator(
                    onRefresh: _initOrderList,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.length + (_hasMore ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (!_hasMore && index == orders.length) {
                          return _buildNoMore(); // 只有没更多时才显示
                        }
                        final order = orders[index];
                        return _buildOrderItem(order);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderRecord order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            offset: const Offset(0, 2),
            color: isDark ? Colors.black26 : const Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题+状态
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFDFF4E3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Text(
                    '支付成功',
                    style: TextStyle(color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4CAF50), fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$${order.amount}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFFFC107),
            ),
          ),
          const SizedBox(height: 6),
          _buildInfoRow("订单号", order.orderSn, isDark),
          _buildInfoRow("支付方式", _mapPayMethod(order.source), isDark),
          _buildInfoRow("支付邮箱", order.email, isDark),
          _buildInfoRow("支付姓名", order.name, isDark),
          _buildInfoRow("支付时间", order.payTime, isDark),
        ],
      ),
    );
  }

  /// 空页面
  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height >= size.width;
    final imgWidth = size.width * (isPortrait ? 0.6 : 0.4);

    return Column(
      children: [
        const Spacer(flex: 2),
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/icons/order_empty.png',
                width: imgWidth,
                fit: BoxFit.contain,
                color: isDark ? Colors.white70 : null,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无消费记录',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        "$label：$value",
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.black87,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildNoMore() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text('没有更多了', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
      ),
    );
  }

  /// 支付方式映射
  String _mapPayMethod(int source) {
    switch (source) {
      case 1:
        return '网页';
      case 2:
        return 'APP';
      default:
        return '其它';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
