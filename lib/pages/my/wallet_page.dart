import 'package:flutter/material.dart';

import '../../dto/bigk/bigk_transaction.dart';
import '../../dto/bigk/bigk_wallet.dart';
import '../../services/bigk/bigk_auth_service.dart';
import '../../services/bigk/bigk_wallet_service.dart';
import '../../services/shop_session_service.dart';
import '../../util/dialog_util.dart';
import '../../util/message_util.dart';
import 'bigk_beneficiaries_page.dart';
import 'bigk_inbox_page.dart';
import 'bigk_profile_settings_page.dart';
import 'bigk_topup_page.dart';
import 'bigk_transactions_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  BigKWallet? _bigkWallet;
  List<BigKTransaction> _recentBigKTransactions = const <BigKTransaction>[];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    if (!BigKAuthService().isLinked) {
      if (!mounted) {
        return;
      }

      setState(() {
        _bigkWallet = null;
        _recentBigKTransactions = const <BigKTransaction>[];
        _loadError = '请先登录 KCC 后再打开钱包。';
        _isLoading = false;
      });
      return;
    }

    try {
      final section = await _loadBigKSection();
      if (!mounted) {
        return;
      }

      setState(() {
        _bigkWallet = section.wallet;
        _recentBigKTransactions = section.transactions;
        _isLoading = false;
      });
    } on MallWalletProvisionRequiredException {
      final shouldCreate = await _confirmWalletProvision();
      if (!mounted) {
        return;
      }

      if (!shouldCreate) {
        setState(() {
          _bigkWallet = null;
          _recentBigKTransactions = const <BigKTransaction>[];
          _loadError = '当前账号尚未创建钱包。';
          _isLoading = false;
        });
        return;
      }

      try {
        final section = await _loadBigKSection(createWalletIfMissing: true);
        if (!mounted) {
          return;
        }

        MessageUtil.success(context, '钱包已创建。');
        setState(() {
          _bigkWallet = section.wallet;
          _recentBigKTransactions = section.transactions;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) {
          return;
        }

        setState(() {
          _bigkWallet = null;
          _recentBigKTransactions = const <BigKTransaction>[];
          _loadError = '加载钱包失败：$e';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _bigkWallet = null;
        _recentBigKTransactions = const <BigKTransaction>[];
        _loadError = '加载钱包失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _confirmWalletProvision() {
    return DialogUtil.confirm(
      context,
      title: '创建钱包',
      content: '检测到当前账号还没有钱包，是否现在为您创建？',
      cancelText: '暂不创建',
      confirmText: '立即创建',
    );
  }

  Future<_BigKWalletSection> _loadBigKSection({
    bool createWalletIfMissing = false,
  }) async {
    await ShopSessionService().ensureMallSession(
      createWalletIfMissing: createWalletIfMissing,
    );
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      BigKWalletService.getWallet(forceRefresh: true),
      BigKWalletService.getTransactions(page: 1, perPage: 5),
    ]);

    return _BigKWalletSection(
      wallet: results[0] as BigKWallet,
      transactions: (results[1] as BigKTransactionPage).data,
    );
  }

  Future<void> _openBigKTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BigKTransactionsPage()),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openProfileSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BigKProfileSettingsPage()),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openBeneficiaries() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BigKBeneficiariesPage()),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openInbox() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BigKInboxPage()),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openTopUp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BigKTopUpPage()),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _showTransferDialog() async {
    final handleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isSubmitting = false;

    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                final handle = handleController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                final note = noteController.text.trim();

                if (handle.isEmpty) {
                  MessageUtil.info(dialogContext, '请输入收款方 Handle。');
                  return;
                }
                if (amount == null || amount <= 0) {
                  MessageUtil.info(dialogContext, '请输入有效金额。');
                  return;
                }

                setDialogState(() => isSubmitting = true);
                try {
                  final result = await BigKWalletService.transfer(
                    recipientHandle: handle,
                    amount: amount,
                    note: note,
                  );

                  if (!mounted || !dialogContext.mounted) {
                    return;
                  }

                  MessageUtil.success(
                    context,
                    result.message?.isNotEmpty == true
                        ? result.message!
                        : '转账已完成。',
                  );
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() => isSubmitting = false);
                  MessageUtil.error(dialogContext, '转账失败：$e');
                }
              }

              return AlertDialog(
                title: const Text('转账'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: handleController,
                        decoration: const InputDecoration(
                          labelText: '收款方 Handle',
                          hintText: '@用户名',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: '金额',
                          hintText: '0.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: '备注',
                          hintText: '选填',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('确认'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (submitted == true && mounted) {
        _loadData();
      }
    } finally {
      handleController.dispose();
      amountController.dispose();
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的钱包'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: <Widget>[
                  if (_bigkWallet != null) ...<Widget>[
                    _buildBigKCard(isDark),
                    const SizedBox(height: 16),
                    _buildBigKActions(theme),
                    const SizedBox(height: 16),
                    _buildBigKTransactionSection(theme, isDark),
                  ] else
                    _buildWalletUnavailable(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildBigKCard(bool isDark) {
    const gold = Color(0xFFD6A94A);
    const softGold = Color(0xFFF0D38A);
    const deepInk = Color(0xFF17130B);
    const deepBrown = Color(0xFF32220E);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[deepInk, deepBrown, Color(0xFF5B3D13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -48,
              top: -42,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withValues(alpha: 0.20),
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: -34,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: softGold.withValues(alpha: 0.18),
                    width: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: softGold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      _bigkWallet?.tierName ?? 'Standard',
                      style: const TextStyle(
                        color: softGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'BigK 钱包',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        _bigkWallet?.balanceFormatted ?? '0.00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'KCC',
                          style: TextStyle(
                            color: softGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    <String>[
                      if ((_bigkWallet?.handle ?? '').isNotEmpty)
                        '@${_bigkWallet!.handle}',
                      if ((_bigkWallet?.email ?? '').isNotEmpty)
                        _bigkWallet!.email!,
                    ].join('  |  '),
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigKActions(ThemeData theme) {
    final actions = <_WalletActionItem>[
      _WalletActionItem(
        icon: Icons.send_outlined,
        label: '转账',
        onTap: _showTransferDialog,
      ),
      _WalletActionItem(
        icon: Icons.receipt_long_outlined,
        label: '记录',
        onTap: _openBigKTransactions,
      ),
      _WalletActionItem(
        icon: Icons.person_outline,
        label: '资料',
        onTap: _openProfileSettings,
      ),
      _WalletActionItem(
        icon: Icons.groups_outlined,
        label: '联系人',
        onTap: _openBeneficiaries,
      ),
      _WalletActionItem(
        icon: Icons.notifications_outlined,
        label: '消息',
        onTap: _openInbox,
      ),
      _WalletActionItem(
        icon: Icons.add_card_outlined,
        label: '充值',
        onTap: _openTopUp,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionButton(
          theme: theme,
          icon: action.icon,
          label: action.label,
          onTap: action.onTap,
        );
      },
    );
  }

  Widget _buildBigKTransactionSection(ThemeData theme, bool isDark) {
    return _buildSectionCard(
      theme: theme,
      title: '最近动态',
      actionLabel: '查看全部',
      onActionTap: _openBigKTransactions,
      child: _recentBigKTransactions.isEmpty
          ? _buildEmptyBody(
              icon: Icons.account_balance_wallet_outlined,
              text: '暂无钱包动态。',
            )
          : Column(
              children: _recentBigKTransactions
                  .map(
                    (transaction) => Column(
                      children: <Widget>[
                        _buildBigKTransactionItem(transaction, theme, isDark),
                        if (transaction != _recentBigKTransactions.last)
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildBigKTransactionItem(
    BigKTransaction transaction,
    ThemeData theme,
    bool isDark,
  ) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                    fontSize: 12,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletUnavailable(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: '钱包暂不可用',
      actionLabel: '重试',
      onActionTap: _loadData,
      child: _buildEmptyBody(
        icon: Icons.account_balance_wallet_outlined,
        text: _loadError ?? '钱包暂时不可用。',
      ),
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required String actionLabel,
    required VoidCallback onActionTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                GestureDetector(
                  onTap: onActionTap,
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyBody({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 44,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BigKWalletSection {
  final BigKWallet wallet;
  final List<BigKTransaction> transactions;

  const _BigKWalletSection({
    required this.wallet,
    required this.transactions,
  });
}

class _WalletActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
