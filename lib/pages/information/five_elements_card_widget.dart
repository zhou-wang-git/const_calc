import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

import 'card_data.dart';
import 'five_elements_card_detail_page.dart';

class FiveElementsCardWidget extends StatelessWidget {
  final CardData data;
  final VoidCallback? onDetailTap;

  static const Map<String, String> fiveElementsImgMapper = {
    '金': 'assets/icons/wuxing_jin-nigtht.png',
    '木': 'assets/icons/wuxing_mu-nigtht.png',
    '水': 'assets/icons/wuxing_shui-nigtht.png',
    '火': 'assets/icons/wuxing_huo-nigtht.png',
    '土': 'assets/icons/wuxing_tu-nigtht.png',
  };

  const FiveElementsCardWidget({
    super.key,
    required this.data,
    this.onDetailTap,
  });

  String removeHtmlTags(String html) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    var unescape = HtmlUnescape();
    return unescape.convert(html.replaceAll(regex, ''));
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
              if (data.number != null &&
                  fiveElementsImgMapper[data.number] != null)
                Image.asset(
                  '${fiveElementsImgMapper[data.number]}',
                  width: 35,
                  height: 35,
                ),
              ElevatedButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => FiveElementsCardDetailPage(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
