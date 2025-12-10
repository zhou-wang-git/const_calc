import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../util/html_util.dart';

class NumberCardDetailPage extends StatefulWidget {
  final String? number;
  final String? fullHtmlContent;

  const NumberCardDetailPage({
    super.key,
    required this.number,
    required this.fullHtmlContent,
  });

  @override
  State<NumberCardDetailPage> createState() => _NumberCardDetailPageState();
}

class _NumberCardDetailPageState extends State<NumberCardDetailPage>
    with TickerProviderStateMixin {
  /// 数字颜色映射方法
  TextSpan _buildColoredNumberSpan(String? number) {
    final digits = number ?? '';
    final List<TextSpan> spans = [];

    for (var i = 0; i < digits.length; i++) {
      final char = digits[i];
      Color color;

      switch (char) {
        case '1':
        case '6':
          color = const Color.fromARGB(255, 180, 160, 45);
          break;
        case '2':
        case '7':
          color = const Color.fromARGB(255, 49, 180, 181);
          break;
        case '3':
        case '8':
          color = const Color.fromARGB(255, 186, 71, 66);
          break;
        case '4':
        case '9':
          color = const Color.fromARGB(255, 42, 123, 70);
          break;
        case '5':
          color = const Color.fromARGB(255, 169, 133, 45);
          break;
        default:
          color = Colors.black;
          break;
      }

      spans.add(
        TextSpan(
          text: char,
          style: TextStyle(
            color: color,
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          '性格详情页',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F3F3),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ✅ 标题 + 编号
              Align(
                alignment: Alignment.centerRight,
                child: RichText(text: _buildColoredNumberSpan(widget.number)),
              ),

              /// ✅ 分割线 + 中间文字
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背景图片（分割线）
                  Image.asset(
                    'assets/icons/img0001.png', // 请确认路径正确
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 40,
                    color: isDark ? Colors.white70 : null,
                  ),
                  Text(
                    "详解",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ✅ 整段 HTML 内容
              Html(
                data: HtmlUtil.appendHTML(widget.fullHtmlContent),
                style: {
                  "body": Style(
                    fontSize: FontSize(14),
                    color: isDark ? Colors.white70 : Colors.black87,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
