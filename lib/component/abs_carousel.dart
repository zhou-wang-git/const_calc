import 'dart:async';
import 'package:flutter/material.dart';
import '../dto/abs.dart';

/// 点击广告回调
typedef AbsTap = void Function(Abs abs);

/// AbsCarousel —— 纯展示型广告轮播组件
/// 外部传入广告列表 [items]，组件负责轮播显示与点击回调。
class AbsCarousel extends StatefulWidget {
  /// 要展示的广告数据（建议父层已过滤好 position/status）
  final List<Abs> items;

  /// 固定高度；如果不传，优先用 [aspectRatio] 计算高度
  final double? height;

  /// 宽高比（宽/高）。与 height 二选一，优先级更高
  final double? aspectRatio;

  /// 点击广告回调（由外部做跳转/埋点）
  final AbsTap? onTap;

  /// 自动轮播开关（仅当 items.length > 1 才会生效）
  final bool autoPlay;

  /// 自动轮播间隔
  final Duration interval;

  /// 每页占据视口的比例（1.0 = 占满宽度；<1 会左右露出）
  final double viewportFraction;

  /// 单个 item 的内边距（默认左右各 6）
  /// 想铺满宽度 → 传 EdgeInsets.zero
  final EdgeInsetsGeometry itemPadding;

  /// 内部是否裁剪圆角（如果外层已经 ClipRRect，一般设为 false）
  final bool clipInside;

  /// 圆角半径（仅在 clipInside=true 时生效）
  final double borderRadius;

  /// 是否显示底部小圆点指示器
  final bool showIndicator;

  /// 数据为空时是否隐藏（不占位）
  final bool hideIfEmpty;

  /// 有数据时的淡入动画时长
  final Duration fadeInDuration;

  /// 图片相对路径的域名前缀（例如 https://your-domain.com）
  final String? domainPrefix;

  /// 高清屏优化（为 Image.network 提供 cacheWidth/Height）
  final bool enableHiDpiCaching;
  final double hiDpiScale; // 2.0 表示以 2x 像素请求缓存

  const AbsCarousel({
    super.key,
    required this.items,
    this.height,
    this.aspectRatio,
    this.onTap,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 4),
    this.viewportFraction = 1,
    this.itemPadding = EdgeInsets.zero,
    this.clipInside = false,
    this.borderRadius = 12,
    this.showIndicator = true,
    this.hideIfEmpty = true,
    this.fadeInDuration = const Duration(milliseconds: 180),
    this.domainPrefix,
    this.enableHiDpiCaching = true,
    this.hiDpiScale = 2.0,
  });

  @override
  State<AbsCarousel> createState() => _AbsCarouselState();
}

class _AbsCarouselState extends State<AbsCarousel> {
  /// 只保留一个 PageController 实例，避免 “not attached” 问题
  late PageController _controller;

  /// 自动轮播的计时器
  Timer? _timer;

  /// 当前索引（配合指示器/自动轮播）
  int _index = 0;

  /// 是否有数据（给你可能的外部判断用）
  bool get hasData => widget.items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // 注意：这里就用 viewportFraction 创建唯一的 controller
    _controller = PageController(
      viewportFraction: widget.viewportFraction,
      keepPage: true,
    );
    _startAutoPlayIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AbsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1) 视窗占比变化 → 帧末重建 controller（防止 during build）
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.dispose();
        _controller = PageController(
          viewportFraction: widget.viewportFraction,
          keepPage: true,
        );
        _startAutoPlayIfNeeded(); // 重建后重启轮播
      });
    }

    // 2) 数据量变化 / 自动播放配置变化 → 重新判断是否需要轮播
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.interval != widget.interval) {
      _startAutoPlayIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 启动（或重启）自动轮播：只在开启且图片数>1 时生效
  void _startAutoPlayIfNeeded() {
    _timer?.cancel();

    if (!widget.autoPlay || widget.items.length < 2) return;

    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      if (widget.items.isEmpty) return;
      if (!_controller.hasClients) return; // 关键保护：未附着 PageView 就别动

      final next = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
      );
    });
  }

  /// 拼接图片 URL：相对路径时加上域名前缀
  String _resolveUrl(Abs abs) {
    final url = abs.imageUrl;
    if (url.isEmpty) {
      print('AbsCarousel: imageUrl is empty for ad id=${abs.id}');
      return url;
    }
    if (url.startsWith('http') || url.startsWith('data:')) {
      print('AbsCarousel: using full url=$url');
      return url;
    }
    if (url.startsWith('/') && (widget.domainPrefix?.isNotEmpty ?? false)) {
      final fullUrl = '${widget.domainPrefix}$url';
      print('AbsCarousel: resolved url=$fullUrl (from $url)');
      return fullUrl;
    }
    print('AbsCarousel: using raw url=$url (no prefix)');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // 空数据：按需隐藏（不占位）
    if (widget.hideIfEmpty && widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(builder: (context, constraints) {
      final hasParentHeight =
          constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

      // 计算高度：优先使用 aspectRatio（更适配不同机型）
      final computedHeight = widget.aspectRatio != null
          ? (constraints.maxWidth / widget.aspectRatio!)
          : (widget.height ?? (hasParentHeight ? constraints.maxHeight : 140));

      // 主体：PageView + 指示器
      final view = Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller, // ✅ 一定要用同一个实例
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final abs = widget.items[i];

              return Padding(
                padding: widget.itemPadding, // ✅ 允许外部控制 item 间距
                child: _AbsCard(
                  imageUrl: _resolveUrl(abs),
                  height: computedHeight,
                  onTap: () => widget.onTap?.call(abs),
                  clipInside: widget.clipInside,
                  borderRadius: widget.borderRadius,
                  enableHiDpiCaching: widget.enableHiDpiCaching,
                  hiDpiScale: widget.hiDpiScale,
                  // 估算容器宽度用于 cacheWidth，注意和 viewportFraction 一致
                  estimatedContainerWidth:
                  constraints.maxWidth * widget.viewportFraction,
                ),
              );
            },
          ),
          if (widget.showIndicator && widget.items.length > 1)
            Positioned(
              bottom: 8,
              child: _Dots(count: widget.items.length, index: _index),
            ),
        ],
      );

      // 有数据时淡入，更顺滑
      final wrapped = AnimatedOpacity(
        opacity: widget.items.isNotEmpty ? 1 : 0,
        duration: widget.fadeInDuration,
        child: view,
      );

      // 默认撑满宽度
      if (hasParentHeight && widget.aspectRatio == null && widget.height == null) {
        return wrapped;
      }
      return SizedBox(width: double.infinity, height: computedHeight, child: wrapped);
    });
  }
}

/// 单个广告卡片（内部裁剪可选）
class _AbsCard extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double borderRadius;
  final bool clipInside;
  final VoidCallback? onTap;

  // 高清屏缓存参数
  final bool enableHiDpiCaching;
  final double hiDpiScale;
  final double estimatedContainerWidth;

  const _AbsCard({
    required this.imageUrl,
    required this.height,
    required this.borderRadius,
    required this.clipInside,
    required this.enableHiDpiCaching,
    required this.hiDpiScale,
    required this.estimatedContainerWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 按容器尺寸 * 倍数 估算缓存像素，避免放大导致模糊
    int? cacheW;
    int? cacheH;
    if (enableHiDpiCaching &&
        estimatedContainerWidth.isFinite &&
        height.isFinite &&
        estimatedContainerWidth > 0 &&
        height > 0) {
      cacheW = (estimatedContainerWidth * hiDpiScale).toInt();
      cacheH = (height * hiDpiScale).toInt();
    }

    Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,                 // 填满容器避免变形
            filterQuality: FilterQuality.high, // 缩放更清晰
            gaplessPlayback: true,
            cacheWidth: cacheW,
            cacheHeight: cacheH,
            errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );

    // 内部裁剪圆角（如果外层已裁剪，可关闭 clipInside 避免双重裁剪）
    if (clipInside) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }
    return content;
  }
}

/// 指示器（小圆点）
class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
