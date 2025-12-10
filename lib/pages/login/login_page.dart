import 'package:const_calc/pages/login/rest_password.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import '../../dto/user.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../util/http_util.dart';
import '../../util/password_validator.dart';
import 'agreement_widget.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _agree = false;
  bool _obscure = true;

  void _handleLogin({bool skipPasswordCheck = false}) async {
    if (!_agree) {
      MessageUtil.info(context, '请先勾选协议');
      return;
    }

    try {
      // 先尝试登录
      await HttpUtil.request(
            () => AuthService().login(
                _usernameController.text, _passwordController.text
            ),
            context,
            () => mounted,
      );

      // 登录成功后检查密码强度（可跳过）
      if (!skipPasswordCheck) {
        final passwordError = PasswordValidator.validate(_passwordController.text);
        if (passwordError != null) {
          _showWeakPasswordDialog();
          return;
        }
      }

      final User? user = await UserService().getUserInfo();

      if (user == null && mounted) {
        MessageUtil.info(context, '用户信息有误');
        return;
      }

      if (!mounted) return; // ✅ 安全使用 context

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MainTabPage()),
      );
    } catch (e) {
      // 登录失败时不检查密码强度，已在 HttpUtil 中统一处理错误
    }
  }

  /// 弱密码提示对话框
  void _showWeakPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                '密码安全提示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '您的密码强度较弱，建议修改为更安全的密码。',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '安全密码要求：',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• 至少 8 位字符\n• 包含大写字母\n• 包含小写字母\n• 包含数字\n• 包含特殊字符',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black45,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleLogin(skipPasswordCheck: true);
              },
              child: Text(
                '稍后再说',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestPasswordPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '立即修改',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : Colors.grey;
    final linkColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // 隐藏返回按钮
        centerTitle: true,
        title: Text(
          '登录',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              SizedBox(
                height: 120,
                child: Image.asset(isDark ? 'assets/icons/logo_dark.png' : 'assets/icons/logo.png'),
              ),
              const SizedBox(height: 40),

              // 用户名/邮箱输入框
              TextField(
                controller: _usernameController,
                cursorColor: Colors.grey,
                style: TextStyle(color: inputTextColor),
                decoration: InputDecoration(
                  hintText: '请输入账号/邮箱',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
              const SizedBox(height: 16),

              // 密码输入框
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                cursorColor: Colors.grey,
                style: TextStyle(color: inputTextColor),
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white54 : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
              const SizedBox(height: 12),

              // 协议勾选
              AgreementWidget(onChanged: (value) {
                _agree = value;
              }),

              const SizedBox(height: 20),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107), // 黄色
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    '登录',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white, // 设置字体为白色
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 底部文本
              // 底部文本（无间距、水平居中）
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RestPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        '忘记密码?',
                        style: TextStyle(
                          fontSize: 13,
                          color: linkColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        '还没有帐号',
                        style: TextStyle(
                          fontSize: 13,
                          color: linkColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
