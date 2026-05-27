import 'package:const_calc/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../pages/login/login_page.dart';
import '../services/http_service.dart';

class AuthManager {
  static Future<void> logout(BuildContext context) async {
    HttpService.clearToken();
    await AuthService().logout();
    if (!context.mounted) return;

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
