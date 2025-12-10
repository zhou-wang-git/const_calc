import 'dart:math';
import 'package:flutter/material.dart';

class ZcxRingWidget extends StatefulWidget {
  final String centerText;
  final double size;
  final double ringWidth;
  final double gapAngle;
  final int ringIndex;
  final void Function(int ringIndex, int segmentIndex)? onSegmentTap;
  final Color labelColor;
  final bool isDark;

  const ZcxRingWidget({
    super.key,
    required this.centerText,
    required this.ringIndex,
    this.onSegmentTap,
    this.size = 180,
    this.ringWidth = 12,
    this.gapAngle = 0.07,
    this.labelColor = Colors.black,
    this.isDark = false,
  });

  @override
  State<ZcxRingWidget> createState() => ZcxRingWidgetState();
}

class ZcxRingWidgetState extends State<ZcxRingWidget>
    with SingleTickerProviderStateMixin {
  List<bool> _selected = [false, false, false];
  bool _centerSelected = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void clearSelection() {
    setState(() {
      _selected = List.generate(3, (_) => false);
      _centerSelected = false;
    });
    _controller.reset();
  }

  void _handleTapUp(TapUpDetails details) {
    final localPos = details.localPosition;
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final outer = (widget.size - widget.ringWidth) / 2 + widget.ringWidth / 2;
    final inner = outer - widget.ringWidth;

    // ✅ 点击中心区域
    if (distance < inner) {
      setState(() {
        _centerSelected = true;
        _selected = [false, false, false];
      });
      _controller.forward(from: 0);
      widget.onSegmentTap?.call(widget.ringIndex, 0); // 中心文字 = 0
      return;
    }

    // 超出圆环区域
    if (distance > outer) return;

    // ✅ 判断点击了哪个圆环
    final angle = atan2(dy, dx);
    final normalized = angle < -pi / 2 ? angle + 2 * pi : angle;
    final baseSweep = 2 * pi / 3;
    final sweep = baseSweep - widget.gapAngle;
    final centerAngles = [-pi / 2, 5 * pi / 6, pi / 6];

    for (int i = 0; i < 3; i++) {
      final start = centerAngles[i] - sweep / 2;
      final end = start + sweep;
      if (normalized >= start && normalized <= end) {
        setState(() {
          _selected = List.generate(3, (j) => j == i);
          _centerSelected = false;
        });
        _controller.forward(from: 0);
        widget.onSegmentTap?.call(widget.ringIndex, i + 1); // segmentIndex = 1,2,3
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTapUp,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: ZcxRingPainter(
              centerText: widget.centerText,
              ringWidth: widget.ringWidth,
              gapAngle: widget.gapAngle,
              selectedList: _selected,
              centerSelected: _centerSelected,
              progress: _animation.value,
              labelColor: widget.labelColor,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class ZcxRingPainter extends CustomPainter {
  final String centerText;
  final double ringWidth;
  final double gapAngle;
  final List<bool> selectedList;
  final bool centerSelected;
  final double progress;
  final Color labelColor;
  final bool isDark;

  ZcxRingPainter({
    required this.centerText,
    required this.ringWidth,
    required this.gapAngle,
    required this.selectedList,
    required this.centerSelected,
    required this.progress,
    required this.labelColor,
    required this.isDark,
  });

  double degreesToRadians(double degrees) => degrees * pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - ringWidth) / 2;

    final labels = ["流年", "流月", "流日"];
    // 浅色模式：明亮色；深色模式：降低亮度
    final baseColors = isDark
        ? [
            Color(0xFF2A7BC0),  // 蓝色变暗
            Color(0xFFCCAA06),  // 黄色变暗
            Color(0xFF3A9080)   // 绿色变暗
          ]
        : [
            Color(0xFF3C9EEF),
            Color(0xFFFDDB08),
            Color(0xFF4DB9A3)
          ];
    final targetColors = isDark
        ? [
            Color(0xFF153D60),  // 选中更暗
            Color(0xFF665003),
            Color(0xFF1D4840)
          ]
        : [
            Color(0xFF1E4F75),
            Color(0xFF7E5F04),
            Color(0xFF275D53)
          ];
    final centerAngles = [-pi / 2, 5 * pi / 6, pi / 6];
    final baseSweep = 2 * pi / 3;
    final sweep = baseSweep - gapAngle;

    // ✅ 绘制三个环
    for (int i = 0; i < 3; i++) {
      final start = centerAngles[i] - sweep / 2;
      final rect = Rect.fromCircle(center: center, radius: radius);

      final color = selectedList[i]
          ? Color.lerp(baseColors[i], targetColors[i], progress)!
          : baseColors[i];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, start, sweep, false, paint);

      // 标签
      final labelRadius = radius - ringWidth * 0.05;
      final text = labels[i];
      final charCount = text.length;
      final baseAngle = start + sweep / 2;
      final spacing = degreesToRadians(6);
      final charAngle = degreesToRadians(14) + spacing;

      for (int j = 0; j < charCount; j++) {
        final angle = baseAngle + (j - (charCount - 1) / 2) * charAngle;
        final offset = Offset(
          center.dx + labelRadius * cos(angle),
          center.dy + labelRadius * sin(angle),
        );

        final tp = TextPainter(
          text: TextSpan(
            text: text[j],
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(angle + pi / 2);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    // ✅ 中心文字，渐变到黄色
    final centerPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w200,
          color: centerSelected
              ? Color.lerp(labelColor, Colors.yellow, progress)
              : labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    centerPainter.paint(
      canvas,
      center - Offset(centerPainter.width / 2, centerPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ZcxRingPainter oldDelegate) =>
      oldDelegate.centerText != centerText ||
      oldDelegate.selectedList != selectedList ||
          oldDelegate.centerSelected != centerSelected ||
          oldDelegate.progress != progress ||
          oldDelegate.labelColor != labelColor ||
          oldDelegate.isDark != isDark;
}
