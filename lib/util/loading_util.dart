import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LoadingUtil {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// ✅ 打开 Loading
  static void openLoading(BuildContext context, {String text = "加载中..."}) {
    if (_isShowing) return; // 避免重复显示
    _isShowing = true;

    void insert() {
      final overlay = Overlay.of(context, rootOverlay: true);
      _overlayEntry = OverlayEntry(
        builder: (_) => Material(
          color: Colors.black38, // ✅ 半透明浅灰背景
          child: Center(child: _LoadingWidget(text: text)),
        ),
      );
      overlay.insert(_overlayEntry!);
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => insert());
    } else {
      insert();
    }
  }

  /// ✅ 关闭 Loading（防抖 & 安全检查）
  static void closeLoading() {
    if (!_isShowing) return;

    // 延迟 50ms，确保 Overlay 已完成插入
    Future.delayed(const Duration(milliseconds: 50), () {
      try {
        _overlayEntry?.remove();
        _overlayEntry = null;
      } catch (e) {
        debugPrint("LoadingUtil: close error $e");
      } finally {
        _isShowing = false;
      }
    });
  }
}

class _LoadingWidget extends StatefulWidget {
  final String text;
  const _LoadingWidget({required this.text});

  @override
  State<_LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<_LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: Image.asset(
              isDark ? 'assets/icons/logo_dark.png' : 'assets/icons/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.text,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
