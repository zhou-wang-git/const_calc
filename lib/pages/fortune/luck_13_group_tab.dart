import 'package:flutter/material.dart';

import '../../dto/library_character.dart';
import '../../services/information_service.dart';
import '../information/number_card_detail_page.dart';

/// ✅ 单个文本项，使用相对坐标（基于背景图宽 691px，高 723px）
class LuckTextItem {
  final String number;
  final String text;
  final double topPercent; // 相对高度百分比 0~1
  final double? leftPercent; // 左偏移百分比
  final double? rightPercent; // 右偏移百分比
  final double fontSizePercent; // 字体大小相对宽度

  LuckTextItem({
    required this.number,
    required this.text,
    required this.topPercent,
    this.leftPercent,
    this.rightPercent,
    this.fontSizePercent = 0.03,
  });
}

class Luck13GroupTab extends StatelessWidget {
  final String imagePath;
  final List<LuckTextItem> items;
  final EdgeInsetsGeometry margin;

  const Luck13GroupTab({
    super.key,
    this.imagePath = 'assets/icons/13zhong-nigtht.png',
    required this.items,
    this.margin = const EdgeInsets.symmetric(vertical: 20), // 默认上下间距 20
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // 深色模式下标签框是黑色背景，文字用白色；浅色模式下用黑色
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: margin,
      child: AspectRatio(
        aspectRatio: 691 / 723, // ✅ 保持比例
        child: LayoutBuilder(
          builder: (context, constraints) {
            double w = constraints.maxWidth;
            double h = constraints.maxHeight;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
                for (var item in items)
                  Positioned(
                    top: h * item.topPercent,
                    left: item.leftPercent != null
                        ? w * item.leftPercent!
                        : null,
                    right: item.rightPercent != null
                        ? w * item.rightPercent!
                        : null,
                    child: GestureDetector(
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final LibraryCharacter? character =
                            await InformationService.getLibraryContent(
                              title: item.number,
                            );

                        if (character == null || character.title == null) return;

                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => NumberCardDetailPage(
                              number: character.title,
                              fullHtmlContent: character.content,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        item.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: w * item.fontSizePercent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
