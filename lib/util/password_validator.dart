import 'package:flutter/material.dart';

/// 密码验证结果详情
class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  /// 是否全部通过
  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar;

  /// 通过的项目数量
  int get passedCount =>
      (hasMinLength ? 1 : 0) +
      (hasUppercase ? 1 : 0) +
      (hasLowercase ? 1 : 0) +
      (hasDigit ? 1 : 0) +
      (hasSpecialChar ? 1 : 0);

  /// 强度等级 (0-5)
  int get strengthLevel => passedCount;

  /// 强度颜色
  Color get strengthColor {
    switch (passedCount) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 强度文字描述
  String get strengthText {
    switch (passedCount) {
      case 0:
      case 1:
        return '弱';
      case 2:
        return '较弱';
      case 3:
        return '一般';
      case 4:
        return '较强';
      case 5:
        return '强';
      default:
        return '';
    }
  }
}

/// 密码强度验证工具
///
/// 密码要求：
/// - 最少 8 位
/// - 包含大写字母 (A-Z)
/// - 包含小写字母 (a-z)
/// - 包含数字 (0-9)
/// - 包含特殊字符 (!@#$%^&*()_+-=[]{}|;:,.<>?)
class PasswordValidator {
  /// 验证密码强度，返回错误信息，如果通过则返回 null
  static String? validate(String password) {
    if (password.length < 8) {
      return '密码长度至少为 8 位';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return '密码必须包含大写字母';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return '密码必须包含小写字母';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return '密码必须包含数字';
    }

    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) {
      return '密码必须包含特殊字符 (!@#\$%^&* 等)';
    }

    return null; // 验证通过
  }

  /// 获取详细验证结果
  static PasswordValidationResult validateDetailed(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasDigit: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar:
          RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password),
    );
  }

  /// 获取密码要求说明
  static String get requirements =>
      '密码需至少 8 位，包含大小写字母、数字和特殊字符';
}

/// 密码强度指示器组件
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;
  final bool centerRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
    this.centerRequirements = false,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final result = PasswordValidator.validateDetailed(password);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: centerRequirements ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // 强度条
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.strengthLevel / 5,
                  backgroundColor: isDark ? Colors.white24 : Colors.grey[300],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(result.strengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              result.strengthText,
              style: TextStyle(
                fontSize: 12,
                color: result.strengthColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (showRequirements) ...[
          const SizedBox(height: 8),
          // 各项要求状态
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: centerRequirements ? WrapAlignment.center : WrapAlignment.start,
            children: [
              _buildRequirement(context, '8位+', result.hasMinLength, textColor, isDark),
              _buildRequirement(context, '大写', result.hasUppercase, textColor, isDark),
              _buildRequirement(context, '小写', result.hasLowercase, textColor, isDark),
              _buildRequirement(context, '数字', result.hasDigit, textColor, isDark),
              _buildRequirement(context, '符号', result.hasSpecialChar, textColor, isDark),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRequirement(BuildContext context, String label, bool passed, Color textColor, bool isDark) {
    // 深色模式：已满足=浅灰，未满足=深灰；浅色模式：已满足=主题黄色，未满足=灰色
    final passedColor = isDark ? Colors.grey[400] : const Color(0xFFFFC107);
    final notPassedColor = isDark ? Colors.grey[700] : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: passed ? passedColor : notPassedColor,
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: passed ? passedColor : (isDark ? notPassedColor : textColor),
          ),
        ),
      ],
    );
  }
}
