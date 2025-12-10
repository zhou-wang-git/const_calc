import 'package:const_calc/util/html_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'five_elements_card_widget.dart';

class FiveElementsCardDetailPage extends StatefulWidget {
  final String? number;
  final String? fullHtmlContent;

  const FiveElementsCardDetailPage({
    super.key,
    required this.number,
    required this.fullHtmlContent,
  });

  @override
  State<FiveElementsCardDetailPage> createState() => _FiveElementsCardDetailPageState();
}

class _FiveElementsCardDetailPageState extends State<FiveElementsCardDetailPage>
    with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          '详情页',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
              if (widget.number != null && FiveElementsCardWidget.fiveElementsImgMapper[widget.number] != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    '${FiveElementsCardWidget.fiveElementsImgMapper[widget.number]}',
                    width: 70,
                    height: 70,
                  ),
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
