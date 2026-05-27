import 'dart:async';

import 'package:const_calc/pages/login/login_page.dart';
import 'package:flutter/material.dart';

import '../../services/register_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import '../../widgets/auth_input_styles.dart';
import '../my/become_tutor_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  int _countdown = 60;
  bool _isButtonDisabled = false;
  Timer? _timer;

  Future<void> _getCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      MessageUtil.info(context, '\u90ae\u7bb1\u4e0d\u80fd\u4e3a\u7a7a');
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.sendRegisterEmail(email: email),
      context,
      () => mounted,
    );

    if (!mounted) {
      return;
    }

    MessageUtil.info(context, '\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001');

    setState(() {
      _isButtonDisabled = true;
      _countdown = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isButtonDisabled = false;
          _countdown = 60;
        });
      }
    });
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final emailCode = _emailCodeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    if (name.isEmpty) {
      MessageUtil.info(context, '\u59d3\u540d\u4e0d\u80fd\u4e3a\u7a7a');
      return;
    }

    if (email.isEmpty) {
      MessageUtil.info(context, '\u90ae\u7bb1\u4e0d\u80fd\u4e3a\u7a7a');
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      MessageUtil.info(context,
          '\u8bf7\u8f93\u5165\u5408\u6cd5\u7684\u90ae\u7bb1\u683c\u5f0f');
      return;
    }

    if (emailCode.isEmpty) {
      MessageUtil.info(
          context, '\u90ae\u7bb1\u9a8c\u8bc1\u7801\u4e0d\u80fd\u4e3a\u7a7a');
      return;
    }

    if (password.isEmpty) {
      MessageUtil.info(context, '请输入 KCC ID 密码');
      return;
    }

    if (confirmPassword.isEmpty) {
      MessageUtil.info(context, '\u8bf7\u518d\u6b21\u8f93\u5165\u5bc6\u7801');
      return;
    }

    if (password != confirmPassword) {
      MessageUtil.info(context,
          '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4');
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.registerAccount(
        realName: name,
        psd: password,
        email: email,
        repsd: confirmPassword,
        year: '0',
        month: '0',
        day: '0',
        code: emailCode,
        sex: '0',
        birthTime: '',
      ),
      context,
      () => mounted,
    );

    if (!mounted) {
      return;
    }

    MessageUtil.info(context, '\u6ce8\u518c\u6210\u529f');
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(initialIdentifier: email),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final linkColor = isDark ? Colors.white60 : Colors.grey;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.appBarTheme.iconTheme?.color ??
                (isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '\u6ce8\u518c',
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  isDark
                      ? 'assets/icons/logo_dark.png'
                      : 'assets/icons/logo.png',
                  height: 120,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '此处注册使用邮箱作为登录标识，无需单独设置账号；密码由 KCC ID 统一身份系统管理。',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF7A5A00),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildInput(
                  '请输入真实中文姓名（便于测算）',
                  _nameController,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 16),
                _buildInputWithButton(
                  '请输入邮箱',
                  _emailController,
                  _getCode,
                ),
                const SizedBox(height: 16),
                _buildInput(
                  '请输入邮箱验证码',
                  _emailCodeController,
                  autofillHints: const [AutofillHints.oneTimeCode],
                ),
                const SizedBox(height: 16),
                _buildPasswordInput(
                  '请输入 KCC ID 密码',
                  _passwordController,
                  true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 8),
                _buildPasswordInput(
                  '请再次输入 KCC ID 密码',
                  _confirmPasswordController,
                  false,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      '\u6ce8\u518c',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BecomeTutorPage()),
                    );
                  },
                  child: Text(
                    '\u6210\u4e3a\u5bfc\u5e08',
                    style: TextStyle(
                      color: linkColor,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    '已有 KCC ID 账号',
                    style: TextStyle(
                      color: linkColor,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
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

  Widget _buildInput(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    Iterable<String>? autofillHints,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      cursorColor: AuthInputStyles.cursorColor(theme),
      style: TextStyle(
        fontSize: 14,
        color: AuthInputStyles.textColor(theme),
      ),
      decoration: AuthInputStyles.decoration(
        context,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildInputWithButton(
    String hint,
    TextEditingController controller,
    VoidCallback onPressed,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildInput(
            hint,
            controller,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 112,
          height: 48,
          child: ElevatedButton(
            onPressed: _isButtonDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              _isButtonDisabled
                  ? '$_countdown s'
                  : '\u83b7\u53d6\u9a8c\u8bc1\u7801',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput(
    String hint,
    TextEditingController controller,
    bool isFirst, {
    Iterable<String>? autofillHints,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: isFirst ? _obscure1 : _obscure2,
      autofillHints: autofillHints,
      cursorColor: AuthInputStyles.cursorColor(theme),
      style: TextStyle(
        fontSize: 14,
        color: AuthInputStyles.textColor(theme),
      ),
      decoration: AuthInputStyles.decoration(
        context,
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(
            (isFirst ? _obscure1 : _obscure2)
                ? Icons.visibility_off
                : Icons.visibility,
            color: AuthInputStyles.iconColor(theme),
          ),
          onPressed: () {
            setState(() {
              if (isFirst) {
                _obscure1 = !_obscure1;
              } else {
                _obscure2 = !_obscure2;
              }
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
