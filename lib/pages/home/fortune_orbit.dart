// fortune_orbit.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

typedef CenterTapCallback = void Function(String centerId, bool isActive);
typedef NodeTapCallback = void Function(String centerId, String nodeId, bool isActive);

/// 命中形状（目前支持圆、椭圆；默认圆）
enum HitShape { circle, ellipse }

class OrbitNode {
  final String id;
  final Size rawSize;            // 设计稿尺寸，参与贴图与默认命中半径推导
  final String normalAsset;
  final String activeAsset;

  /// --- 区域精度增强参数 ---
  final HitShape hitShape;       // 命中为圆 or 椭圆（默认圆）
  final Offset hitCenterShift;   // 命中圆/椭圆的圆心相对素材中心的偏移（设计稿单位）
  // 圆：优先用 hitRadius，其次用 hitScale（相对 min(w,h)/2）
  final double? hitRadius;       // 绝对半径（设计稿单位，优先级最高）
  final double? hitScale;        // 相对半径比例（默认 0.9）

  // 椭圆：单轴半径（优先）或比例（次之）；未提供时退化为圆的半径
  final double? hitRadiusX;      // X 轴半径（设计稿单位）
  final double? hitRadiusY;      // Y 轴半径（设计稿单位）
  final double? hitScaleX;       // X 轴比例（相对 rawSize.width/2）
  final double? hitScaleY;       // Y 轴比例（相对 rawSize.height/2）

  const OrbitNode({
    required this.id,
    required this.rawSize,
    required this.normalAsset,
    required this.activeAsset,
    this.hitShape = HitShape.circle,
    this.hitCenterShift = Offset.zero,
    this.hitRadius,
    this.hitScale,
    this.hitRadiusX,
    this.hitRadiusY,
    this.hitScaleX,
    this.hitScaleY,
  });
}

class FortuneOrbit extends StatefulWidget {
  // --- 画布与几何 ---
  final double boxSize;                 // 画布边长（设计稿单位）
  final double radius;                  // 基础轨道半径（设计稿单位）
  final Offset centerOffset;            // 中心位移（设计稿单位）
  final bool moveOrbitWithCenter;       // 节点是否跟随中心位移

  // --- 节点与摆位 ---
  final List<OrbitNode> nodes;          // 三个环绕节点
  final double startAngleDeg;           // 第 0 个节点起始角（度）
  final double globalAngleOffsetDeg;    // 全局角偏（度）
  final List<double> perNodeAngleOffsetDegs;  // 每节点角度微调（度）
  final List<double> perNodeRadiusOffsets;    // 每节点半径微调（设计稿单位）

  // --- 中心素材与文字 ---
  final String centerId;
  final Size centerRawSize;
  final String centerNormalAsset;
  final String centerActiveAsset;
  final String centerTextTop;
  final String centerTextBottom;
  final Offset centerTextTopOffset;
  final Offset centerTextBottomOffset;
  final TextStyle? centerTextStyle;

  // 中心命中圈（仍用圆；如需更细也可扩展为椭圆）
  final double? centerHitScale;         // 默认 0.9
  final Offset centerHitShift;          // ✅ 中心命中圆心偏移（设计稿单位）

  // --- 初始状态/重置/回调 ---
  final bool initialCenterActive;
  final List<String> initialActiveNodeIds;
  final int resetTick;
  final CenterTapCallback? onCenterTap;
  final NodeTapCallback? onNodeTap;

  // --- 调试层 ---
  final bool showDebugOverlay;

  // --- 深色模式 ---
  final bool isDark;

  const FortuneOrbit({
    super.key,
    required this.boxSize,
    required this.radius,
    this.centerOffset = Offset.zero,
    this.moveOrbitWithCenter = true,
    required this.nodes,
    this.startAngleDeg = 0,
    this.globalAngleOffsetDeg = 0,
    this.perNodeAngleOffsetDegs = const [],
    this.perNodeRadiusOffsets = const [],
    required this.centerId,
    required this.centerRawSize,
    required this.centerNormalAsset,
    required this.centerActiveAsset,
    this.centerTextTop = '',
    this.centerTextBottom = '',
    this.centerTextTopOffset = Offset.zero,
    this.centerTextBottomOffset = Offset.zero,
    this.centerTextStyle,
    this.centerHitScale,
    this.centerHitShift = Offset.zero,      // ✅ 默认不偏移
    this.initialCenterActive = false,
    this.initialActiveNodeIds = const [],
    this.resetTick = 0,
    this.onCenterTap,
    this.onNodeTap,
    this.showDebugOverlay = false,
    this.isDark = false,
  });

  @override
  State<FortuneOrbit> createState() => FortuneOrbitState();
}

class FortuneOrbitState extends State<FortuneOrbit> {
  late bool _centerActive;
  late Map<String, bool> _nodeActive;

  @override
  void initState() {
    super.initState();
    _initStateFromInitials();
  }

  /// ✅ 外部可调用的重置方法
  void reset() {
    setState(() {
      _centerActive = false;
      for (final k in _nodeActive.keys) {
        _nodeActive[k] = false;
      }
    });
  }

  void _initStateFromInitials() {
    _centerActive = widget.initialCenterActive;
    _nodeActive = {for (final n in widget.nodes) n.id: widget.initialActiveNodeIds.contains(n.id)};
  }

  @override
  void didUpdateWidget(covariant FortuneOrbit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetTick != oldWidget.resetTick) {
      setState(_initStateFromInitials);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 统一使用“设计稿单位”（不再 .w/.h）
    final double box = widget.boxSize;
    final double baseRadius = widget.radius;
    final Offset centerShift = widget.centerOffset;

    // 统一算几何（供点击与调试）
    final _LayoutCache cache = _computeLayout(box, baseRadius, centerShift);

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 中心视觉（不接手势）
          Transform.translate(offset: centerShift, child: _buildCenterVisualOnly()),

          // 节点视觉（不接手势）
          for (int i = 0; i < widget.nodes.length; i++)
            Transform.translate(
              offset: cache.nodeCenters[i] - cache.boxCenter,
              child: SizedBox(
                width: widget.nodes[i].rawSize.width,
                height: widget.nodes[i].rawSize.height,
                child: IgnorePointer(
                  child: widget.isDark
                      ? ColorFiltered(
                          // 降低亮度：每个颜色通道乘以 0.7
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.7, 0,   0,   0, 0,
                            0,   0.7, 0,   0, 0,
                            0,   0,   0.7, 0, 0,
                            0,   0,   0,   1, 0,
                          ]),
                          child: Image.asset(
                            (_nodeActive[widget.nodes[i].id] ?? false)
                                ? widget.nodes[i].activeAsset
                                : widget.nodes[i].normalAsset,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          (_nodeActive[widget.nodes[i].id] ?? false)
                              ? widget.nodes[i].activeAsset
                              : widget.nodes[i].normalAsset,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),

          // 顶层遮罩：统一处理点击
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) => _handleTap(d.localPosition, cache),
            ),
          ),

          // 可视化调试
          if (widget.showDebugOverlay)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FortuneDebugPainter(cache: cache)),
              ),
            ),
        ],
      ),
    );
  }

  /// 中心视觉
  Widget _buildCenterVisualOnly() {
    final Size s = widget.centerRawSize;
    final String asset = _centerActive ? widget.centerActiveAsset : widget.centerNormalAsset;

    final Offset topOff = widget.centerTextTopOffset;
    final Offset bottomOff = widget.centerTextBottomOffset;

    final centerImage = widget.isDark
        ? ColorFiltered(
            // 降低亮度：每个颜色通道乘以 0.7
            colorFilter: const ColorFilter.matrix(<double>[
              0.7, 0,   0,   0, 0,
              0,   0.7, 0,   0, 0,
              0,   0,   0.7, 0, 0,
              0,   0,   0,   1, 0,
            ]),
            child: Image.asset(asset, fit: BoxFit.contain),
          )
        : Image.asset(asset, fit: BoxFit.contain);

    return SizedBox(
      width: s.width,
      height: s.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: IgnorePointer(child: centerImage)),
          if (widget.centerTextTop.isNotEmpty)
            Transform.translate(
              offset: topOff,
              child: Text(
                widget.centerTextTop,
                textAlign: TextAlign.center,
                style: widget.centerTextStyle ??
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          if (widget.centerTextBottom.isNotEmpty)
            Transform.translate(
              offset: bottomOff,
              child: Text(
                widget.centerTextBottom,
                textAlign: TextAlign.center,
                style: widget.centerTextStyle ??
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  /// 点击命中
  void _handleTap(Offset p, _LayoutCache cache) {
    // 1) 中心（圆）
    if ((p - cache.centerHitCenter).distance <= cache.centerHitR) {
      setState(() {
        _centerActive = !_centerActive;
        for (final k in _nodeActive.keys) _nodeActive[k] = false;
      });
      widget.onCenterTap?.call(widget.centerId, _centerActive);
      return;
    }

    // 2) 节点（支持椭圆命中）
    int? hitIndex;
    double bestScore = double.infinity; // 选“最内侧”的那个（越小越内）

    for (int i = 0; i < widget.nodes.length; i++) {
      final dx = p.dx - cache.nodeHitCenters[i].dx;
      final dy = p.dy - cache.nodeHitCenters[i].dy;

      // 圆：rx==ry；椭圆：单轴半径
      final rx = cache.nodeHitRx[i];
      final ry = cache.nodeHitRy[i];

      // 归一化半径距离，<=1 命中
      final score = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry);
      if (score <= 1.0 && score < bestScore) {
        bestScore = score;
        hitIndex = i;
      }
    }

    if (hitIndex != null) {
      final node = widget.nodes[hitIndex];
      final wasActive = _nodeActive[node.id] ?? false;
      setState(() {
        for (final k in _nodeActive.keys) _nodeActive[k] = false;
        _nodeActive[node.id] = !wasActive;
        _centerActive = false;
      });
      widget.onNodeTap?.call(widget.centerId, node.id, _nodeActive[node.id]!);
    }
  }

  /// 统一几何计算（中心/节点的显示圆心、命中圆心与半径）
  _LayoutCache _computeLayout(double box, double baseRadius, Offset centerShift) {
    final boxCenter = Offset(box / 2, box / 2);

    // 中心命中：圆
    final Size centerSize = widget.centerRawSize;
    final double centerHitR =
        math.min(centerSize.width, centerSize.height) * 0.5 * (widget.centerHitScale ?? 0.9);
    final Offset centerVisualCenter = boxCenter + centerShift;
    final Offset centerHitCenter = centerVisualCenter + widget.centerHitShift;

    // 节点命中：圆/椭圆
    final Offset orbitBaseOffset = widget.moveOrbitWithCenter ? centerShift : Offset.zero;

    final List<Offset> nodeCenters = [];
    final List<Offset> nodeHitCenters = [];
    final List<double> nodeHitRx = [];
    final List<double> nodeHitRy = [];

    for (int i = 0; i < widget.nodes.length; i++) {
      final node = widget.nodes[i];

      final double angleDeg = widget.startAngleDeg +
          i * 120 +
          widget.globalAngleOffsetDeg +
          (i < widget.perNodeAngleOffsetDegs.length ? widget.perNodeAngleOffsetDegs[i] : 0);
      final double angleRad = angleDeg * math.pi / 180.0;

      final double r = baseRadius +
          (i < widget.perNodeRadiusOffsets.length ? widget.perNodeRadiusOffsets[i] : 0);

      final Offset nodeCenter =
          boxCenter + orbitBaseOffset + Offset(r * math.cos(angleRad), r * math.sin(angleRad));
      nodeCenters.add(nodeCenter);

      // 命中圆心允许偏移
      final Offset hitCenterShift = node.hitCenterShift;
      final Offset nodeHitCenter = nodeCenter + hitCenterShift;
      nodeHitCenters.add(nodeHitCenter);

      // 计算半径：优先绝对值，其次比例；椭圆按 x/y 单独推导
      final Size s = node.rawSize;
      final double baseCircleR = math.min(s.width, s.height) * 0.5 * (node.hitScale ?? 0.9);
      final double circleR = node.hitRadius ?? baseCircleR;

      double rx, ry;
      if (node.hitShape == HitShape.ellipse) {
        final double baseRx =
        (node.hitScaleX != null) ? (s.width * 0.5 * node.hitScaleX!) : circleR;
        final double baseRy =
        (node.hitScaleY != null) ? (s.height * 0.5 * node.hitScaleY!) : circleR;
        rx = node.hitRadiusX ?? baseRx;
        ry = node.hitRadiusY ?? baseRy;
      } else {
        // circle
        rx = circleR;
        ry = circleR;
      }

      nodeHitRx.add(rx);
      nodeHitRy.add(ry);
    }

    return _LayoutCache(
      boxSize: box,
      boxCenter: boxCenter,
      centerVisualCenter: centerVisualCenter,
      centerHitCenter: centerHitCenter,
      centerHitR: centerHitR,
      nodeCenters: nodeCenters,
      nodeHitCenters: nodeHitCenters,
      nodeHitRx: nodeHitRx,
      nodeHitRy: nodeHitRy,
      radius: baseRadius,
    );
  }
}

/// —— 缓存（绘制/命中共用） ——
class _LayoutCache {
  final double boxSize;
  final Offset boxCenter;

  final Offset centerVisualCenter;
  final Offset centerHitCenter;
  final double centerHitR;

  final List<Offset> nodeCenters;     // 节点视觉圆心
  final List<Offset> nodeHitCenters;  // 节点命中圆心（可偏移）
  final List<double> nodeHitRx;       // 命中半径 x
  final List<double> nodeHitRy;       // 命中半径 y

  final double radius; // 基准轨道半径（调试画用）

  _LayoutCache({
    required this.boxSize,
    required this.boxCenter,
    required this.centerVisualCenter,
    required this.centerHitCenter,
    required this.centerHitR,
    required this.nodeCenters,
    required this.nodeHitCenters,
    required this.nodeHitRx,
    required this.nodeHitRy,
    required this.radius,
  });
}

/// —— 调试绘制（画椭圆/圆心/连接线/标签） ——
class _FortuneDebugPainter extends CustomPainter {
  final _LayoutCache cache;

  _FortuneDebugPainter({required this.cache});

  final Paint _guide = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFF6D00); // 橙：轨道/外框

  final Paint _centerP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFF00C853); // 绿：中心命中

  final Paint _nodeP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFF2962FF); // 蓝：节点命中

  @override
  void paint(Canvas canvas, Size size) {
    // 外框
    canvas.drawRect(Offset.zero & size, _guide..color = _guide.color.withOpacity(0.25));
    // 轨道
    canvas.drawCircle(cache.centerVisualCenter, cache.radius, _guide);

    // 中心命中（圆）
    canvas.drawCircle(cache.centerHitCenter, cache.centerHitR, _centerP);
    canvas.drawCircle(cache.centerHitCenter, 2, _centerP..style = PaintingStyle.fill);
    _drawText(canvas, 'CENTER', cache.centerHitCenter + const Offset(6, -6), const Color(0xFF00C853));

    // 节点命中（椭圆/圆）
    for (int i = 0; i < cache.nodeCenters.length; i++) {
      final vc = cache.nodeCenters[i];
      final hc = cache.nodeHitCenters[i];
      final rx = cache.nodeHitRx[i];
      final ry = cache.nodeHitRy[i];

      // 视觉中心连线
      canvas.drawLine(cache.centerVisualCenter, vc, _guide);

      // 椭圆（Rect.fromCenter）
      final rect = Rect.fromCenter(center: hc, width: rx * 2, height: ry * 2);
      canvas.drawOval(rect, _nodeP);
      canvas.drawCircle(hc, 2, _nodeP..style = PaintingStyle.fill);

      _drawText(canvas, 'N$i', hc + const Offset(6, -6), const Color(0xFF2962FF));
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _FortuneDebugPainter oldDelegate) => true;
}
