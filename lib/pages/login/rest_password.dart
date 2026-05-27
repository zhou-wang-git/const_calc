import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/register_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import '../../widgets/auth_input_styles.dart';

class RestPasswordPage extends StatefulWidget {
  final String initialEmail;

  const RestPasswordPage({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<RestPasswordPage> createState() => _RestPasswordPageState();
}

class _RestPasswordPageState extends State<RestPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isButtonDisabled = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail.trim();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _getCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      MessageUtil.info(context, '请输入 KCC ID 绑定邮箱');
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.sendRecoverPasswordEmail(email: email),
      context,
      () => mounted,
    );

    if (!mounted) {
      return;
    }

    MessageUtil.info(
      context,
      '\u91cd\u7f6e\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001\uff0c\u8bf7\u67e5\u6536\u90ae\u7bb1',
    );
    _startCountdown();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_isValidEmail(email)) {
      MessageUtil.info(context, '请输入 KCC ID 绑定邮箱');
      return;
    }

    if (otp.isEmpty) {
      MessageUtil.info(
          context, '\u8bf7\u8f93\u5165\u90ae\u7bb1\u9a8c\u8bc1\u7801');
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      MessageUtil.info(context, passwordError);
      return;
    }

    if (confirmPassword.isEmpty) {
      MessageUtil.info(context, '请再次输入新的 KCC ID 密码');
      return;
    }

    if (password != confirmPassword) {
      MessageUtil.info(context,
          '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4');
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.recoverPassword(
        email: email,
        code: otp,
        newPassword: password,
        confirmPassword: confirmPassword,
      ),
      context,
      () => mounted,
    );

    if (!mounted) {
      return;
    }

    MessageUtil.info(
      context,
      'KCC ID 密码已重置，请使用新密码登录',
    );
    Navigator.pop(context);
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

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _isButtonDisabled = true;
      _countdown = 60;
    });

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

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value);
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return '请输入新的 KCC ID 密码';
    }
    if (password.length < 8) {
      return '\u5bc6\u7801\u81f3\u5c11\u9700\u8981 8 \u4f4d';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return '\u5bc6\u7801\u5fc5\u987b\u5305\u542b\u5927\u5199\u5b57\u6bcd';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return '\u5bc6\u7801\u5fc5\u987b\u5305\u542b\u5c0f\u5199\u5b57\u6bcd';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return '\u5bc6\u7801\u5fc5\u987b\u5305\u542b\u6570\u5b57';
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) {
      return '\u5bc6\u7801\u5fc5\u987b\u5305\u542b\u7279\u6b8a\u5b57\u7b26';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? theme.cardTheme.color ?? const Color(0xFF1F1F1F)
        : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '重置 KCC ID 密码',
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '请使用 KCC ID 绑定邮箱完成验证，重置后即可回到数易使用新密码登录。',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\u65b0\u5bc6\u7801\u9700\u540c\u65f6\u5305\u542b 8 \u4f4d\u4ee5\u4e0a\u957f\u5ea6\uff0c\u5927\u5199\u5b57\u6bcd\uff0c\u5c0f\u5199\u5b57\u6bcd\uff0c\u6570\u5b57\u548c\u7279\u6b8a\u5b57\u7b26\u3002',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF7A5A00),
                            fontSize: 12.5,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildInput(
                  hint: '请输入 KCC ID 绑定邮箱',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        hint:
                            '\u8bf7\u8f93\u5165\u90ae\u7bb1\u9a8c\u8bc1\u7801',
                        controller: _otpController,
                        autofillHints: const [AutofillHints.oneTimeCode],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 112,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isButtonDisabled ? null : _getCode,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPasswordInput(
                  hint: '请输入新的 KCC ID 密码',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordInput(
                  hint: '请再次输入新的 KCC ID 密码',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      '\u786e\u8ba4\u91cd\u7f6e',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _openSupportEmail,
                  child: Text(
                    'support@kccdigital.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      decoration: TextDecoration.underline,
                      decorationColor: textColor,
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

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
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

  Widget _buildPasswordInput({
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    Iterable<String>? autofillHints,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: AuthInputStyles.iconColor(theme),
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
