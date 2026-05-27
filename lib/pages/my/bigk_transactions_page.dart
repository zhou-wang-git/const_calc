import 'package:flutter/material.dart';

import '../../dto/bigk/bigk_transaction.dart';
import '../../services/bigk/bigk_wallet_service.dart';
import '../../util/message_util.dart';

class BigKTransactionsPage extends StatefulWidget {
  const BigKTransactionsPage({super.key});

  @override
  State<BigKTransactionsPage> createState() => _BigKTransactionsPageState();
}

class _BigKTransactionsPageState extends State<BigKTransactionsPage> {
  final List<BigKTransaction> _transactions = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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
        _scrollController.position.maxScrollExtent - 160) {
      _loadMore();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _lastPage = 1;
      _transactions.clear();
    });

    try {
      final page =
          await BigKWalletService.getTransactions(page: 1, perPage: 20);
      if (!mounted) return;

      setState(() {
        _transactions.addAll(page.data);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      MessageUtil.error(context, '加载钱包交易记录失败: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final page = await BigKWalletService.getTransactions(
        page: nextPage,
        perPage: 20,
      );
      if (!mounted) return;

      setState(() {
        _transactions.addAll(page.data);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      MessageUtil.error(context, '加载更多交易失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('BigK 钱包记录'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == _transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      return _buildTransactionCard(
                        _transactions[index],
                        theme,
                        isDark,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            '暂无 BigK 钱包交易记录',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BigKTransaction transaction,
    ThemeData theme,
    bool isDark,
  ) {
    final isIncome = transaction.isIncome;
    final accentColor = isIncome ? Colors.green : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : transaction.statusName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.postedAtFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.amountFormatted,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
