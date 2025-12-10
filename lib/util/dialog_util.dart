import 'package:flutter/material.dart';

class DialogUtil {
  /// iOS风格单按钮提示弹窗
  static Future<void> alert(
      BuildContext context, {
        String? title,
        String content = "",
        String buttonText = "确定",
      }) async {
    final hasTitle = (title != null && title.trim().isNotEmpty);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : Colors.black;
    final contentColor = isDark ? Colors.white70 : Colors.black87;
    final buttonColor = isDark ? const Color(0xFFFFD54F) : theme.primaryColor;
    final dividerColor = isDark ? Colors.white24 : Colors.grey[300];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 内容区
                Padding(
                  padding: EdgeInsets.fromLTRB(20, hasTitle ? 16 : 20, 20, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasTitle)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          Text(
                            content,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              color: contentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 分割线
                Container(height: 1, color: dividerColor),
                // 单按钮
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 17,
                        color: buttonColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// iOS风格确认弹窗
  static Future<bool> confirm(
      BuildContext context, {
        String? title, // 不传或空字符串 -> 不显示且不占位
        String content = "是否确认执行此操作？",
        String cancelText = "取消",
        String confirmText = "确定",
      }) async {
    final hasTitle = (title != null && title.trim().isNotEmpty);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 深色模式下使用更亮的颜色
    final titleColor = isDark ? Colors.white : Colors.black;
    final contentColor = isDark ? Colors.white70 : Colors.black87;
    final cancelColor = isDark ? Colors.white60 : Colors.grey[600];
    final confirmColor = isDark ? const Color(0xFFFFD54F) : theme.primaryColor;
    final dividerColor = isDark ? Colors.white24 : Colors.grey[300];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 小一点的圆角
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 内容区
                Padding(
                  padding: EdgeInsets.fromLTRB(20, hasTitle ? 16 : 20, 20, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80), // 给点高度方便居中
                    child: Center( // ⬅️ 水平垂直居中
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasTitle)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          Text(
                            content,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              color: contentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 顶部分割线（全宽）
                Container(height: 1, color: dividerColor),

                // 底部按钮区（左右各半，有中间竖线）
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            cancelText,
                            style: TextStyle(
                              fontSize: 17,
                              color: cancelColor,
                            ),
                          ),
                        ),
                      ),

                      // 中间竖线
                      Container(width: 1, color: dividerColor),

                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              fontSize: 17,
                              color: confirmColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return result == true;
  }
}
