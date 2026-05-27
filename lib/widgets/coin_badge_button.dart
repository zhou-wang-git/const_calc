import 'package:flutter/material.dart';

import '../dto/coin_balance.dart';
import '../services/coin_service.dart';

/// 带积分角标的按钮组件
class CoinBadgeButton extends StatelessWidget {
  final String text;
  final String functionId;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CoinBadgeButton({
    super.key,
    required this.text,
    required this.functionId,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = CoinService.getCachedBalance();
    final config = CoinService.getCachedConfig();

    // 获取功能消费积分数
    final coins = config?.getFunctionCost(functionId) ?? 0;

    // 判断是否免费用户
    final isFreeUser = balance?.isFreeUser ?? false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 主按钮
        SizedBox(
          width: width,
          height: height ?? 48,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? theme.colorScheme.primary,
              foregroundColor: textColor ?? Colors.white,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // 积分角标（免费用户不显示）
        if (!isFreeUser && coins > 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$coins能量点',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 带积分角标的图标按钮（用于卡片入口等）
class CoinBadgeIconButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final String functionId;
  final VoidCallback onTap;
  final Color? badgeColor;

  const CoinBadgeIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.functionId,
    required this.onTap,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final balance = CoinService.getCachedBalance();
    final config = CoinService.getCachedConfig();

    final coins = config?.getFunctionCost(functionId) ?? 0;
    final isFreeUser = balance?.isFreeUser ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          // 积分角标
          if (!isFreeUser && coins > 0)
            Positioned(
              top: -4,
              right: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
