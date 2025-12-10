import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../util/html_util.dart';

class LuckMainPersonTab extends StatelessWidget {
  final String? title;       // 例如 "3"
  final String imagePath;     // 背景图片路径
  final String htmlContent;   // HTML 描述内容

  const LuckMainPersonTab({
    super.key,
    required this.title,
    this.imagePath = 'assets/icons/titilenn2.png',
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final containerBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey;

    return Column(
      children: [
        // 顶部图片 + "X号人"
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              imagePath,
              width: MediaQuery.of(context).size.width * 0.9,
              fit: BoxFit.contain,
            ),
            Positioned(
              top: -8,
              child: Text(
                title ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFFbbd08),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 内容展示容器
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          width: double.infinity,
          decoration: BoxDecoration(
            color: containerBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Html(
            data: HtmlUtil.appendHTML(htmlContent),
            style: {
              "body": Style(
                color: textColor,
                fontSize: FontSize(14),
                fontWeight: FontWeight.normal,
                textAlign: TextAlign.justify,
              ),
            },
          ),
        ),
      ],
    );
  }
}
