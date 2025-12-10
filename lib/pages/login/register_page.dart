import 'dart:async';
import 'package:const_calc/pages/login/login_page.dart';
import 'package:flutter/material.dart';

import '../../services/register_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import '../../util/password_validator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  int _countdown = 60; // 验证码倒计时
  bool _isButtonDisabled = false; // 倒计时期间禁用按钮
  late Timer _timer;
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

  // 获取验证码的方法
  void _getCode() async {
    if (_emailController.text.isEmpty) {
      MessageUtil.info(context, '邮箱不能为空');
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.sendRegisterEmail(email: _emailController.text),
      context,
      () => mounted,
    );

    if (!mounted) return;
    MessageUtil.info(context, '验证码已发送');

    // 启动倒计时
    setState(() {
      _isButtonDisabled = true;
    });

    // 启动定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isButtonDisabled = false;
          _countdown = 60; // 重置倒计时
        });
      }
    });
  }

  // 注册方法
  void _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final emailCode = _emailCodeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    if (name.isEmpty) {
      MessageUtil.info(context, "姓名不能为空");
      return;
    }

    if (username.isEmpty) {
      MessageUtil.info(context, "账号不能为空");
      return;
    }

    if (email.isEmpty) {
      MessageUtil.info(context, "邮箱不能为空");
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      MessageUtil.info(context, "请输入合法的邮箱格式");
      return;
    }

    if (emailCode.isEmpty) {
      MessageUtil.info(context, "邮箱验证码不能为空");
      return;
    }

    if (password.isEmpty) {
      MessageUtil.info(context, "密码不能为空");
      return;
    }

    // 密码强度验证
    final passwordError = PasswordValidator.validate(password);
    if (passwordError != null) {
      MessageUtil.info(context, passwordError);
      return;
    }

    if (confirmPassword.isEmpty) {
      MessageUtil.info(context, "请再次输入密码");
      return;
    }

    if (password != confirmPassword) {
      MessageUtil.info(context, "两次输入的密码不一致");
      return;
    }

    await HttpUtil.request<void>(
      () => RegisterService.registerAccount(
        realName: name,
        account: username,
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

    if (!mounted) return;
    MessageUtil.info(context, '注册成功');
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
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
    final linkColor = isDark ? Colors.white60 : Colors.grey;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
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
          '注册',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(isDark ? 'assets/icons/logo_dark.png' : 'assets/icons/logo.png', height: 120),
              const SizedBox(height: 30),
              _buildInput('请输入真实的中文姓名（利于测算）', _nameController),
              const SizedBox(height: 16),
              _buildInput('请输入账号', _usernameController),
              const SizedBox(height: 16),
              _buildInputWithButton('请输入邮箱', _emailController, _getCode),
              const SizedBox(height: 16),
              _buildInput('请输入邮箱验证码', _emailCodeController),
              const SizedBox(height: 16),
              _buildPasswordInput('请输入密码', _passwordController, true),
              PasswordStrengthIndicator(password: _password, centerRequirements: true),
              const SizedBox(height: 8),
              _buildPasswordInput('请再次输入密码', _confirmPasswordController, false),
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
                    '注册',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  '已有帐号',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 13,
                    decoration: TextDecoration.underline, // 加下划线
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 输入框构建
  Widget _buildInput(String hint, TextEditingController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : const Color(0xFFB5B5B5);

    return TextField(
      controller: controller,
      cursorColor: Colors.grey,
      style: TextStyle(fontSize: 14, color: inputTextColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        filled: true,
        fillColor: inputBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }

  // 带验证码按钮的输入框
  Widget _buildInputWithButton(
    String hint,
    TextEditingController controller,
    VoidCallback onPressed,
  ) {
    return Row(
      children: [
        Expanded(child: _buildInput(hint, controller)),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isButtonDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              _isButtonDisabled ? '$_countdown 秒' : '获取验证码',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // 密码输入框构建
  Widget _buildPasswordInput(
    String hint,
    TextEditingController controller,
    bool isFirst,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : const Color(0xFFB5B5B5);

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: isFirst ? _obscure1 : _obscure2,
        cursorColor: Colors.grey,
        style: TextStyle(fontSize: 14, color: inputTextColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 14),
          filled: true,
          fillColor: inputBgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              (isFirst ? _obscure1 : _obscure2)
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: isDark ? Colors.white54 : null,
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
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
