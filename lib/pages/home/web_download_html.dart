// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 通过 <a download> 触发浏览器下载
void downloadInBrowser(String url, {String? filename}) {
  url = '$url&type=download';
  final anchor = html.AnchorElement(href: url);
  if (filename != null && filename.isNotEmpty) {
    anchor.download = filename; // 建议文件名，是否采纳取决于浏览器/响应头
  }
  anchor.rel = 'noopener';
  anchor.target = '_blank';
  anchor.click();
  anchor.remove();
}
