import 'package:const_calc/util/html_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AgreementPage extends StatelessWidget {
  final String title;
  final String html;

  const AgreementPage({super.key, required this.title, required this.html});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Html(data: HtmlUtil.appendHTML(html)),
      ),
    );
  }
}
