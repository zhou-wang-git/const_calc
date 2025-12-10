import 'dart:async';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';

import '../../services/register_service.dart';
import '../../util/http_util.dart';
import '../../util/password_validator.dart';

class RestPasswordPage extends StatefulWidget {
  const RestPasswordPage({super.key});

  @override
  State<RestPasswordPage> createState() => _RestPasswordPage();
}

class _RestPasswordPage extends State<RestPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isButtonDisabled = false;
  int _countdown = 60; // 倒计时60秒
  late Timer _timer;

  // 隐藏/显示密码的控制变量
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _password = ''; // 用于实时密码强度显示

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _password = _passwordController.text;
    });
  }

  final emailRegExp = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  // 获取验证码
  void _getCode() async {
    String email = _emailController.text.trim();

    if (email.isEmpty || !emailRegExp.hasMatch(email)) {
      MessageUtil.info(context, '请输入有效的邮箱地址');
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.sendRecoverPasswordEmail(email: _emailController.text),
      context,
      () => mounted,
    );

    if (!mounted) return;
    MessageUtil.info(context, '验证码已发送');

    setState(() {
      _isButtonDisabled = true;
    });

    // 启动倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isButtonDisabled = false;
          _countdown = 60;
        });
      }
    });
  }

  // 提交表单
  Future<void> _submit() async {
    String email = _emailController.text.trim();
    String code = _codeController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !emailRegExp.hasMatch(email)) {
      MessageUtil.info(context, '请输入有效的邮箱地址');
      return;
    }
    if (code.isEmpty) {
      MessageUtil.info(context, '请输入验证码');
      return;
    }
    if (password.isEmpty) {
      MessageUtil.info(context, '请输入密码');
      return;
    }
    // 密码强度验证
    final passwordError = PasswordValidator.validate(password);
    if (passwordError != null) {
      MessageUtil.info(context, passwordError);
      return;
    }
    if (confirmPassword.isEmpty) {
      MessageUtil.info(context, '请输入确认密码');
      return;
    }
    if (confirmPassword != password) {
      MessageUtil.info(context, '两次输入的密码不一致');
      return;
    }

    // 调用重置密码 API
    await HttpUtil.request<void>(
      () => RegisterService.recoverPassword(
        email: email,
        code: code,
        newPassword: password,
        confirmPassword: confirmPassword,
      ),
      context,
      () => mounted,
    );

    if (!mounted) return;
    MessageUtil.info(context, '密码重置成功');

    // 返回登录页
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white24 : Colors.grey[200];

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
            color: theme.appBarTheme.iconTheme?.color ?? (isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '忘记密码',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField('邮箱', _emailController, false, true),
            Divider(color: dividerColor, height: 1, thickness: 1),

            SizedBox(height: 8),
            _buildInputField('验证码', _codeController, false, false),
            Divider(color: dividerColor, height: 1, thickness: 1),

            SizedBox(height: 8),
            _buildPasswordField('新密码', _passwordController, _obscurePassword),
            Divider(color: dividerColor, height: 1, thickness: 1),
            PasswordStrengthIndicator(
              password: _password,
              centerRequirements: true,
            ),

            _buildPasswordField(
              '确认密码',
              _confirmPasswordController,
              _obscureConfirmPassword,
            ),
            Divider(color: dividerColor, height: 1, thickness: 1),
            const Spacer(),
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
                  '提交',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    bool isPassword,
    bool isEmail,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : const Color(0xFFB5B5B5);
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;

    return Row(
      children: [
        // 标签部分：设置标签列宽度小一点
        Container(
          width: 60, // 缩小标签宽度，给输入框腾出空间
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 12), // 标签和输入框之间的间距
        // 输入框部分
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            cursorColor: Colors.grey,
            textAlign: TextAlign.left, // 文本左对齐
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              hintText: '请输入$label',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: inputBgColor,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
        // 仅在邮箱栏显示获取验证码按钮
        if (isEmail) ...[
          const SizedBox(width: 12), // 设置按钮与输入框之间的间距
          SizedBox(
            height: 48, // 和输入框一样高
            child: ElevatedButton(
              onPressed: _isButtonDisabled ? null : _getCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107), // 按钮颜色
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              child: Text(
                _isButtonDisabled ? '$_countdown 秒' : '获取验证码',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 密码输入框，带可见性切换
  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : const Color(0xFFB5B5B5);
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final iconColor = isDark ? Colors.white54 : Colors.grey;

    return Row(
      children: [
        // 标签部分
        Container(
          width: 60, // 缩小标签宽度，给输入框腾出空间
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 12), // 标签和输入框之间的间距
        // 输入框部分
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            cursorColor: Colors.grey,
            textAlign: TextAlign.left, // 文本左对齐
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              hintText: '请输入$label',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: inputBgColor,
              border: InputBorder.none,
              // 去掉输入框的边框
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: iconColor,
                ),
                onPressed: () {
                  setState(() {
                    if (label == '新密码') {
                      _obscurePassword = !_obscurePassword;
                    } else {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
