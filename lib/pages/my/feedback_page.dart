import 'package:const_calc/dto/user.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';

import '../../services/my_service.dart';
import '../../util/http_util.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      MessageUtil.info(context, '请输入反馈内容');
      return;
    }

    final User? user = await UserService().getUserInfo();
    await HttpUtil.request<void>(
      () => MyService.addFeedback(
        info: text,
        email: user?.email ?? '',
        title: '个人中心',
      ),
      // ignore: use_build_context_synchronously
      context,
      () => mounted,
    );

    if(!mounted) return;
    MessageUtil.info(context, '反馈成功');

    // _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 点击空白收起键盘
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        appBar: AppBar(
          title: Text(
            '意见反馈',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
          backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0.5,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上方输入框（单行，带下边框，和图一致）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFF0F0F0),
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  cursorColor: isDark ? const Color(0xFFFFD54F) : Colors.grey,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '反馈内容',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    hintText: '请输入反馈内容',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 金色圆角大按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAB400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26), // 胶囊效果
                    ),
                  ),
                  child: const Text(
                    '提交',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
