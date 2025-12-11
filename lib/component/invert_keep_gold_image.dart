import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 反色图片组件，但保留金黄色 (0xFBBD08) 不变
class InvertKeepGoldImage extends StatefulWidget {
  final String assetPath;
  final BoxFit fit;

  const InvertKeepGoldImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
  });

  @override
  State<InvertKeepGoldImage> createState() => _InvertKeepGoldImageState();
}

class _InvertKeepGoldImageState extends State<InvertKeepGoldImage> {
  ui.FragmentProgram? _program;
  ui.Image? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShaderAndImage();
  }

  Future<void> _loadShaderAndImage() async {
    try {
      // 加载 Shader
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/invert_keep_gold.frag',
      );

      // 加载图片
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _program = program;
          _image = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load shader or image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox();
    }

    if (_program == null || _image == null) {
      // Shader 加载失败，回退到普通反色
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: Image.asset(widget.assetPath, fit: widget.fit),
      );
    }

    return CustomPaint(
      painter: _InvertKeepGoldPainter(
        program: _program!,
        image: _image!,
      ),
      size: Size(_image!.width.toDouble(), _image!.height.toDouble()),
    );
  }
}

class _InvertKeepGoldPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image image;

  _InvertKeepGoldPainter({
    required this.program,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // 设置 uniform 变量
    shader.setFloat(0, image.width.toDouble());  // uSize.x (使用图片原始尺寸)
    shader.setFloat(1, image.height.toDouble()); // uSize.y
    shader.setImageSampler(0, image); // uTexture

    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.high; // ✅ 添加高质量过滤

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _InvertKeepGoldPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
