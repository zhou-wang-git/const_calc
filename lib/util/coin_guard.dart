import 'package:flutter/material.dart';

import '../dto/coin_balance.dart';
import '../services/coin_service.dart';
import '../widgets/coin_consume_dialog.dart';
import 'message_util.dart';

/// 积分守卫 - 用于功能入口拦截
class CoinGuard {
  static int? _lastConsumeId;

  static int? get lastConsumeId => _lastConsumeId;

  /// 检查并执行需要消费积分的操作
  ///
  /// [context] - BuildContext
  /// [functionId] - 功能ID，用于获取消费积分数
  /// [functionName] - 功能名称，显示在弹窗中
  /// [coins] - 需要消费的积分数（如果为null则从配置获取）
  /// [onSuccess] - 消费成功后的回调
  ///
  /// 返回 true 表示可以继续执行，false 表示被拦截
  static Future<bool> checkAndConsume({
    required BuildContext context,
    required String functionId,
    required String functionName,
    int? coins,
    VoidCallback? onSuccess,
  }) async {
    _lastConsumeId = null;
    try {
      // 1. 获取余额信息
      CoinBalance balance;
      try {
        balance =
            CoinService.getCachedBalance() ?? await CoinService.getBalance();
      } catch (e) {
        if (context.mounted) {
          MessageUtil.error(context, '获取用户信息失败，请稍后重试');
        }
        return false;
      }

      // 2. 免费用户直接放行
      if (balance.isFreeUser) {
        onSuccess?.call();
        return true;
      }

      // 3. 获取消费积分数
      final config =
          CoinService.getCachedConfig() ?? await CoinService.getConfig();
      final requiredCoins = coins ?? config.getFunctionCost(functionId);

      // 4. 显示确认弹窗
      if (!context.mounted) return false;

      final result = await CoinConsumeDialog.show(
        context: context,
        functionName: functionName,
        coins: requiredCoins,
      );

      // 5. 处理弹窗结果
      switch (result) {
        case ConsumeDialogResult.freeUser:
          // 免费用户，直接放行
          onSuccess?.call();
          return true;

        case ConsumeDialogResult.confirmed:
          // 确认消费，执行扣费
          try {
            final consumeResult = await CoinService.consume(
              functionId: functionId,
              coins: requiredCoins,
            );

            if (!context.mounted) return false;

            if (!consumeResult.charged && consumeResult.reason != null) {
              // 免费用户
              onSuccess?.call();
              return true;
            }

            // 消费成功
            _lastConsumeId = consumeResult.consumeId;
            onSuccess?.call();
            return true;
          } catch (e) {
            if (context.mounted) {
              MessageUtil.error(context, '消费失败: $e');
            }
            return false;
          }

        case ConsumeDialogResult.cancelled:
          return false;

        case ConsumeDialogResult.recharged:
          // 用户去充值了，返回false让用户重新操作
          return false;
      }
    } catch (e) {
      if (context.mounted) {
        MessageUtil.error(context, '操作失败: $e');
      }
      return false;
    }
  }

  /// 仅检查是否有足够积分（不弹窗）
  ///
  /// 返回 true 表示有足够积分或是免费用户
  static Future<bool> hasEnoughCoins({
    required String functionId,
    int? coins,
  }) async {
    try {
      final balance =
          CoinService.getCachedBalance() ?? await CoinService.getBalance();

      // 免费用户
      if (balance.isFreeUser) return true;

      final config =
          CoinService.getCachedConfig() ?? await CoinService.getConfig();
      final requiredCoins = coins ?? config.getFunctionCost(functionId);

      return balance.coins >= requiredCoins;
    } catch (e) {
      return false;
    }
  }

  /// 获取功能消费积分数
  static Future<int> getFunctionCost(String functionId) async {
    try {
      final config =
          CoinService.getCachedConfig() ?? await CoinService.getConfig();
      return config.getFunctionCost(functionId);
    } catch (e) {
      return 10; // 默认值
    }
  }

  /// 预加载配置和余额（可在应用启动时调用）
  static Future<void> preload() async {
    try {
      await Future.wait([
        CoinService.getBalance(),
        CoinService.getConfig(),
      ]);
    } catch (e) {
      // 忽略预加载失败
    }
  }
}
