import 'package:flutter/material.dart';

import '../../services/kcc/kcc_auth_service.dart';
import '../../util/auth_manager.dart';
import '../../util/message_util.dart';
import '../../widgets/auth_input_styles.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      MessageUtil.info(context,
          '\u8bf7\u586b\u5199\u5b8c\u6574\u7684\u5bc6\u7801\u4fe1\u606f');
      return;
    }
    if (newPassword != confirmPassword) {
      MessageUtil.info(
          context, '\u4e24\u6b21\u65b0\u5bc6\u7801\u4e0d\u4e00\u81f4');
      return;
    }
    if (newPassword.length < 8) {
      MessageUtil.info(context, '\u65b0\u5bc6\u7801\u81f3\u5c11 8 \u4f4d');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await KccAuthService().changePassword(
        currentPassword: currentPassword,
        password: newPassword,
        passwordConfirmation: confirmPassword,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      MessageUtil.success(
        context,
        response.message.isNotEmpty
            ? response.message
            : '\u5bc6\u7801\u5df2\u66f4\u65b0',
      );
      await AuthManager.logout(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      MessageUtil.error(context, '修改 KCC ID 密码失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? theme.cardTheme.color ?? const Color(0xFF1F1F1F)
        : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '\u4fee\u6539\u5bc6\u7801',
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AutofillGroup(
          child: ListView(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Color(0xFFFAB400),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '密码由 KCC ID 统一管理',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '当前页面会直接调用 KCC ID 统一身份的 change-password 接口。',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\u4fee\u6539\u6210\u529f\u540e\uff0c\u540e\u7eed\u767b\u5f55\u8bf7\u4f7f\u7528\u65b0\u5bc6\u7801\u3002',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                cursorColor: AuthInputStyles.cursorColor(theme),
                style: TextStyle(color: AuthInputStyles.textColor(theme)),
                decoration: AuthInputStyles.decoration(
                  context,
                  hintText: '请输入当前 KCC ID 密码',
                  borderRadius: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                cursorColor: AuthInputStyles.cursorColor(theme),
                style: TextStyle(color: AuthInputStyles.textColor(theme)),
                decoration: AuthInputStyles.decoration(
                  context,
                  hintText: '请输入新的 KCC ID 密码',
                  borderRadius: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                cursorColor: AuthInputStyles.cursorColor(theme),
                style: TextStyle(color: AuthInputStyles.textColor(theme)),
                decoration: AuthInputStyles.decoration(
                  context,
                  hintText: '请确认新的 KCC ID 密码',
                  borderRadius: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAB400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '\u63d0\u4ea4',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
