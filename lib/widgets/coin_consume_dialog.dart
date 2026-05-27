import 'package:flutter/material.dart';

import '../dto/coin_balance.dart';
import '../services/coin_service.dart';
import '../pages/my/coin_recharge_page.dart';
import '../pages/my/wallet_page.dart';

/// 消费确认弹窗结果
enum ConsumeDialogResult {
  confirmed, // 确认消费
  cancelled, // 取消
  recharged, // 去充值
  freeUser, // 免费用户（无需弹窗）
}

/// 消费确认弹窗
class CoinConsumeDialog extends StatefulWidget {
  final String functionName; // 功能名称
  final int coins; // 需要消耗的积分

  const CoinConsumeDialog({
    super.key,
    required this.functionName,
    required this.coins,
  });

  /// 显示消费确认弹窗
  /// 返回 ConsumeDialogResult
  static Future<ConsumeDialogResult> show({
    required BuildContext context,
    required String functionName,
    required int coins,
  }) async {
    // 先获取用户余额信息
    CoinBalance? balance;
    try {
      balance =
          CoinService.getCachedBalance() ?? await CoinService.getBalance();
    } catch (e) {
      // 获取失败，继续显示弹窗
    }

    // 免费用户直接返回
    if (balance != null && balance.isFreeUser) {
      return ConsumeDialogResult.freeUser;
    }

    // 检查余额是否足够
    final hasEnough = balance != null && balance.coins >= coins;

    if (!context.mounted) return ConsumeDialogResult.cancelled;

    // 显示对应弹窗
    if (hasEnough) {
      final result = await showDialog<ConsumeDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CoinConsumeDialog(
          functionName: functionName,
          coins: coins,
        ),
      );
      return result ?? ConsumeDialogResult.cancelled;
    } else {
      final result = await showDialog<ConsumeDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => InsufficientBalanceDialog(
          functionName: functionName,
          required: coins,
          balance: balance?.coins ?? 0,
        ),
      );
      return result ?? ConsumeDialogResult.cancelled;
    }
  }

  @override
  State<CoinConsumeDialog> createState() => _CoinConsumeDialogState();
}

class _CoinConsumeDialogState extends State<CoinConsumeDialog> {
  CoinBalance? _balance;

  @override
  void initState() {
    super.initState();
    _balance = CoinService.getCachedBalance();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            // 标题
            Text(
              '确认消费',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 12),

            // 消费详情
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '功能',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.functionName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '消耗能量点',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '-${widget.coins}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '当前余额',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_balance?.coins ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '消费后余额',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(_balance?.coins ?? 0) - widget.coins}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(ConsumeDialogResult.cancelled);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(ConsumeDialogResult.confirmed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '确认消费',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 余额不足弹窗
class InsufficientBalanceDialog extends StatelessWidget {
  final String functionName;
  final int required;
  final int balance;

  const InsufficientBalanceDialog({
    super.key,
    required this.functionName,
    required this.required,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortage = required - balance;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            // 标题
            Text(
              '能量点不足',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 12),

            // 详情
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '需要能量点',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$required',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '当前余额',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$balance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '还需充值',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$shortage 能量点',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(ConsumeDialogResult.cancelled);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(ConsumeDialogResult.recharged);
                      // 跳转到充值页面
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoinRechargePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '去充值',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
