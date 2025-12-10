import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../component/safe_web_view.dart';

// 条件导入：web 用 web_download_html.dart，其它平台用 web_download_stub.dart
import 'web_download_stub.dart'
if (dart.library.html) 'web_download_html.dart';

class PdfWebViewWithShare extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;

  const PdfWebViewWithShare({
    super.key,
    required this.url,
    this.headers,
  });

  @override
  PdfWebViewWithShareState createState() => PdfWebViewWithShareState();
}

class PdfWebViewWithShareState extends State<PdfWebViewWithShare> {
  String? _lastSavedPath;

  String? _extractFileName(String? contentDisposition) {
    if (contentDisposition == null) return null;

    // filename="xx.pdf" 或 filename=xx.pdf
    final reg1 = RegExp(r'filename="?([^";]+)"?');
    final m1 = reg1.firstMatch(contentDisposition);
    if (m1 != null) return m1.group(1);

    // RFC5987：filename*=UTF-8''xx.pdf
    final reg2 = RegExp(r"filename\*=(?:UTF-8''|)([^;]+)");
    final m2 = reg2.firstMatch(contentDisposition);
    if (m2 != null) return Uri.decodeComponent(m2.group(1)!.trim());

    return null;
  }

  String _inferFileName(String url, Response? headResp) {
    final disp = headResp?.headers.value('content-disposition');
    final fname = _extractFileName(disp);
    if (fname != null && fname.isNotEmpty) return fname;

    final u = Uri.parse(url);
    if (u.pathSegments.isNotEmpty && u.pathSegments.last.isNotEmpty) {
      return u.pathSegments.last;
    }
    return 'download.pdf';
  }

  Future<String?> _downloadPDFToLocal(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dio = Dio();

      Response? headResp;
      try {
        headResp = await dio.head(url, options: Options(headers: widget.headers));
      } catch (_) {}

      final fileName = _inferFileName(url, headResp);
      final savePath = '${dir.path}/$fileName';

      await dio.download(
        url,
        savePath,
        options: Options(headers: widget.headers),
        deleteOnError: true,
      );

      _lastSavedPath = savePath;
      return savePath;
    } catch (e) {
      debugPrint('Download failed: $e');
      return null;
    }
  }

  Future<void> _shareLocalPDF() async {
    final path = await _downloadPDFToLocal(widget.url);
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载失败，请稍后重试')),
      );
      return;
    }
    try {
      final params = ShareParams(text: '分享 PDF 文件', files: [XFile(path)]);
      await SharePlus.instance.share(params);
    } catch (e) {
      debugPrint('Error sharing file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分享失败')),
      );
    }
  }

  Future<void> _onShareOrDownload() async {
    if (kIsWeb) {
      downloadInBrowser(widget.url);
    } else {
      await _shareLocalPDF();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewerUrl =
        'https://app.numforlife.com/pdfjs/web/viewer.html?file=${Uri.encodeComponent(widget.url)}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '测算详情PDF',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: kIsWeb ? '下载' : '分享',
            icon: Icon(kIsWeb ? Icons.download : Icons.ios_share),
            onPressed: _onShareOrDownload,
          ),
        ],
      ),
      body: SafeWebView(
        url: viewerUrl,
        onLoadComplete: (Uri? uri) {
          debugPrint('1111');
        },
        // headers: widget.headers,
      ),
    );
  }
}
