import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../services/agreement_service.dart';
import '../../util/html_util.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPage();
}

class _AboutPage extends State<AboutPage> {
  String _html = '';

  @override
  void initState() {
    super.initState();
    // 页面加载完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findAboutHtml();
    });
  }

  Future<void> _findAboutHtml() async {
    final agreement = await HttpUtil.request(
      () => AgreementService().getAgreementInfo(type: '3'),
      context,
      () => mounted,
    );
    if (!mounted) return;
    if (agreement == null) {
      MessageUtil.info(context, "关于我们内容为空");
      return;
    }
    setState(() {
      _html = agreement.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // 将HTML中的logo.png替换为logo_dark.png（深色模式）
    String htmlContent = _html;
    if (isDark) {
      htmlContent = htmlContent.replaceAll(
        '22cc033f68289bdbe7b8fd2eedde8c48.png',
        'logo_dark.png',
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('关于我们', style: TextStyle(color: textColor)),
        backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Html(
          data: HtmlUtil.appendHTML(htmlContent),
          style: {
            'body': Style(color: textColor),
            'p': Style(color: textColor),
            'h1': Style(color: textColor),
            'h2': Style(color: textColor),
            'h3': Style(color: textColor),
          },
        ),
      ),
    );
  }
}
