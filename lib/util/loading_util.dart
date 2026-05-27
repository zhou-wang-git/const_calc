import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LoadingUtil {
  static OverlayEntry? _overlayEntry;
  static int _loadingCount = 0;
  static int _scheduleVersion = 0;
  static bool _isInsertScheduled = false;

  static void openLoading(BuildContext context, {String text = "加载中..."}) {
    _loadingCount += 1;
    if (_overlayEntry != null || _isInsertScheduled) return;

    final version = ++_scheduleVersion;
    _isInsertScheduled = true;

    void insert() {
      _isInsertScheduled = false;
      if (_overlayEntry != null ||
          _loadingCount <= 0 ||
          version != _scheduleVersion) {
        return;
      }

      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) return;

      _overlayEntry = OverlayEntry(
        builder: (_) => Material(
          color: Colors.black38,
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

  static void closeLoading() {
    if (_loadingCount > 0) {
      _loadingCount -= 1;
    }
    if (_loadingCount > 0) return;

    _loadingCount = 0;
    _scheduleVersion += 1;
    _isInsertScheduled = false;

    if (_overlayEntry == null) return;

    void remove() {
      try {
        _overlayEntry?.remove();
      } catch (e) {
        debugPrint("LoadingUtil: close error $e");
      } finally {
        _overlayEntry = null;
      }
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      remove();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => remove());
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
