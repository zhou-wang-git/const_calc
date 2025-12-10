import 'package:flutter/material.dart';

class MessageUtil {
  static void show(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 2),
      }) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF545454), // ✅ 自定义灰色
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13, // ✅ 字体小一些
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  /// 快捷方法：错误提示
  static void error(BuildContext context, String message) => show(context, message);

  /// 快捷方法：成功提示
  static void success(BuildContext context, String message) => show(context, message);

  /// 快捷方法：普通信息提示
  static void info(BuildContext context, String message) => show(context, message);
}
