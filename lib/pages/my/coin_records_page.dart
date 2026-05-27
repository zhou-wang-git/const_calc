import 'package:flutter/material.dart';

import '../../dto/coin_record.dart';
import '../../services/coin_service.dart';
import '../../util/http_util.dart';

/// 积分记录页面
class CoinRecordsPage extends StatefulWidget {
  const CoinRecordsPage({super.key});

  @override
  State<CoinRecordsPage> createState() => _CoinRecordsPageState();
}

class _CoinRecordsPageState extends State<CoinRecordsPage> {
  final List<CoinRecord> _records = [];
  int _currentPage = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _selectedType = 0; // 0=全部

  final ScrollController _scrollController = ScrollController();

  // 类型选项
  final List<Map<String, dynamic>> _typeOptions = [
    {'value': 0, 'label': '全部'},
    {'value': 1, 'label': '充值'},
    {'value': 2, 'label': '会员赠送'},
    {'value': 3, 'label': '消费'},
    {'value': 4, 'label': '活动赠送'},
    {'value': 5, 'label': '新用户赠送'},
    {'value': 6, 'label': '签到'},
    {'value': 7, 'label': '邀请奖励'},
    {'value': 8, 'label': '退款'},
    {'value': 9, 'label': '管理员调整'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _records.clear();
    });

    try {
      final result = await HttpUtil.request<CoinRecordPage>(
        () => CoinService.getRecords(
          page: 1,
          pageSize: 20,
          type: _selectedType,
        ),
        context,
        () => mounted,
      );

      if (!mounted) return;

      setState(() {
        _records.addAll(result?.list ?? []);
        _total = result?.total ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _records.length >= _total) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await CoinService.getRecords(
        page: _currentPage + 1,
        pageSize: 20,
        type: _selectedType,
      );

      if (!mounted) return;

      setState(() {
        _currentPage++;
        _records.addAll(result.list);
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onTypeChanged(int type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('能量点记录'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 类型筛选
          _buildTypeFilter(theme, isDark),

          // 记录列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == _records.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            return _buildRecordCard(_records[index], theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(ThemeData theme, bool isDark) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _typeOptions.length,
        itemBuilder: (context, index) {
          final option = _typeOptions[index];
          final isSelected = _selectedType == option['value'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(option['label']),
              selected: isSelected,
              onSelected: (_) => _onTypeChanged(option['value']),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无能量点记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(CoinRecord record, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 类型图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: record.isIncome
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(record.type),
              color: record.isIncome ? Colors.green : Colors.red,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // 详情
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.typeName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                if (record.remark != null && record.remark!.isNotEmpty)
                  Text(
                    record.remark!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  record.addTimeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // 积分变动
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.coinsFormatted,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: record.isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '余额: ${record.balance}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(int type) {
    switch (type) {
      case 1:
        return Icons.add_card; // 充值
      case 2:
        return Icons.card_giftcard; // 会员赠送
      case 3:
        return Icons.shopping_cart; // 消费
      case 4:
        return Icons.celebration; // 活动赠送
      case 5:
        return Icons.person_add; // 新用户赠送
      case 6:
        return Icons.calendar_today; // 签到
      case 7:
        return Icons.group_add; // 邀请奖励
      case 8:
        return Icons.replay; // 退款
      case 9:
        return Icons.admin_panel_settings; // 管理员调整
      default:
        return Icons.monetization_on;
    }
  }
}
