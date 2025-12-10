import 'package:flutter/material.dart';

/// 应用样式常量
class AppStyles {
  /// 剩余查询次数字体大小比例（相对于屏幕宽度）
  static const double quotaFontSizeRatio = 0.035;

  /// 获取剩余查询次数文字样式（支持深色模式）
  static TextStyle getQuotaTextStyle(double screenWidth, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: screenWidth * quotaFontSizeRatio,
    );
  }

  /// 格式化次数显示：999 显示为"无限"
  static String formatCount(int count) {
    return count >= 999 ? '无限' : count.toString();
  }

  /// 格式化剩余查询次数显示
  /// 如果 limit 是 999，显示"剩余查询次数: 无限"
  /// 否则显示"剩余查询次数: X/Y"
  static String formatQuotaDisplay(int remaining, int limit) {
    if (limit >= 999) {
      return '剩余查询次数: 无限';
    }
    return '剩余查询次数: $remaining/$limit';
  }
}
