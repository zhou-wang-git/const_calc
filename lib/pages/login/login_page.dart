import 'package:const_calc/pages/login/rest_password.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/user.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../util/http_util.dart';
import '../../widgets/auth_input_styles.dart';
import 'agreement_widget.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final String initialIdentifier;

  const LoginPage({
    super.key,
    this.initialIdentifier = '',
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _agree = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialIdentifier.trim();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _initialResetEmail() {
    final value = _usernameController.text.trim();
    final isEmail = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value);
    return isEmail ? value : '';
  }

  Future<void> _handleLogin() async {
    if (!_agree) {
      MessageUtil.info(context, '\u8bf7\u5148\u52fe\u9009\u534f\u8bae');
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      MessageUtil.info(context, '请输入 KCC ID 账号或邮箱');
      return;
    }

    if (_passwordController.text.isEmpty) {
      MessageUtil.info(context, '请输入 KCC ID 密码');
      return;
    }

    try {
      await HttpUtil.request(
        () => AuthService().login(
          _usernameController.text,
          _passwordController.text,
        ),
        context,
        () => mounted,
      );

      final User? user = await UserService().getUserInfo();
      if (user == null && mounted) {
        MessageUtil.info(
            context, '\u7528\u6237\u4fe1\u606f\u83b7\u53d6\u5931\u8d25');
        return;
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabPage()),
        (route) => false,
      );
    } catch (_) {}
  }

  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@kccdigital.com',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputTextColor = AuthInputStyles.textColor(theme);
    final linkColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          '\u767b\u5f55',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120,
                  child: Image.asset(
                    isDark
                        ? 'assets/icons/logo_dark.png'
                        : 'assets/icons/logo.png',
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  cursorColor: AuthInputStyles.cursorColor(theme),
                  style: TextStyle(
                    color: inputTextColor,
                    fontSize: 14,
                  ),
                  decoration: AuthInputStyles.decoration(
                    context,
                    hintText: '请输入 KCC ID 账号或邮箱',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  cursorColor: AuthInputStyles.cursorColor(theme),
                  style: TextStyle(
                    color: inputTextColor,
                    fontSize: 14,
                  ),
                  decoration: AuthInputStyles.decoration(
                    context,
                    hintText: '请输入 KCC ID 密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AuthInputStyles.iconColor(theme),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AgreementWidget(onChanged: (value) {
                  _agree = value;
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      '\u767b\u5f55',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestPasswordPage(
                                initialEmail: _initialResetEmail(),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          '\u5fd8\u8bb0\u5bc6\u7801\uff1f',
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
                          '还没有 KCC ID 账号？',
                          style: TextStyle(
                            fontSize: 13,
                            color: linkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _openSupportEmail,
                  child: Text(
                    'support@kccdigital.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: linkColor,
                      decoration: TextDecoration.underline,
                      decorationColor: linkColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
