import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

import 'card_data.dart';
import 'number_card_detail_page.dart';

class NumberCardWidget extends StatelessWidget {
  final CardData data;
  final VoidCallback? onDetailTap;

  const NumberCardWidget({super.key, required this.data, this.onDetailTap});

  String removeHtmlTags(String html) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    var unescape = HtmlUnescape();
    // 去除HTML标签
    String text = html.replaceAll(regex, '');
    // 去除换行符和多余空白
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // 去除首尾空白
    text = text.trim();
    return unescape.convert(text);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部编号和按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.number ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => NumberCardDetailPage(
                        number: data.number ?? '',
                        fullHtmlContent: data.summary ?? '',
                      ),
                    ),
                  );
                  if (onDetailTap != null) onDetailTap!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3A3A3A) : Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  fixedSize: const Size(90, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "查看详情",
                  style: TextStyle(fontSize: 14, color: Color(0xFFFFC107)),
                ),
              ),
            ],
          ),

          // 中间标题线
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "详解",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
            ],
          ),

          const SizedBox(height: 6),

          // 说明文字
          Text(
            removeHtmlTags(data.summary ?? ''),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
