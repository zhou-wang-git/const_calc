import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';

import '../../services/my_service.dart';
import '../../util/http_util.dart';
import '../../util/password_validator.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  bool _obscureNewPwd = true;
  bool _obscureConfirmPwd = true;
  String _password = ''; // 用于实时密码强度显示

  @override
  void initState() {
    super.initState();
    _newPwdController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _password = _newPwdController.text;
    });
  }

  @override
  void dispose() {
    _newPwdController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      appBar: AppBar(
        title: Text(
          '修改密码',
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
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPwdField(
              label: '新密码',
              hint: '请输入新密码',
              controller: _newPwdController,
              obscureText: _obscureNewPwd,
              isDark: isDark,
              onToggle: () {
                setState(() => _obscureNewPwd = !_obscureNewPwd);
              },
            ),
            // 密码强度指示器
            PasswordStrengthIndicator(password: _password, centerRequirements: true),

            _buildPwdField(
              label: '确认密码',
              hint: '请确认新密码',
              controller: _confirmPwdController,
              obscureText: _obscureConfirmPwd,
              isDark: isDark,
              onToggle: () {
                setState(() => _obscureConfirmPwd = !_obscureConfirmPwd);
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAB400), // 金色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 输入框部件
  Widget _buildPwdField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return Container(
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
        controller: controller,
        obscureText: obscureText,
        cursorColor: isDark ? const Color(0xFFFFD54F) : Colors.grey,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: isDark ? Colors.white60 : Colors.grey,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final newPwd = _newPwdController.text.trim();
    final confirmPwd = _confirmPwdController.text.trim();

    if (newPwd.isEmpty || confirmPwd.isEmpty) {
      MessageUtil.info(context, '请输入完整信息');
      return;
    }
    // 密码强度验证
    final passwordError = PasswordValidator.validate(newPwd);
    if (passwordError != null) {
      MessageUtil.info(context, passwordError);
      return;
    }
    if (newPwd != confirmPwd) {
      MessageUtil.info(context, '两次输入的密码不一致');
      return;
    }

    await HttpUtil.request<void>(
      () => MyService.updateInfo(psd: newPwd, repsd: confirmPwd),
      context,
      () => mounted,
    );

    if (!mounted) return;
    MessageUtil.info(context, '修改成功');
  }
}
